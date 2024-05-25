// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IParty} from "../party/interface/IParty.sol";
import {IWarden} from "./interface/IWarden.sol";
import {WardenStorage} from "./storage/WardenStorage.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {RationPriceManager} from "../../RationPriceManager.sol";
import {ISafehold} from "../safehold/interface/ISafehold.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {ILoot} from "../loot/interface/ILoot.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";
import {LibLootDistributorFactory} from "../factory/LibLootDistributorFactory.sol";
import {LibSafeholdFactory} from "../factory/LibSafeholdFactory.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract WardenFacet is IWarden, IFacet {
    /*//////////////////////////////////////////////////////////////
                                 WARDEN
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyParty() {
        require(
            msg.sender == WardenStorage.wardenStorage().party,
            "Warden: Only Nexus can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == LibOwnership._owner(),
            "Warden: Only Owner can call this function"
        );
        _;
    }

    modifier onlyChief() {
        require(
            msg.sender == WardenStorage.wardenStorage().chief,
            "Warden: Only Chief can call this function"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!LibPausable._paused(), "Warden: Contract is paused");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Owner
    //////////////////////////////////////////////////////////////*/

    function setParty(address _party) external override onlyOwner {
        WardenStorage.wardenStorage().party = _party;
    }

    function setChief(address _chief) external override onlyOwner {
        WardenStorage.wardenStorage().chief = _chief;
    }

    function setRewarder(address _rewarder) external override onlyOwner {
        WardenStorage.wardenStorage().rewarder = _rewarder;
    }

    function setRationPriceManager(
        address _rationPriceManager
    ) external override onlyOwner {
        WardenStorage.wardenStorage().rationPriceManager = _rationPriceManager;
    }

    function setDiamondCutImplementation(
        address _diamondCutImplementation
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondCutImplementation = _diamondCutImplementation;
    }

    function setDiamondSafeholdFacet(
        address _diamondSafeholdFacet
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondSafeholdFacet = _diamondSafeholdFacet;
    }

    function setDiamondLootFacet(
        address _diamondLootFacet
    ) external override onlyOwner {
        WardenStorage.wardenStorage().diamondLootFacet = _diamondLootFacet;
    }

    function setDiamondOwnershipFacet(
        address _diamondOwnershipFacet
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondOwnershipFacet = _diamondOwnershipFacet;
    }

    function setDiamondPausableFacet(
        address _diamondPausableFacet
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondPausableFacet = _diamondPausableFacet;
    }

    function setDiamondLoupeFacet(
        address _diamondLoupeFacet
    ) external override onlyOwner {
        WardenStorage.wardenStorage().diamondLoupeFacet = _diamondLoupeFacet;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Chief
    //////////////////////////////////////////////////////////////*/

    function pauseChief() external onlyChief {
        LibPausable._pause();
    }

    function unpauseChief() external onlyChief {
        LibPausable._unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Party
    //////////////////////////////////////////////////////////////*/

    function createSafehold(
        uint32 _tokenId
    ) external onlyParty whenNotPaused returns (address) {
        require(
            WardenStorage.wardenStorage().diamondSafeholdFacet != address(0) &&
                WardenStorage.wardenStorage().diamondCutImplementation !=
                address(0) &&
                WardenStorage.wardenStorage().diamondOwnershipFacet !=
                address(0) &&
                WardenStorage.wardenStorage().diamondLoupeFacet != address(0),
            "Warden:Facets not set"
        );
        require(
            WardenStorage.wardenStorage().safeholds[_tokenId] == address(0),
            "Warden:Safehold exists"
        );

        address safehold = LibSafeholdFactory.deploySafehold(
            address(this),
            LibOwnership._owner()
        );

        WardenStorage.wardenStorage().safeholds[_tokenId] = safehold;

        return safehold;
    }

    function createLootDistributor(
        uint32 _tokenId
    ) external onlyParty whenNotPaused returns (address) {
        require(
            WardenStorage.wardenStorage().diamondLootFacet != address(0) &&
                WardenStorage.wardenStorage().diamondCutImplementation !=
                address(0) &&
                WardenStorage.wardenStorage().diamondOwnershipFacet !=
                address(0) &&
                WardenStorage.wardenStorage().diamondLoupeFacet != address(0),
            "Warden:Facets not set"
        );
        require(
            WardenStorage.wardenStorage().lootDistributors[_tokenId] ==
                address(0),
            "Warden:LootDistributor exists"
        );

        address lootDistributor = LibLootDistributorFactory
            .deployLootDistributor(address(this), LibOwnership._owner());

        WardenStorage.wardenStorage().lootDistributors[
            _tokenId
        ] = lootDistributor;

        return lootDistributor;
    }

    function purchaseRation(
        IWarden.RationPurchase memory purchase
    ) public payable onlyParty whenNotPaused {
        uint256 totalTax = purchase.leaderRewardsTax +
            purchase.referralRewardsTax +
            purchase.platformRevenueTax +
            purchase.partyMemberRewardsTax;

        uint256 totalPrice = purchase.price + totalTax;

        address safehold = WardenStorage.wardenStorage().safeholds[
            purchase.leaderTokenId
        ];

        address lootDistributor = WardenStorage
            .wardenStorage()
            .lootDistributors[purchase.leaderTokenId];

        WardenStorage.wardenStorage().safeholdTokenBalances[
            safehold
        ] += purchase.price;

        WardenStorage.wardenStorage().lootRewards[lootDistributor] += purchase
            .partyMemberRewardsTax;

        // Calculates the amount of rewards offset to add based on the current ratio before adding new rations
        // The ratio of rewardsOffset/increaseRation is the same as totalLoot/totalRations for the party
        // The rewardOffset will be deducted later when calculating the member's owed loot

        // Rounds up in favour of the protocols
        uint256 rewardOffsetToAdd = 0;

        if (purchase.currentTotalRations > 0) {
            rewardOffsetToAdd = Math.ceilDiv(
                WardenStorage.wardenStorage().lootRewards[lootDistributor] *
                    purchase.amount,
                purchase.currentTotalRations
            );
        } else {
            rewardOffsetToAdd = WardenStorage.wardenStorage().lootRewards[
                lootDistributor
            ];
        }

        WardenStorage.wardenStorage().lootRewardsOffset[lootDistributor][
                purchase.memberTokenId
            ] += rewardOffsetToAdd;

        WardenStorage.wardenStorage().lootRewards[
            lootDistributor
        ] += rewardOffsetToAdd;

        {
            require(msg.value == totalPrice, "Warden: Invalid payment amount");

            ISafehold(safehold).receiveFunds{value: purchase.price}(
                purchase.price
            );

            IRewarder(WardenStorage.wardenStorage().rewarder).handleRationsTax{
                value: totalTax
            }(
                purchase.leaderTokenId,
                purchase.leaderRewardsTax,
                purchase.referralRewardsTax,
                purchase.platformRevenueTax,
                purchase.partyMemberRewardsTax,
                lootDistributor
            );
        }
    }

    function sellRation(
        IWarden.RationSell memory sell
    ) external onlyParty whenNotPaused {
        uint256 totalTax = sell.leaderRewardsTax +
            sell.referralRewardsTax +
            sell.platformRevenueTax +
            sell.partyMemberRewardsTax;

        address safehold = WardenStorage.wardenStorage().safeholds[
            sell.leaderTokenId
        ];

        address lootDistributor = WardenStorage
            .wardenStorage()
            .lootDistributors[sell.leaderTokenId];

        WardenStorage.wardenStorage().safeholdTokenBalances[safehold] -= sell
            .price;

        _calculateLoot(sell);

        WardenStorage.wardenStorage().lootRewards[lootDistributor] += sell
            .partyMemberRewardsTax;

        {
            uint256 balance = address(safehold).balance;

            ISafehold(safehold).retrieveFunds(sell.price);

            uint256 balanceAfter = address(safehold).balance;

            require(
                balance - balanceAfter == sell.price,
                "Warden: Invalid transfer"
            );

            IRewarder(WardenStorage.wardenStorage().rewarder).handleRationsTax{
                value: totalTax
            }(
                sell.leaderTokenId,
                sell.leaderRewardsTax,
                sell.referralRewardsTax,
                sell.platformRevenueTax,
                sell.partyMemberRewardsTax,
                lootDistributor
            );

            (bool success, ) = payable(sell.receiver).call{
                value: sell.price - totalTax
            }("");
            require(success, "Native token transfer error");
        }
    }

    function claimLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _memberHandler,
        uint256 _totalRations,
        uint256 _partyMemberRations
    ) public onlyParty whenNotPaused returns (uint256) {
        uint256 pendingLoot = calculatePartyLoot(
            _partyLeaderTokenId,
            _partyMemberTokenId,
            _totalRations,
            _partyMemberRations
        );

        // Increase the rewardsOffset for the member, as they have claimed their loot
        WardenStorage.wardenStorage().lootRewardsOffset[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ][_partyMemberTokenId] += pendingLoot;

        if (pendingLoot > 0) {
            _lootTransfer(_partyLeaderTokenId, pendingLoot, _memberHandler);

            return pendingLoot;
        }

        return 0;
    }

    function notifyReward(
        uint32 _tokenId,
        uint256 _amount
    ) external override onlyParty {
        // Increase reward amount
        WardenStorage.wardenStorage().lootRewards[
            WardenStorage.wardenStorage().lootDistributors[_tokenId]
        ] += _amount;
    }

    /*//////////////////////////////////////////////////////////////
                                Read-Only
    //////////////////////////////////////////////////////////////*/

    function getRationPrice(
        uint256 _supply,
        uint256 _amount
    ) external view override returns (uint256) {
        return
            RationPriceManager(WardenStorage.wardenStorage().rationPriceManager)
                .calculatePrice(_supply, _amount);
    }

    function getParty() external view override returns (address) {
        return WardenStorage.wardenStorage().party;
    }

    function getChief() external view override returns (address) {
        return WardenStorage.wardenStorage().chief;
    }

    function getRewarder() external view override returns (address) {
        return WardenStorage.wardenStorage().rewarder;
    }

    function getRationPriceManager() external view override returns (address) {
        return WardenStorage.wardenStorage().rationPriceManager;
    }

    function getDiamondCutImplementation()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondCutImplementation;
    }

    function getDiamondSafeholdFacet()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondSafeholdFacet;
    }

    function getDiamondLootFacet() external view override returns (address) {
        return WardenStorage.wardenStorage().diamondLootFacet;
    }

    function getDiamondOwnershipFacet()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondOwnershipFacet;
    }

    function getDiamondPausableFacet()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondPausableFacet;
    }

    function getDiamondLoupeFacet() external view override returns (address) {
        return WardenStorage.wardenStorage().diamondLoupeFacet;
    }

    function getLootEligible(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _totalRations,
        uint256 _partyMemberRations
    ) external view override returns (uint256 pendingLoot_) {
        return
            pendingLoot_ = calculatePartyLoot(
                _partyLeaderTokenId,
                _partyMemberTokenId,
                _totalRations,
                _partyMemberRations
            );
    }

    /*//////////////////////////////////////////////////////////////
                                Internal
    //////////////////////////////////////////////////////////////*/

    function _calculateLoot(IWarden.RationSell memory sell) internal {
        uint256 pendingLoot = calculatePartyLoot(
            sell.leaderTokenId,
            sell.memberTokenId,
            sell.currentTotalRations,
            sell.currentMemberRations
        );

        // Increase the rewardsOffset for the member, as they have claimed their loot
        WardenStorage.wardenStorage().lootRewardsOffset[
            WardenStorage.wardenStorage().lootDistributors[sell.leaderTokenId]
        ][sell.memberTokenId] += pendingLoot;

        if (pendingLoot > 0) {
            _lootTransfer(sell.leaderTokenId, pendingLoot, sell.receiver);
        }
    }

    function calculatePartyLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _totalRations,
        uint256 _memberRations
    ) internal view returns (uint256) {
        if (_memberRations == 0) {
            return 0;
        }

        address lootDistributor = WardenStorage
            .wardenStorage()
            .lootDistributors[_partyLeaderTokenId];

        // Determines the share of the loot for the member based on their rations
        uint256 lootsShare = (WardenStorage.wardenStorage().lootRewards[
            lootDistributor
        ] * _memberRations) / _totalRations;

        uint256 rewardsOffset = WardenStorage.wardenStorage().lootRewardsOffset[
            lootDistributor
        ][_partyMemberTokenId];

        // Reduce by the rewardsOffset - as they were only added to keep the share / rewards ratio the same when the member added their rations

        // In the event tht rewardsOffset is higher than the actual reward, due to precision loss, just return 0
        if (rewardsOffset > lootsShare) {
            return 0;
        }

        return lootsShare - rewardsOffset;
    }

    function _lootTransfer(
        uint32 _partyLeaderTokenId,
        uint256 _amount,
        address _memberHandler
    ) internal {
        address loot = WardenStorage.wardenStorage().lootDistributors[
            _partyLeaderTokenId
        ];

        {
            uint256 balance = address(this).balance;

            ILoot(loot).lootTransfer(_amount);

            uint256 balanceAfter = address(this).balance;

            require(
                balanceAfter - balance >= _amount,
                "Warden: Invalid transfer"
            );

            (bool success, ) = payable(_memberHandler).call{value: _amount}("");
            require(success, "Native token transfer error");
        }
    }

    /*//////////////////////////////////////////////////////////////
                            IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](31);
        s[0] = IWarden.setParty.selector;
        s[1] = IWarden.setChief.selector;
        s[2] = IWarden.setRewarder.selector;
        s[3] = IWarden.setRationPriceManager.selector;
        s[4] = IWarden.setDiamondCutImplementation.selector;
        s[5] = IWarden.setDiamondSafeholdFacet.selector;
        s[6] = IWarden.setDiamondLootFacet.selector;
        s[7] = IWarden.setDiamondOwnershipFacet.selector;
        s[8] = IWarden.setDiamondPausableFacet.selector;
        s[9] = IWarden.setDiamondLoupeFacet.selector;
        s[10] = IWarden.pauseChief.selector;
        s[11] = IWarden.unpauseChief.selector;
        s[12] = IWarden.createSafehold.selector;
        s[13] = IWarden.createLootDistributor.selector;
        s[14] = IWarden.purchaseRation.selector;
        s[15] = IWarden.sellRation.selector;
        s[16] = IWarden.claimLoot.selector;
        s[17] = IWarden.notifyReward.selector;
        s[18] = IWarden.getRationPrice.selector;
        s[19] = IWarden.getParty.selector;
        s[20] = IWarden.getChief.selector;
        s[21] = IWarden.getRewarder.selector;
        s[22] = IWarden.getRationPriceManager.selector;
        s[23] = IWarden.getDiamondCutImplementation.selector;
        s[24] = IWarden.getDiamondSafeholdFacet.selector;
        s[25] = IWarden.getDiamondLootFacet.selector;
        s[26] = IWarden.getDiamondOwnershipFacet.selector;
        s[27] = IWarden.getDiamondPausableFacet.selector;
        s[28] = IWarden.getDiamondLoupeFacet.selector;
        s[29] = IFacet.pluginMetadata.selector;
        s[30] = IWarden.getLootEligible.selector;
    }

    function pluginMetadata()
        external
        pure
        override
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IWarden).interfaceId;
    }
}
