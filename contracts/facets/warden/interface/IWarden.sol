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
        uint256 price;
        uint256 leaderRewardsTax;
        uint256 referralRewardsTax;
        uint256 platformRevenueTax;
        uint256 partyMemberRewardsTax;
        address token;
        address receiver;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Party
    //////////////////////////////////////////////////////////////*/

    function purchaseRation(RationPurchase memory purchase) external payable;

    function sellRation(RationSell memory sell) external;

    function claimLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _memberHandler
    ) external returns (uint256);

    function claimLootToken(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _token,
        address _memberHandler
    ) external returns (uint256);

    function notifyReward(uint32 _tokenId, uint256 _amount) external;

    function notifyRewardToken(
        uint32 _tokenId,
        address _token,
        uint256 _amount
    ) external;

    /*//////////////////////////////////////////////////////////////
                                Read-Only
    //////////////////////////////////////////////////////////////*/

    function getMemberRations(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external view returns (uint256);

    function getTotalRations(uint32 _tokenId) external view returns (uint256);

    function getLootEligible(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external view returns (uint256);

    function getLootEligibleToken(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _token
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
