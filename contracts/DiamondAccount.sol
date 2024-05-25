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
import {AccountStorage} from "./facets/account/storage/AccountStorage.sol";

contract DiamondAccount {
    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        address _accountFacet,
        address _ownershipFacet,
        address _loupeFacet,
        address _nftContract,
        uint256 _nftId
    ) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // Add ERC6551Account facet
        (bytes4[] memory accountSelectors, ) = IFacet(_accountFacet)
            .pluginMetadata();
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _accountFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: accountSelectors
        });

        // Add Ownership facet
        (bytes4[] memory ownershipSelectors, ) = IFacet(_ownershipFacet)
            .pluginMetadata();
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Add Loupe Facet
        (bytes4[] memory loupeSelectors, ) = IFacet(_loupeFacet)
            .pluginMetadata();
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: _loupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");

        AccountStorage.StorageStruct storage s = AccountStorage
            .accountStorage();

        s.NFT = _nftContract;
        s.NFTid = _nftId;
        s.chainId = block.chainid;
    }

    // Diamond Init needs to be executed, since

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
