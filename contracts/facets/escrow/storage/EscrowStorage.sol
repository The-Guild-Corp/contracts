// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library EscrowStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant STORAGE_POSITION =
        keccak256("diamond.standard.escrow.storage");

    struct StorageStruct {
        bool initialized;
        address quest;
        uint32 seekerId;
        uint32 solverId;
        uint256 paymentAmount;
        address token;
    }

    function escrowStorage() internal pure returns (StorageStruct storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
