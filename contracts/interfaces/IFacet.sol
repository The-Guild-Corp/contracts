// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFacet {
        function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId);
}