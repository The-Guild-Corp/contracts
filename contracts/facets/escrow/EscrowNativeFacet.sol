//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEscrow} from "../../interfaces/Quests/IEscrow.sol";
import {IQuest} from "../../interfaces/Quests/IQuest.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {EscrowStorage} from "./storage/EscrowStorage.sol";

/**
 * @title Quest Escrow for Native Tokens
 * @notice Stores reward for quest
 */
contract EscrowNative is IEscrow, IFacet {
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
        require(
            _token == address(0),
            "EscrowNative: Token address should be 0"
        );

        EscrowStorage.escrowStorage().initialized = true;
        EscrowStorage.escrowStorage().quest = msg.sender;

        EscrowStorage.escrowStorage().seekerId = _seekerId;
        EscrowStorage.escrowStorage().solverId = _solverId;

        EscrowStorage.escrowStorage().paymentAmount = _paymentAmount;

        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();

        (
            uint256 platformTax,
            uint256 referralTax,
            uint256 sharesTax
        ) = IRewarder(rewarder).calculateSeekerTax(
                EscrowStorage.escrowStorage().paymentAmount
            );

        require(
            msg.value ==
                EscrowStorage.escrowStorage().paymentAmount +
                    referralTax +
                    platformTax +
                    sharesTax,
            "Invalid amount sent"
        );

        IRewarder(rewarder).handleSeekerTaxNative{
            value: referralTax + platformTax + sharesTax
        }(_seekerId, platformTax, referralTax, sharesTax);
    }

    function processPayment() external onlyQuest {
        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();
        IRewarder(rewarder).handleRewardNative{value: address(this).balance}(
            EscrowStorage.escrowStorage().solverId,
            0
        );
    }

    /**
     * @notice process the dispute start
     */
    function processStartDispute() external payable onlyQuest {
        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();
        IRewarder(rewarder).handleStartDisputeNative{value: msg.value}(
            EscrowStorage.escrowStorage().paymentAmount
        );
    }

    /**
     * @notice process the dispute resolution
     */
    function processResolution(uint32 solverShare) external onlyQuest {
        address rewarder = IQuest(EscrowStorage.escrowStorage().quest)
            .getRewarder();
        IRewarder(rewarder).processResolutionNative{
            value: address(this).balance
        }(
            EscrowStorage.escrowStorage().seekerId,
            EscrowStorage.escrowStorage().solverId,
            solverShare
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
