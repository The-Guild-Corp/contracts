// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library AccountStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.standard.account.storage");

    struct StorageStruct {
        //using SafeERC20 for IERC20;

        bool initialized;
        bool canLevel;
        // Default tier is 1 instead of 0, since solidity 0 can also mean non-existent, all tiers in contract are real tiers
        uint8 tier; // 0 to 5 ( 6 in total ); 0 tier - banned
        address referredBy; // maybe changed to referredBy address
        uint256 mintTime;
        address NFT;
        uint256 NFTid;
        uint256 chainId;
        // NFT ids of those referred by this NFT and its subordinates
        mapping(uint256 => address) firstLevelRefs;
        mapping(uint256 => address) secondLevelRefs;
        mapping(uint256 => address) thirdLevelRefs;
        mapping(uint256 => address) fourthLevelRefs;
        uint256 firstLevelCount;
        uint256 secondLevelCount;
        uint256 thirdLevelCount;
        uint256 fourthLevelCount;
        uint256 _state;
        address nexus;
    }

    function accountStorage() internal pure returns (StorageStruct storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
