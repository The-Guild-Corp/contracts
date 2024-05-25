//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEscrow} from "../../interfaces/Quests/IEscrow.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {IQuest} from "../../interfaces/Quests/IQuest.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {EscrowStorage} from "./storage/EscrowStorage.sol";

/**
 * @title Quest Escrow for ERC20 Tokens
 * @notice Stores reward for quest
 */
contract EscrowToken is IEscrow, IFacet {
    using SafeERC20 for IERC20;

    modifier onlyQuest() {
        require(
            msg.sender == EscrowStorage.escrowStorage().quest,
            "only quest"
        );
        _;
    }

    function initialize(
        address _token,
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount
    ) external payable {
        require(
            !EscrowStorage.escrowStorage().initialized,
            "Already Initialized"
        );
        require(_token != address(0), "Invalid token address");

        EscrowStorage.escrowStorage().initialized = true;

        EscrowStorage.escrowStorage().quest = msg.sender;
        EscrowStorage.escrowStorage().token = _token;

        EscrowStorage.escrowStorage().seekerId = _seekerId;
        EscrowStorage.escrowStorage().solverId = _solverId;

        EscrowStorage.escrowStorage().paymentAmount = _paymentAmount;

        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();

        (
            uint256 platformTax,
            uint256 referralTax,
            uint256 sharesTax
        ) = IRewarder(rewarder).calculateSeekerTax(_paymentAmount);

        require(
            IERC20(_token).balanceOf(address(this)) ==
                _paymentAmount + referralTax + platformTax + sharesTax,
            "Insufficient amount sent"
        );

        IERC20(_token).approve(
            address(rewarder),
            referralTax + platformTax + sharesTax
        );

        IRewarder(rewarder).handleSeekerTaxToken(
            _seekerId,
            platformTax,
            referralTax,
            sharesTax,
            address(_token)
        );
    }

    function processPayment() external onlyQuest {
        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();
        IERC20(EscrowStorage.escrowStorage().token).approve(
            address(rewarder),
            EscrowStorage.escrowStorage().paymentAmount
        );
        IRewarder(rewarder).handleRewardToken(
            EscrowStorage.escrowStorage().token,
            EscrowStorage.escrowStorage().solverId,
            EscrowStorage.escrowStorage().paymentAmount
        );
    }

    /**
     * @notice process the dispute start
     */
    function processStartDispute() external payable onlyQuest {
        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();
        IRewarder(rewarder).handleStartDisputeToken(
            EscrowStorage.escrowStorage().paymentAmount,
            EscrowStorage.escrowStorage().token,
            EscrowStorage.escrowStorage().seekerId
        );
    }

    /**
     * @notice process the dispute resolution
     */
    function processResolution(uint32 solverShare) external onlyQuest {
        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();
        IERC20(EscrowStorage.escrowStorage().token).approve(
            rewarder,
            EscrowStorage.escrowStorage().paymentAmount
        );
        IRewarder(rewarder).processResolutionToken(
            EscrowStorage.escrowStorage().seekerId,
            EscrowStorage.escrowStorage().solverId,
            solverShare,
            EscrowStorage.escrowStorage().token,
            EscrowStorage.escrowStorage().paymentAmount
        );
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](4);
        s[0] = IEscrow.initialize.selector;
        s[1] = IEscrow.processPayment.selector;
        s[2] = IEscrow.processStartDispute.selector;
        s[3] = IEscrow.processResolution.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IEscrow).interfaceId;
    }
}
