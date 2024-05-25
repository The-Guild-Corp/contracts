// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library NexusStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant STORAGE_POSITION =
        keccak256("diamond.standard.nexus.storage");

    struct StorageStruct {
        // Core Contracts
        address guardian;
        address tierManager;
        address taxManager;
        address nft;
        address party;
        address rewarder;
        // Facet Implementation Addresses
        address diamondCutImplementation;
        address diamondAccountImplementation;
        address diamondOwnershipImplementation;
        // Handlers-NFT Data
        mapping(uint32 => address) NFTToHandler;
        mapping(address => uint32) HandlerToNFT;
        mapping(address => bool) handlerStorage;
        mapping(string => bool) nftMinted;
        mapping(string => uint32) uuidToNFT;
        mapping(string => uint32) uuidToReferrer;
        mapping(string => bool) handlerCreated;
        mapping(string => bool) uuidInitialized;
        mapping(string => bool) partyCreated;
        // Upgrades go below

        address diamondLoupeImplementation;
    }

    function nexusStorage() internal pure returns (StorageStruct storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
