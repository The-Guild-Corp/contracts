// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library TavernStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant STORAGE_POSITION =
        keccak256("diamond.standard.tavern.storage");

    struct StorageStruct {
        address barkeeper;
        address mediator; // for disputes
        uint256 reviewPeriod;
        address nexus;
        address escrowNativeImplementation; // for native blockchain tokens
        address escrowTokenImplementation; // for ERC20 tokens
        address questImplementation;
        mapping(uint256 => bool) questExists;
        // token address => bool
        mapping(address => bool) whitelistedTokens;
        // Upgrade variables goes below here
        mapping(string => bool) questExists2;
        uint256 extensionPeriod;
        uint256 deadlineMultiplier;
        mapping(string => address) questIdToAddress;
        bool extendEnabled;
        bool disputeEnabled;
    }

    function tavernStorage() internal pure returns (StorageStruct storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
