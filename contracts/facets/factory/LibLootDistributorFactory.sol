// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {DiamondLootDistributors} from "../../DiamondLootDistributors.sol";
import {WardenStorage} from "../warden/storage/WardenStorage.sol";

library LibLootDistributorFactory {
    /*//////////////////////////////////////////////////////////////
                                SAFEHOLD
    //////////////////////////////////////////////////////////////*/

    function deployLootDistributor(
        address _warden,
        address _owner
    ) internal returns (address) {
        DiamondLootDistributors loot = new DiamondLootDistributors(
            _warden,
            _owner,
            WardenStorage.wardenStorage().diamondCutImplementation,
            WardenStorage.wardenStorage().diamondLootFacet,
            WardenStorage.wardenStorage().diamondOwnershipFacet,
            WardenStorage.wardenStorage().diamondLoupeFacet
        );

        return address(loot);
    }
}
