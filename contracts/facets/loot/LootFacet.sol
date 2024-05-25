// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IWarden} from "../warden/interface/IWarden.sol";
import {LootStorage} from "./storage/LootStorage.sol";
import {ILoot} from "./interface/ILoot.sol";

contract LootDistributorFacet is ILoot {
    /*//////////////////////////////////////////////////////////////
                                LOOT
    //////////////////////////////////////////////////////////////*/

    modifier onlyWarden() {
        require(
            msg.sender == LootStorage.lootStorage().warden,
            "Safehold: Only Warden can call this function"
        );
        _;
    }

    function lootTransfer(uint256 _amount) external onlyWarden {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Native token transfer error");
        return;
    }

    /*//////////////////////////////////////////////////////////////
                             IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = ILoot.lootTransfer.selector;
        s[1] = LootDistributorFacet.pluginMetadata.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(ILoot).interfaceId;
    }
}
