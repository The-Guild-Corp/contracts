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

// @Note: Facets to be added to this Diamond are defined in the constructor
import {IFacet} from "./interfaces/IFacet.sol";

contract DiamondParty {
    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        address _partyFacet,
        address _ownershipFacet,
        address _pausableFacet
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

        // Add Party facet
        IDiamondCut.FacetCut[] memory cutParty = new IDiamondCut.FacetCut[](1);
        (bytes4[] memory partySelectors, ) = IFacet(_partyFacet)
            .pluginMetadata();
        cutParty[0] = IDiamondCut.FacetCut({
            facetAddress: _partyFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: partySelectors
        });
        LibDiamond.diamondCut(cutParty, address(0), "");

        // Add Ownership facet
        IDiamondCut.FacetCut[] memory cutOwnership = new IDiamondCut.FacetCut[](
            1
        );
        (bytes4[] memory ownershipSelectors, ) = IFacet(_ownershipFacet)
            .pluginMetadata();
        cutOwnership[0] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });
        LibDiamond.diamondCut(cutOwnership, address(0), "");

        // Add Pausable facet
        IDiamondCut.FacetCut[] memory cutPausable = new IDiamondCut.FacetCut[](
            1
        );
        (bytes4[] memory pausableSelectors, ) = IFacet(_pausableFacet)
            .pluginMetadata();
        cutPausable[0] = IDiamondCut.FacetCut({
            facetAddress: _pausableFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: pausableSelectors
        });
        LibDiamond.diamondCut(cutPausable, address(0), "");
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
