//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IEscrow} from "../../interfaces/Quests/IEscrow.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {INexus} from "../../interfaces/INexus.sol";
import {IQuest} from "../../interfaces/Quests/IQuest.sol";
import {ITavern} from "../../interfaces/Quests/ITavern.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {QuestStorage} from "./storage/QuestStorage.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {DiamondEscrow} from "../../DiamondEscrow.sol";

/**
 * @title Quest Implementation
 * @notice Controls the quest flow
 */

contract QuestFacet is IQuest, IFacet {
    using SafeERC20 for IERC20;
    modifier onlySeeker() {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(
            ITavern(s.tavern).ownerOf(s.seekerId) == msg.sender,
            "only Seeker"
        );
        _;
    }

    modifier onlySolver() {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(
            ITavern(s.tavern).ownerOf(s.solverId) == msg.sender,
            "only Solver"
        );
        _;
    }

    modifier onlyMediator() {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(msg.sender == s.mediator, "only mediator");
        _;
    }

    function initialize(
        uint32 _seekerNftId,
        uint32 _solverNftId,
        uint256 _paymentAmount,
        string memory _infoURI,
        uint256 _maxExtensions,
        address _token,
        address _escrowImpl
    ) external {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        s.tavern = msg.sender;
        require(!s.initialized, "Already Initialized");
        s.initialized = true;

        s.token = _token;

        s.seekerId = _seekerNftId;
        s.solverId = _solverNftId;

        s.paymentAmount = _paymentAmount;

        s.infoURI = _infoURI;
        s.MAX_EXTENSIONS = _maxExtensions;
        s.escrowImplementation = _escrowImpl;
    }

    /*//////////////////////////////////////////////////////////////
                            only-seeker
    //////////////////////////////////////////////////////////////*/

    function startQuest() external payable onlySeeker {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.initialized, "not initialized");
        require(!s.started, "already started");

        s.started = true;
        DiamondEscrow escrow = new DiamondEscrow(
            address(this),
            INexus(ITavern(s.tavern).nexus()).getDiamondCutImplementation(),
            s.escrowImplementation
        );
        s.escrow = address(escrow);
        emit QuestStarted(
            s.seekerId,
            s.solverId,
            s.token,
            s.paymentAmount,
            address(escrow)
        );

        if (s.token == address(0)) {
            IEscrow(address(escrow)).initialize{value: msg.value}(
                s.token,
                s.seekerId,
                s.solverId,
                s.paymentAmount
            );
        } else {
            (
                uint256 platformTax,
                uint256 referralTax,
                uint256 sharesTax
            ) = IRewarder(getRewarder()).calculateSeekerTax(s.paymentAmount);

            IERC20(s.token).transferFrom(
                msg.sender,
                address(escrow),
                s.paymentAmount + platformTax + referralTax + sharesTax
            );

            IEscrow(address(escrow)).initialize(
                s.token,
                s.seekerId,
                s.solverId,
                s.paymentAmount
            );
        }
    }

    /**
     * @dev ERC20 Tokens should be approved on rewarder
     */
    function startDispute() external payable onlySeeker {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.started, "quest not started");
        require(!s.beingDisputed, "Dispute started before");
        require(!s.rewarded, "Rewarded before");

        s.beingDisputed = true;
        s.mediator = ITavern(s.tavern).mediator();

        if (s.token == address(0)) {
            emit DisputeStarted(s.seekerId, s.solverId);
            IEscrow(s.escrow).processStartDispute{value: msg.value}();
        } else {
            require(msg.value == 0, "Native token sent");
            emit DisputeStarted(s.seekerId, s.solverId);
            IEscrow(s.escrow).processStartDispute{value: 0}();
        }
    }

    function extend() external onlySeeker {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.finished, "Quest not finished");
        require(
            s.extendedCount < s.MAX_EXTENSIONS,
            "Max extensions number reached"
        );
        require(!s.rewarded, "Was rewarded before");

        s.extendedCount++;

        emit QuestExtended(s.seekerId, s.solverId, s.extendedCount);

        s.rewardTime += ITavern(s.tavern).reviewPeriod();
    }

    /*//////////////////////////////////////////////////////////////
                            only-mediator
    //////////////////////////////////////////////////////////////*/

    function resolveDispute(uint32 solverShare) external onlyMediator {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.beingDisputed, "Dispute not started");
        require(!s.rewarded, "Rewarded before");
        require(solverShare <= 10000, "Share can't be more than 10000");

        s.rewarded = true;

        emit DisputeResolved(s.seekerId, s.solverId, solverShare);

        IEscrow(s.escrow).processResolution(solverShare);
    }

    /*//////////////////////////////////////////////////////////////
                            only-solver
    //////////////////////////////////////////////////////////////*/

    function finishQuest() external onlySolver {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.started, "quest not started");

        s.finished = true;

        emit QuestFinished(s.seekerId, s.solverId);

        s.rewardTime = block.timestamp + ITavern(s.tavern).reviewPeriod();
    }

    function receiveReward() external onlySolver {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.finished, "Quest not finished");
        require(!s.rewarded, "Rewarded before");
        require(!s.beingDisputed, "Is under dispute");
        require(s.rewardTime <= block.timestamp, "Not reward time yet");

        s.rewarded = true;

        emit RewardReceived(s.seekerId, s.solverId, s.paymentAmount);

        IEscrow(s.escrow).processPayment();
    }

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function getRewarder() public view returns (address) {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        return ITavern(s.tavern).getRewarder();
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](8);
        s[0] = QuestFacet.initialize.selector;
        s[1] = QuestFacet.startQuest.selector;
        s[2] = QuestFacet.startDispute.selector;
        s[3] = QuestFacet.resolveDispute.selector;
        s[4] = QuestFacet.finishQuest.selector;
        s[5] = QuestFacet.extend.selector;
        s[6] = QuestFacet.receiveReward.selector;
        s[7] = IQuest.getRewarder.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IQuest).interfaceId;
    }
}
