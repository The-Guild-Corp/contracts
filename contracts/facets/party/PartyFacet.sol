// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {INexus} from "../../interfaces/INexus.sol";
import {IWarden} from "../warden/interface/IWarden.sol";
import {PartyStorage} from "./storage/PartyStorage.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {ITaxManager} from "../../interfaces/ITaxManager.sol";
import {ITierManager} from "../../interfaces/ITierManager.sol";
import {IReferralHandler} from "../../interfaces/IReferralHandler.sol";
import {IParty} from "./interface/IParty.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";

contract PartyFacet is IParty {
    /*//////////////////////////////////////////////////////////////
                                 PARTY
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(LibOwnership._owner() == msg.sender, "Only owner");
        _;
    }

    modifier onlyNexus() {
        require(
            msg.sender == PartyStorage.partyStorage().nexus,
            "Party: Only Nexus can call this function"
        );
        _;
    }

    modifier onlyChief() {
        require(
            msg.sender ==
                IWarden(PartyStorage.partyStorage().warden).getChief(),
            "Party: Only Chief can call this function"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!LibPausable._paused(), "Contract is paused");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            only-owner
    //////////////////////////////////////////////////////////////*/

    function setWarden(address _warden) external onlyOwner {
        PartyStorage.partyStorage().warden = _warden;
    }

    function setNexus(address _nexus) external onlyOwner {
        PartyStorage.partyStorage().nexus = _nexus;
    }

    /*//////////////////////////////////////////////////////////////
                            only-chief
    //////////////////////////////////////////////////////////////*/

    function pauseAdmin() external onlyChief {
        LibPausable._pause();
    }

    function unpauseAdmin() external onlyChief {
        LibPausable._unpause();
    }

    function setIsPartiesEnabledStatus(bool _status) external onlyChief {
        PartyStorage.partyStorage().partiesEnabled = _status;
    }

    /*//////////////////////////////////////////////////////////////
                            only-nexus
    //////////////////////////////////////////////////////////////*/

    function createParty(
        uint32 _tokenId
    ) external onlyNexus returns (address, address) {
        require(
            PartyStorage.partyStorage().idToSafehold[_tokenId] == address(0),
            "Party:Party exists"
        );

        address safehold = IWarden(PartyStorage.partyStorage().warden)
            .createSafehold(_tokenId);

        PartyStorage.partyStorage().idToSafehold[_tokenId] = safehold;

        address lootDistributor = IWarden(PartyStorage.partyStorage().warden)
            .createLootDistributor(_tokenId);

        PartyStorage.partyStorage().idToLootDistributor[
            _tokenId
        ] = lootDistributor;

        return (safehold, lootDistributor);
    }

    function notifyReward(
        uint32 _tokenId,
        uint256 _amount
    ) external override onlyNexus {
        emit RewardAdded(_tokenId, _amount);
        _notifyReward(_tokenId, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function getLootEligible(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external view returns (uint256 lootEligible_) {
        require(
            PartyStorage.partyStorage().idToSafehold[_partyLeaderTokenId] !=
                address(0),
            "Party: Party does not exist for this Leader"
        );

        uint256 memberRations = PartyStorage.partyStorage().userRations[
            _partyLeaderTokenId
        ][_partyMemberTokenId];

        uint256 totalRations = PartyStorage.partyStorage().totalRations[
            _partyLeaderTokenId
        ];

        return
            lootEligible_ = IWarden(PartyStorage.partyStorage().warden)
                .getLootEligible(
                    _partyLeaderTokenId,
                    _partyMemberTokenId,
                    totalRations,
                    memberRations
                );
    }

    function getWarden() external view returns (address) {
        return PartyStorage.partyStorage().warden;
    }

    function getNexus() external view returns (address) {
        return PartyStorage.partyStorage().nexus;
    }

    function isPartiesEnabled() external view returns (bool) {
        return PartyStorage.partyStorage().partiesEnabled;
    }

    function getIdToSafehold(uint32 _tokenId) external view returns (address) {
        return PartyStorage.partyStorage().idToSafehold[_tokenId];
    }

    function getIdToLootDistributor(
        uint32 _tokenId
    ) external view returns (address) {
        return PartyStorage.partyStorage().idToLootDistributor[_tokenId];
    }

    function getRationPrice(
        uint256 _supply,
        uint256 _amount
    ) public view returns (uint256) {
        return
            IWarden(PartyStorage.partyStorage().warden).getRationPrice(
                _supply,
                _amount
            );
    }

    function getRationBuyPrice(
        uint32 _tokenId,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 supply = PartyStorage.partyStorage().totalRations[_tokenId];
        return getRationPrice(supply, _amount);
    }

    function getRationSellPrice(
        uint32 _tokenId,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 supply = PartyStorage.partyStorage().totalRations[_tokenId];
        if (supply > 0) {
            return getRationPrice(supply - _amount, _amount);
        }

        return 0;
    }

    function getRationBuyPriceAfterFee(
        uint32 _tokenId,
        uint256 _amount
    ) public view returns (uint256) {
        address taxManager = _getTaxManager();

        uint256 price = getRationBuyPrice(_tokenId, _amount);
        uint256 taxRate = ITaxManager(taxManager).getPartyTaxRate();

        uint256 taxAmount = (price * taxRate) /
            ITaxManager(taxManager).taxBaseDivisor();

        return price + taxAmount;
    }

    function getRationSellPriceAfterFee(
        uint32 _tokenId,
        uint256 _amount
    ) public view returns (uint256) {
        address taxManager = _getTaxManager();

        uint256 price = getRationSellPrice(_tokenId, _amount);
        uint256 taxRate = ITaxManager(taxManager).getPartyTaxRate();

        uint256 taxAmount = (price * taxRate) /
            ITaxManager(taxManager).taxBaseDivisor();

        return price - taxAmount;
    }

    function getMemberPartyRations(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId
    ) public view returns (uint256) {
        require(
            PartyStorage.partyStorage().idToSafehold[_leaderTokenId] !=
                address(0),
            "Party: Party does not exist for this Leader"
        );

        uint256 rations = PartyStorage.partyStorage().userRations[
            _leaderTokenId
        ][_partyMemberTokenId];

        return rations;
    }

    function getPartyTotalRations(
        uint32 _leaderTokenId
    ) public view returns (uint256) {
        require(
            PartyStorage.partyStorage().idToSafehold[_leaderTokenId] !=
                address(0),
            "Party: Party does not exist for this Leader"
        );

        uint256 totalRations = PartyStorage.partyStorage().totalRations[
            _leaderTokenId
        ];

        return totalRations;
    }

    /*//////////////////////////////////////////////////////////////
                            write-functions
    //////////////////////////////////////////////////////////////*/

    function buyRations(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) external payable whenNotPaused {
        require(
            PartyStorage.partyStorage().idToSafehold[_leaderTokenId] !=
                address(0),
            "Party: Party does not exist for this Leader"
        );

        require(
            msg.sender ==
                IReferralHandler(_getTokenHandler(_partyMemberTokenId))
                    .nftOwner(),
            "Party: Not the owner of the Party Member"
        );

        uint256 currentTotalRations = getPartyTotalRations(_leaderTokenId);

        _checkPartyMemberRationLimit(
            _leaderTokenId,
            _partyMemberTokenId,
            _amount
        );

        uint256 price = getRationBuyPrice(_leaderTokenId, _amount);

        Tax memory tax = calculateTax(price);

        uint256 taxes = tax.leaderRewardsTax +
            tax.referralRewardsTax +
            tax.platformRevenueTax +
            tax.partyMemberRewardsTax;

        uint256 taxedPrice = price + taxes;

        _updateRationBalanceAfterPurchase(
            _leaderTokenId,
            _partyMemberTokenId,
            _amount
        );

        emit PartyRationsBought(
            _leaderTokenId,
            _partyMemberTokenId,
            _amount,
            price,
            taxes
        );

        {
            require(msg.value == taxedPrice, "Party: Incorrect payment amount");

            IWarden(PartyStorage.partyStorage().warden).purchaseRation{
                value: taxedPrice
            }(
                IWarden.RationPurchase(
                    _leaderTokenId,
                    _partyMemberTokenId,
                    _amount,
                    currentTotalRations,
                    price,
                    tax.leaderRewardsTax,
                    tax.referralRewardsTax,
                    tax.platformRevenueTax,
                    tax.partyMemberRewardsTax,
                    address(0)
                )
            );
        }
    }

    function sellRations(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) external whenNotPaused {
        require(
            PartyStorage.partyStorage().idToSafehold[_leaderTokenId] !=
                address(0),
            "Party: Party does not exist for this Leader"
        );

        require(
            msg.sender ==
                IReferralHandler(_getTokenHandler(_partyMemberTokenId))
                    .nftOwner(),
            "Party: Not the owner of the Party member"
        );

        require(
            PartyStorage.partyStorage().userRations[_leaderTokenId][
                _partyMemberTokenId
            ] >= _amount,
            "Party: Not enough rations to sell"
        );

        uint256 currentTotalRations = getPartyTotalRations(_leaderTokenId);
        uint256 currentMemberRations = getMemberPartyRations(
            _leaderTokenId,
            _partyMemberTokenId
        );

        uint256 price = getRationSellPrice(_leaderTokenId, _amount);
        Tax memory tax = calculateTax(price);

        uint256 taxes = tax.leaderRewardsTax +
            tax.referralRewardsTax +
            tax.platformRevenueTax +
            tax.partyMemberRewardsTax;

        _updateRationBalanceAfterSell(
            _leaderTokenId,
            _partyMemberTokenId,
            _amount
        );

        emit PartyRationsSold(
            _leaderTokenId,
            _partyMemberTokenId,
            _amount,
            price,
            taxes
        );

        address _receiver = IReferralHandler(
            _getTokenHandler(_partyMemberTokenId)
        ).nftOwner();

        {
            IWarden(PartyStorage.partyStorage().warden).sellRation(
                IWarden.RationSell(
                    _leaderTokenId,
                    _partyMemberTokenId,
                    _amount,
                    currentTotalRations,
                    currentMemberRations,
                    price,
                    tax.leaderRewardsTax,
                    tax.referralRewardsTax,
                    tax.platformRevenueTax,
                    tax.partyMemberRewardsTax,
                    address(0),
                    _receiver
                )
            );
        }
    }

    function claimLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external whenNotPaused {
        require(
            PartyStorage.partyStorage().idToSafehold[_partyLeaderTokenId] !=
                address(0),
            "Party: Party does not exist for this Leader"
        );

        require(
            msg.sender ==
                IReferralHandler(_getTokenHandler(_partyMemberTokenId))
                    .nftOwner(),
            "Party: Not the Party Member"
        );

        uint256 memberRations = PartyStorage.partyStorage().userRations[
            _partyLeaderTokenId
        ][_partyMemberTokenId];

        uint256 totalRations = PartyStorage.partyStorage().totalRations[
            _partyLeaderTokenId
        ];

        uint256 lootClaimed = IWarden(PartyStorage.partyStorage().warden)
            .claimLoot(
                _partyLeaderTokenId,
                _partyMemberTokenId,
                INexus(PartyStorage.partyStorage().nexus).getHandler(
                    _partyMemberTokenId
                ),
                totalRations,
                memberRations
            );

        emit LootClaimed(_partyLeaderTokenId, _partyMemberTokenId, lootClaimed);
    }

    /*//////////////////////////////////////////////////////////////
                            internal-functions
    //////////////////////////////////////////////////////////////*/

    struct Tax {
        uint256 leaderRewardsTax;
        uint256 referralRewardsTax;
        uint256 platformRevenueTax;
        uint256 partyMemberRewardsTax;
    }

    function calculateTax(uint256 price) internal returns (Tax memory) {
        (
            uint256 leaderRewardsTax,
            uint256 referralRewardsTax,
            uint256 platformRevenueTax,
            uint256 partyMemberRewardsTax
        ) = IRewarder(_getRewarder()).calculateRationsTax(price);

        return
            Tax(
                leaderRewardsTax,
                referralRewardsTax,
                platformRevenueTax,
                partyMemberRewardsTax
            );
    }

    function _updateRationBalanceAfterPurchase(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) internal {
        // Gets the current balance of rations a party member has with a leader
        uint256 balance = PartyStorage.partyStorage().userRations[
            _leaderTokenId
        ][_partyMemberTokenId];

        // Updates the balance of rations a party member has with a leader
        PartyStorage.partyStorage().userRations[_leaderTokenId][
            _partyMemberTokenId
        ] = balance + _amount;

        // Gets the current total supply of rations a leader has
        uint256 supply = PartyStorage.partyStorage().totalRations[
            _leaderTokenId
        ];

        // Updates the total supply of rations a leader has
        PartyStorage.partyStorage().totalRations[_leaderTokenId] =
            supply +
            _amount;
    }

    function _updateRationBalanceAfterSell(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) internal {
        // Gets the current balance of rations a party member has with a leader
        uint256 balance = PartyStorage.partyStorage().userRations[
            _leaderTokenId
        ][_partyMemberTokenId];

        // Updates the balance of rations a party member has with a leader
        PartyStorage.partyStorage().userRations[_leaderTokenId][
            _partyMemberTokenId
        ] = balance - _amount;

        // Gets the current total supply of rations a leader has
        uint256 supply = PartyStorage.partyStorage().totalRations[
            _leaderTokenId
        ];

        // Updates the total supply of rations a leader has
        PartyStorage.partyStorage().totalRations[_leaderTokenId] =
            supply -
            _amount;
    }

    function _checkPartyMemberRationLimit(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) internal view {
        uint256 balance = PartyStorage.partyStorage().userRations[
            _leaderTokenId
        ][_partyMemberTokenId];

        address handler = _getTokenHandler(_partyMemberTokenId);
        uint8 tier = IReferralHandler(handler).getTier();

        require(
            balance + _amount <=
                ITierManager(_getTierManager()).getRationLimit(tier),
            "Party: Party member has reached their ration limit"
        );
    }

    function _getTokenHandler(
        uint32 _partyMemberTokenId
    ) internal view returns (address) {
        return
            INexus(PartyStorage.partyStorage().nexus).getHandler(
                _partyMemberTokenId
            );
    }

    function _getTaxManager() internal view returns (address) {
        return INexus(PartyStorage.partyStorage().nexus).getTaxManager();
    }

    function _getTierManager() internal view returns (address) {
        return INexus(PartyStorage.partyStorage().nexus).getTierManager();
    }

    function _getRewarder() internal view returns (address) {
        return INexus(PartyStorage.partyStorage().nexus).getRewarder();
    }

    function _notifyReward(uint32 _tokenId, uint256 _amount) internal {
        require(
            PartyStorage.partyStorage().idToSafehold[_tokenId] != address(0),
            "Party: Party does not exist for this Leader"
        );

        IWarden(PartyStorage.partyStorage().warden).notifyReward(
            _tokenId,
            _amount
        );
    }

    /*//////////////////////////////////////////////////////////////
                             IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](24);
        s[0] = IParty.setWarden.selector;
        s[1] = IParty.setNexus.selector;
        s[2] = IParty.pauseAdmin.selector;
        s[3] = IParty.unpauseAdmin.selector;
        s[4] = IParty.setIsPartiesEnabledStatus.selector;
        s[5] = IParty.createParty.selector;
        s[6] = IParty.notifyReward.selector;
        s[7] = IParty.getWarden.selector;
        s[8] = IParty.getNexus.selector;
        s[9] = IParty.isPartiesEnabled.selector;
        s[10] = IParty.getIdToSafehold.selector;
        s[11] = IParty.getIdToLootDistributor.selector;
        s[12] = IParty.getRationPrice.selector;
        s[13] = IParty.getRationBuyPrice.selector;
        s[14] = IParty.getRationSellPrice.selector;
        s[15] = IParty.getRationBuyPriceAfterFee.selector;
        s[16] = IParty.getRationSellPriceAfterFee.selector;
        s[17] = IParty.getMemberPartyRations.selector;
        s[18] = IParty.getPartyTotalRations.selector;
        s[19] = IParty.buyRations.selector;
        s[20] = IParty.sellRations.selector;
        s[21] = IParty.claimLoot.selector;
        s[22] = PartyFacet.pluginMetadata.selector;
        s[23] = IParty.getLootEligible.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(INexus).interfaceId;
    }
}
