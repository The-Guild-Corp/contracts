// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IFacet} from "./interfaces/IFacet.sol";
import {ISafehold} from "./facets/safehold/interface/ISafehold.sol";
import {SafeholdStorage} from "./facets/safehold/storage/SafeholdStorage.sol";

contract DiamondSafehold {
    constructor(
        address _warden,
        address _contractOwner,
        address _diamondCutFacet,
        address _diamondSafeholdFacet,
        address _diamondOwnershipFacet,
        address _diamondLoupeFacet
    ) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");

        // Add Safehold facet
        IDiamondCut.FacetCut[] memory cutSafehold = new IDiamondCut.FacetCut[](
            1
        );
        bytes4[] memory safeholdSelectors = new bytes4[](2);
        safeholdSelectors[0] = ISafehold.receiveFunds.selector;
        safeholdSelectors[1] = ISafehold.retrieveFunds.selector;
        cutSafehold[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondSafeholdFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: safeholdSelectors
        });
        LibDiamond.diamondCut(cutSafehold, address(0), "");

        // Add ownership facet
        IDiamondCut.FacetCut[] memory ownershipCut = new IDiamondCut.FacetCut[](
            1
        );
        (bytes4[] memory ownershipSelectors, ) = IFacet(_diamondOwnershipFacet)
            .pluginMetadata();
        ownershipCut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondOwnershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Add loupe facet
        IDiamondCut.FacetCut[] memory loupeCut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory loupeSelectors = new bytes4[](1);
        loupeSelectors[0] = IFacet(_diamondLoupeFacet).pluginMetadata.selector;
        loupeCut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        LibDiamond.diamondCut(ownershipCut, address(0), "");

        SafeholdStorage.SafeholdStorageStruct
            storage safeholdStorage = SafeholdStorage.safeholdStorage();
        safeholdStorage.warden = _warden;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
