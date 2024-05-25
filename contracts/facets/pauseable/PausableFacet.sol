// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibPausable} from "./LibPausable.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {IPauseable} from "./interface/IPauseable.sol";
import {IFacet} from "../../interfaces/IFacet.sol";

contract PausableFacet is IPauseable, IFacet {
    function paused() external view returns (bool) {
        LibOwnership._isOwner();
        return LibPausable._paused();
    }

    function pause() external {
        LibOwnership._isOwner();
        LibPausable._pause();
        emit Paused(msg.sender);
    }

    function unpause() external {
        LibOwnership._isOwner();
        LibPausable._unpause();
        emit Unpaused(msg.sender);
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](3);
        s[0] = IPauseable.pause.selector;
        s[1] = IPauseable.unpause.selector;
        s[2] = IPauseable.paused.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IPauseable).interfaceId;
    }
}
