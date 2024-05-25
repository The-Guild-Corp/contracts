// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {DiamondAccount} from "../../DiamondAccount.sol";
import {NexusStorage} from "../nexus/storage/NexusStorage.sol";

library LibAccountFactory {
    /*//////////////////////////////////////////////////////////////
                                ACCOUNT
    //////////////////////////////////////////////////////////////*/

    function deployAccount(
        address _owner,
        uint256 _nftId
    ) internal returns (address) {
        DiamondAccount nexus = new DiamondAccount(
            _owner,
            NexusStorage.nexusStorage().diamondCutImplementation,
            NexusStorage.nexusStorage().diamondAccountImplementation,
            NexusStorage.nexusStorage().diamondOwnershipImplementation,
            NexusStorage.nexusStorage().diamondLoupeImplementation,
            NexusStorage.nexusStorage().nft,
            _nftId
        );

        return address(nexus);
    }
}
