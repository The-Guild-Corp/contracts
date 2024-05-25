// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library SafeholdStorage {
    /*//////////////////////////////////////////////////////////////
                                SAFEHOLD
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant SAFEHOLD_STORAGE_POSITION =
        keccak256("diamond.standard.safehold.storage");

    struct SafeholdStorageStruct {
        address warden;
    }

    function safeholdStorage()
        internal
        pure
        returns (SafeholdStorageStruct storage ps)
    {
        bytes32 position = SAFEHOLD_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}
