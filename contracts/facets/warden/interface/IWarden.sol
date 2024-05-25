// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface IWarden {
    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Struct
    //////////////////////////////////////////////////////////////*/

    struct RationPurchase {
        uint32 leaderTokenId;
        uint32 memberTokenId;
        uint256 amount;
        uint256 currentTotalRations;
        uint256 price;
        uint256 leaderRewardsTax;
        uint256 referralRewardsTax;
        uint256 platformRevenueTax;
        uint256 partyMemberRewardsTax;
        address token;
    }

    struct RationSell {
        uint32 leaderTokenId;
        uint32 memberTokenId;
        uint256 amount;
        uint256 currentTotalRations;
        uint256 currentMemberRations;
        uint256 price;
        uint256 leaderRewardsTax;
        uint256 referralRewardsTax;
        uint256 platformRevenueTax;
        uint256 partyMemberRewardsTax;
        address token;
        address receiver;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Owner
    //////////////////////////////////////////////////////////////*/

    function setParty(address _party) external;

    function setChief(address _chief) external;

    function setRewarder(address _rewarder) external;

    function setRationPriceManager(address _rationPriceManager) external;

    function setDiamondCutImplementation(
        address _diamondCutImplementation
    ) external;

    function setDiamondSafeholdFacet(address _diamondSafeholdFacet) external;

    function setDiamondLootFacet(address _diamondLootFacet) external;

    function setDiamondOwnershipFacet(address _diamondOwnershipFacet) external;

    function setDiamondPausableFacet(address _diamondPausableFacet) external;

    function setDiamondLoupeFacet(address _diamondLoupeFacet) external;

    /*//////////////////////////////////////////////////////////////
                                Only-Chief
    //////////////////////////////////////////////////////////////*/

    function pauseChief() external;

    function unpauseChief() external;

    /*//////////////////////////////////////////////////////////////
                                Only-Party
    //////////////////////////////////////////////////////////////*/

    function createSafehold(uint32 _tokenId) external returns (address);

    function createLootDistributor(uint32 _tokenId) external returns (address);

    function purchaseRation(RationPurchase memory purchase) external payable;

    function sellRation(RationSell memory sell) external;

    function claimLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _memberHandler,
        uint256 _totalRations,
        uint256 _partyMemberRations
    ) external returns (uint256);

    function notifyReward(uint32 _tokenId, uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                                Read-Only
    //////////////////////////////////////////////////////////////*/

    function getLootEligible(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _totalRations,
        uint256 _partyMemberRations
    ) external view returns (uint256);

    function getRationPrice(
        uint256 _supply,
        uint256 _amount
    ) external view returns (uint256);

    function getParty() external view returns (address);

    function getChief() external view returns (address);

    function getRewarder() external view returns (address);

    function getRationPriceManager() external view returns (address);

    function getDiamondCutImplementation() external view returns (address);

    function getDiamondSafeholdFacet() external view returns (address);

    function getDiamondLootFacet() external view returns (address);

    function getDiamondOwnershipFacet() external view returns (address);

    function getDiamondPausableFacet() external view returns (address);

    function getDiamondLoupeFacet() external view returns (address);
}
