// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IWarden} from "../warden/interface/IWarden.sol";
import {LootStorage} from "./storage/LootStorage.sol";
import {ILoot} from "./interface/ILoot.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    function lootTransferToken(
        address _token,
        uint256 _amount
    ) external onlyWarden {
        IERC20(_token).transfer(msg.sender, _amount);
        return;
    }

    /*//////////////////////////////////////////////////////////////
                             IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](2);
        s[0] = ILoot.lootTransfer.selector;
        s[1] = ILoot.lootTransferToken.selector;
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
