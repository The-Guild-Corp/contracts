// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IWarden} from "../warden/interface/IWarden.sol";
import {SafeholdStorage} from "./storage/SafeholdStorage.sol";
import {ISafehold} from "./interface/ISafehold.sol";

contract SafeholdFacet is ISafehold {
    /*//////////////////////////////////////////////////////////////
                                SAFEHOLD
    //////////////////////////////////////////////////////////////*/
    modifier onlyWarden() {
        require(
            msg.sender == SafeholdStorage.safeholdStorage().warden,
            "Safehold: Only Warden can call this function"
        );
        _;
    }

    function receiveFunds(uint256 _price) external payable onlyWarden {
        require(msg.value == _price, "Safehold: Invalid value");
    }

    function retrieveFunds(uint256 _price) external onlyWarden {
        (bool success, ) = payable(msg.sender).call{value: _price}("");
        require(success, "Native token transfer error");
        return;
    }

    /*//////////////////////////////////////////////////////////////
                             IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](1);
        s[0] = ISafehold.receiveFunds.selector;
        s[1] = ISafehold.retrieveFunds.selector;
        s[2] = SafeholdFacet.pluginMetadata.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(ISafehold).interfaceId;
    }
}
