// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {DiamondSafehold} from "../../DiamondSafehold.sol";
import {WardenStorage} from "../warden/storage/WardenStorage.sol";

library LibSafeholdFactory {
    /*//////////////////////////////////////////////////////////////
                                SAFEHOLD
    //////////////////////////////////////////////////////////////*/

    function deploySafehold(
        address _warden,
        address _owner
    ) internal returns (address) {
        DiamondSafehold safehold = new DiamondSafehold(
            _warden,
            _owner,
            WardenStorage.wardenStorage().diamondCutImplementation,
            WardenStorage.wardenStorage().diamondSafeholdFacet,
            WardenStorage.wardenStorage().diamondOwnershipFacet,
            WardenStorage.wardenStorage().diamondLoupeFacet
        );
        return address(safehold);
    }
}
