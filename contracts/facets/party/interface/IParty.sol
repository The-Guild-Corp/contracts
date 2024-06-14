// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface IParty {
    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    event PartyRationsBought(
        uint32 leaderTokenId,
        uint32 partyMemberTokenId,
        uint256 rationsAmount,
        uint256 price,
        uint256 tax
    );

    event PartyRationsSold(
        uint32 leaderTokenId,
        uint32 partyMemberTokenId,
        uint256 rationsAmount,
        uint256 price,
        uint256 tax
    );

    event LootClaimed(
        uint32 leaderTokenId,
        uint32 partyMemberTokenId,
        uint256 lootAmount
    );

    event RewardAdded(uint32 tokenId, uint256 amount);

    event TokenRewardAdded(uint32 tokenId, address token, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            only-owner
    //////////////////////////////////////////////////////////////*/

    function setWarden(address _newOwner) external;

    function setNexus(address _newTaxManager) external;

    /*//////////////////////////////////////////////////////////////
                            only-chief
    //////////////////////////////////////////////////////////////*/

    function pauseAdmin() external;

    function unpauseAdmin() external;

    function setIsPartiesEnabledStatus(bool _status) external;

    /*//////////////////////////////////////////////////////////////
                            only-nexus
    //////////////////////////////////////////////////////////////*/

    function createParty(
        uint32 _partyLeaderTokenId
    ) external returns (address, address);

    function notifyReward(uint32 _tokenId, uint256 _amount) external;

    function notifyRewardToken(
        uint32 _tokenId,
        address _token,
        uint256 _amount
    ) external;

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function getLootEligible(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external view returns (uint256);

    function getLootEligibleToken(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _token
    ) external view returns (uint256);

    function getWarden() external view returns (address);

    function getNexus() external view returns (address);

    function isPartiesEnabled() external view returns (bool);

    function getIdToSafehold(uint32 _tokenId) external view returns (address);

    function getIdToLootDistributor(
        uint32 _tokenId
    ) external view returns (address);

    function getRationPrice(
        uint256 _supply,
        uint256 _amount
    ) external view returns (uint256);

    function getRationBuyPrice(
        uint32 _tokenId,
        uint256 _amount
    ) external returns (uint256);

    function getRationSellPrice(
        uint32 _tokenId,
        uint256 _amount
    ) external returns (uint256);

    function getRationBuyPriceAfterFee(
        uint32 _tokenId,
        uint256 _amount
    ) external returns (uint256);

    function getRationSellPriceAfterFee(
        uint32 _tokenId,
        uint256 _amount
    ) external returns (uint256);

    function getMemberPartyRations(
        uint32 _leaderTokenId,
        uint32 _memberTokenId
    ) external view returns (uint256);

    function getPartyTotalRations(
        uint32 _leaderTokenId
    ) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            write-functions
    //////////////////////////////////////////////////////////////*/

    function buyRations(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) external payable;

    function sellRations(
        uint32 _leaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _amount
    ) external;

    function claimLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external;

    function claimLootToken(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _token
    ) external;
}
