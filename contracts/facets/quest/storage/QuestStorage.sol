// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library QuestStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.quest.storage");

    struct StorageStruct {
        // state variables
        bool initialized;
        bool started;
        bool beingDisputed;
        bool finished;
        bool rewarded;
        bool released;
        uint256 MAX_EXTENSIONS;
        uint256 extendedCount;
        address escrowImplementation; // native or with token
        uint32 seekerId;
        uint32 solverId;
        address mediator;
        string infoURI;
        address token;
        uint256 paymentAmount;
        uint256 rewardTime;
        uint256 deadline;
        uint256 reviewPeriod;
        uint256 extensionPeriod;
        address tavern;
        address escrow;
        uint256 duration;
        uint256 finishedTime;
    }

    function questStorage() internal pure returns (StorageStruct storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
