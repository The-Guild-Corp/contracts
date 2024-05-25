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
