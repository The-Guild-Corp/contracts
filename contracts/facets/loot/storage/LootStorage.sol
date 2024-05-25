// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library LootStorage {
    /*//////////////////////////////////////////////////////////////
                                LOOT
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant LOOT_STORAGE_POSITION =
        keccak256("diamond.standard.loot.storage");

    struct LootStorageStruct {
        address warden;
    }

    function lootStorage()
        internal
        pure
        returns (LootStorageStruct storage ps)
    {
        bytes32 position = LOOT_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}
