// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC173} from "../../interfaces/IERC173.sol";
import {LibOwnership} from "./LibOwnership.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibOwnership._isOwner();
        LibOwnership._transferOwnership(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibOwnership._owner();
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](2);
        s[0] = IERC173.owner.selector;
        s[1] = IERC173.transferOwnership.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IERC173).interfaceId;
    }
}
