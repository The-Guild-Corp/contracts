// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {LibDiamond} from "../../libraries/LibDiamond.sol";

library LibOwnership {
    /*//////////////////////////////////////////////////////////////
                                Library
    //////////////////////////////////////////////////////////////*/

    function _transferOwnership(address _newOwner) internal {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function _isOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    function _owner() internal view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
