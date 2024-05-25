// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library PausableStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant PAUSABLE_STORAGE_POSITION =
        keccak256("diamond.standard.pausable.storage");

    struct PausableStorageStruct {
       bool paused;
    }

    function pausableStorage()
        internal
        pure
        returns (PausableStorageStruct storage ps)
    {
        bytes32 position = PAUSABLE_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}
