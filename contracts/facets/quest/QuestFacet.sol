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

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                          INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(
        uint32 _seekerNftId,
        uint32 _solverNftId,
        uint256 _paymentAmount,
        string memory _infoURI,
        uint256 _maxExtensions,
        uint256 _duration,
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

        s.duration = _duration;

        s.reviewPeriod = ITavern(s.tavern).reviewPeriod();
        s.extensionPeriod = ITavern(s.tavern).extensionPeriod();

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

        uint256 durationMultiplied = s.duration *
            ITavern(s.tavern).deadlineMultiplier();

        s.deadline = block.timestamp + durationMultiplied;

        emit QuestStarted(
            s.seekerId,
            s.solverId,
            s.token,
            s.paymentAmount,
            address(escrow),
            s.deadline,
            block.timestamp
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
        require(ITavern(s.tavern).isDisputeEnabled(), "Dispute is not enabled");
        require(s.started, "quest not started");
        require(!s.beingDisputed, "Dispute started before");
        require(!s.released, "Reward already released");
        require(!s.rewarded, "Rewarded before");

        // Should not be able to start a dispute once review period is done
        if (s.finished) {
            require(s.rewardTime > block.timestamp, "Dispute: Too late");
        } else {
            require(s.deadline < block.timestamp, "Dispute: Too early");
            require(
                s.deadline +
                    s.reviewPeriod +
                    (s.extendedCount * s.extensionPeriod) >
                    block.timestamp,
                "Dispute: Too late"
            );
        }

        s.beingDisputed = true;
        s.mediator = ITavern(s.tavern).mediator();

        if (s.token == address(0)) {
            emit DisputeStarted(s.seekerId, s.solverId, block.timestamp);
            IEscrow(s.escrow).processStartDispute{value: msg.value}();
        } else {
            require(msg.value == 0, "Native token sent");
            emit DisputeStarted(s.seekerId, s.solverId, block.timestamp);
            IEscrow(s.escrow).processStartDispute{value: 0}();
        }
    }

    function extend() external onlySeeker {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();

        require(ITavern(s.tavern).isExtendEnabled(), "Extend is not enabled");

        // Should not be able to extend once review period is done
        if (s.finished) {
            require(s.rewardTime > block.timestamp, "Extend: Too late");
        } else {
            require(s.deadline < block.timestamp, "Extend: Too early");
            require(
                s.deadline +
                    s.reviewPeriod +
                    (s.extendedCount * s.extensionPeriod) >
                    block.timestamp,
                "Extend: Too late"
            );
        }

        require(
            s.extendedCount <= s.MAX_EXTENSIONS,
            "Max extensions number reached"
        );

        require(!s.rewarded, "Was rewarded before");

        s.extendedCount++;

        emit QuestExtended(
            s.seekerId,
            s.solverId,
            s.extendedCount,
            block.timestamp
        );

        s.rewardTime += s.extensionPeriod;
    }

    function releaseRewards() external onlySeeker {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(!s.beingDisputed, "Is under dispute");
        require(!s.rewarded, "Rewarded before");

        if (s.finished) {
            require(s.rewardTime > block.timestamp, "Release: Too late");
        } else {
            require(
                s.deadline + s.reviewPeriod > block.timestamp,
                "Release: Too late"
            );
        }

        emit RewardsReleased(s.seekerId, s.solverId, block.timestamp);

        s.released = true;
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

        emit DisputeResolved(
            s.seekerId,
            s.solverId,
            solverShare,
            block.timestamp
        );

        IEscrow(s.escrow).processResolution(solverShare);
    }

    /*//////////////////////////////////////////////////////////////
                            only-solver
    //////////////////////////////////////////////////////////////*/

    function finishQuest() external onlySolver {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.started, "Quest not started");
        require(!s.finished, "Finished before");
        require(block.timestamp < s.deadline, "Deadline already exceeded");

        s.finished = true;

        emit QuestFinished(s.seekerId, s.solverId, block.timestamp);

        s.finishedTime = block.timestamp;
        s.rewardTime = block.timestamp + s.reviewPeriod;
    }

    function receiveReward() external onlySolver {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        require(s.started, "Quest not started");
        require(!s.rewarded, "Rewarded before");
        require(!s.beingDisputed, "Is under dispute");

        if (s.finished) {
            if (!s.released) {
                require(s.rewardTime <= block.timestamp, "Reward: Too Early");
            }
        } else {
            if (!s.released) {
                require(
                    s.deadline + s.reviewPeriod <= block.timestamp,
                    "Reward: Too Early"
                );
            }
        }

        s.rewarded = true;

        emit RewardReceived(
            s.seekerId,
            s.solverId,
            s.paymentAmount,
            block.timestamp
        );

        IEscrow(s.escrow).processPayment();
    }

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function getRewarder() public view returns (address) {
        QuestStorage.StorageStruct storage s = QuestStorage.questStorage();
        return ITavern(s.tavern).getRewarder();
    }

    function initialized() external view returns (bool) {
        return QuestStorage.questStorage().initialized;
    }

    function started() external view returns (bool) {
        return QuestStorage.questStorage().started;
    }

    function beingDisputed() external view returns (bool) {
        return QuestStorage.questStorage().beingDisputed;
    }

    function finished() external view returns (bool) {
        return QuestStorage.questStorage().finished;
    }

    function rewarded() external view returns (bool) {
        return QuestStorage.questStorage().rewarded;
    }

    function token() external view returns (address) {
        return QuestStorage.questStorage().token;
    }

    function seekerId() external view returns (uint32) {
        return QuestStorage.questStorage().seekerId;
    }

    function solverId() external view returns (uint32) {
        return QuestStorage.questStorage().solverId;
    }

    function paymentAmount() external view returns (uint256) {
        return QuestStorage.questStorage().paymentAmount;
    }

    function infoURI() external view returns (string memory) {
        return QuestStorage.questStorage().infoURI;
    }

    function maxExtensions() external view returns (uint256) {
        return QuestStorage.questStorage().MAX_EXTENSIONS;
    }

    function extendedCount() external view returns (uint256) {
        return QuestStorage.questStorage().extendedCount;
    }

    function rewardTime() external view returns (uint256) {
        return QuestStorage.questStorage().rewardTime;
    }

    function released() external view returns (bool) {
        return QuestStorage.questStorage().released;
    }

    function deadline() external view returns (uint256) {
        return QuestStorage.questStorage().deadline;
    }

    function reviewPeriod() external view returns (uint256) {
        return QuestStorage.questStorage().reviewPeriod;
    }

    function extensionPeriod() external view returns (uint256) {
        return QuestStorage.questStorage().extensionPeriod;
    }

    function duration() external view returns (uint256) {
        return QuestStorage.questStorage().duration;
    }

    function finishedTime() external view returns (uint256) {
        return QuestStorage.questStorage().finishedTime;
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](29);
        s[0] = QuestFacet.initialize.selector;
        s[1] = QuestFacet.startQuest.selector;
        s[2] = QuestFacet.startDispute.selector;
        s[3] = QuestFacet.resolveDispute.selector;
        s[4] = QuestFacet.finishQuest.selector;
        s[5] = QuestFacet.extend.selector;
        s[6] = QuestFacet.receiveReward.selector;
        s[7] = IQuest.getRewarder.selector;
        s[8] = IQuest.initialized.selector;
        s[9] = IQuest.started.selector;
        s[10] = IQuest.beingDisputed.selector;
        s[11] = IQuest.finished.selector;
        s[12] = IQuest.rewarded.selector;
        s[13] = IQuest.token.selector;
        s[14] = IQuest.seekerId.selector;
        s[15] = IQuest.solverId.selector;
        s[16] = IQuest.paymentAmount.selector;
        s[17] = IQuest.infoURI.selector;
        s[18] = IQuest.maxExtensions.selector;
        s[19] = IQuest.extendedCount.selector;
        s[20] = IQuest.rewardTime.selector;
        s[21] = IQuest.releaseRewards.selector;
        s[22] = IQuest.released.selector;
        s[23] = IQuest.deadline.selector;
        s[24] = IQuest.reviewPeriod.selector;
        s[25] = IQuest.extensionPeriod.selector;
        s[26] = QuestFacet.pluginMetadata.selector;
        s[27] = IQuest.duration.selector;
        s[28] = IQuest.finishedTime.selector;
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
