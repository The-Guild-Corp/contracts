// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

library PartyStorage {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant PARTY_STORAGE_POSITION =
        keccak256("diamond.standard.party.storage");

    struct PartyStorageStruct {
        address nexus;
        address warden;
        // Party leader NFTId => total rations for party
        mapping(uint32 => uint256) totalRations;
        // Party leader NFTId => (Party member NFTId => rations balance)
        mapping(uint32 => mapping(uint32 => uint256)) userRations;
        mapping(uint32 => address) idToSafehold;
        mapping(uint32 => address) idToLootDistributor;
        mapping(address => bool) tokenApproved;
        bool partiesEnabled;
    }

    function partyStorage()
        internal
        pure
        returns (PartyStorageStruct storage ps)
    {
        bytes32 position = PARTY_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}
