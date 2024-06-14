// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library WardenStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant WARDEN_STORAGE_POSITION =
        keccak256("diamond.standard.warden.storage");

    struct WardenStorageStruct {
        address party;
        address chief;
        address rationPriceManager;
        address rewarder;
        mapping(uint32 => address) safeholds;
        mapping(uint32 => address) lootDistributors;
        mapping(address => uint256) lootRewards;
        mapping(address => mapping(uint32 => uint256)) lootRewardsOffset;
        mapping(address => uint256) safeholdTokenBalances;
        address diamondCutImplementation;
        address diamondSafeholdFacet;
        address diamondLootFacet;
        address diamondOwnershipFacet;
        address diamondPausableFacet;
        // Upgrades go below

        address diamondLoupeFacet;
        // Tracks erc20 token rewards sent to ration holders
        // Loot address => Token address => Total rewards
        mapping(address => mapping(address => uint256)) lootTokenRewards;
        // Ration holders offset for erc20 rewards
        // Loot address => Token address => Party Member ID => Token rewards offset
        mapping(address => mapping(address => mapping(uint32 => uint256))) lootTokenRewardsOffset;
        // Loot address => Token address => Party Member ID => Token rewards eligible
        mapping(address => mapping(address => mapping(uint32 => uint256))) lootMemberTokenRewards;
        // Loot address => Total rations
        mapping(address => uint256) lootTotalRations;
        // Loot address => Member id => rations owned
        mapping(address => mapping(uint32 => uint256)) memberRationsAmount;
        // Loot address => RationHolderCount
        mapping(address => uint256) lootRationHoldersCount;
        // Loot address => RationHolderCount => Holder(member token id)
        mapping(address => mapping(uint256 => uint32)) lootRationHolder;
        // Loot address => memberId => amount, loot amount eligible from taxes
        mapping(address => mapping(uint32 => uint256)) lootMemberRewards;
        // Erc20 token count
        // Token count
        uint256 lootTokenCount;
        // Token index => Token address
        mapping(uint256 => address) lootToken;
        // Token existence, Token Address => Token existence
        mapping(address => bool) tokenExistence;
    }

    function wardenStorage()
        internal
        pure
        returns (WardenStorageStruct storage ps)
    {
        bytes32 position = WARDEN_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}
