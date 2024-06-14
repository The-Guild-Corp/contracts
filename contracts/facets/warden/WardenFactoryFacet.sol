// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IParty} from "../party/interface/IParty.sol";
import {IWardenFactory} from "./interface/IWardenFactory.sol";
import {WardenStorage} from "./storage/WardenStorage.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {RationPriceManager} from "../../RationPriceManager.sol";
import {ISafehold} from "../safehold/interface/ISafehold.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {ILoot} from "../loot/interface/ILoot.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";
import {LibLootDistributorFactory} from "../factory/LibLootDistributorFactory.sol";
import {LibSafeholdFactory} from "../factory/LibSafeholdFactory.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WardenFactoryFacet is IWardenFactory, IFacet {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 WARDEN
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyParty() {
        require(
            msg.sender == WardenStorage.wardenStorage().party,
            "Warden: Only Nexus can call this function"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!LibPausable._paused(), "Warden: Contract is paused");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Party
    //////////////////////////////////////////////////////////////*/

    function createSafehold(
        uint32 _tokenId
    ) external onlyParty whenNotPaused returns (address) {
        require(
            WardenStorage.wardenStorage().diamondSafeholdFacet != address(0) &&
                WardenStorage.wardenStorage().diamondCutImplementation !=
                address(0) &&
                WardenStorage.wardenStorage().diamondOwnershipFacet !=
                address(0) &&
                WardenStorage.wardenStorage().diamondLoupeFacet != address(0),
            "Warden:Facets not set"
        );
        require(
            WardenStorage.wardenStorage().safeholds[_tokenId] == address(0),
            "Warden:Safehold exists"
        );

        address safehold = LibSafeholdFactory.deploySafehold(
            address(this),
            LibOwnership._owner()
        );

        WardenStorage.wardenStorage().safeholds[_tokenId] = safehold;

        return safehold;
    }

    function createLootDistributor(
        uint32 _tokenId
    ) external onlyParty whenNotPaused returns (address) {
        require(
            WardenStorage.wardenStorage().diamondLootFacet != address(0) &&
                WardenStorage.wardenStorage().diamondCutImplementation !=
                address(0) &&
                WardenStorage.wardenStorage().diamondOwnershipFacet !=
                address(0) &&
                WardenStorage.wardenStorage().diamondLoupeFacet != address(0),
            "Warden:Facets not set"
        );
        require(
            WardenStorage.wardenStorage().lootDistributors[_tokenId] ==
                address(0),
            "Warden:LootDistributor exists"
        );

        address lootDistributor = LibLootDistributorFactory
            .deployLootDistributor(address(this), LibOwnership._owner());

        WardenStorage.wardenStorage().lootDistributors[
            _tokenId
        ] = lootDistributor;

        return lootDistributor;
    }

    /*//////////////////////////////////////////////////////////////
                            IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](2);
        s[0] = IWardenFactory.createSafehold.selector;
        s[1] = IWardenFactory.createLootDistributor.selector;
    }

    function pluginMetadata()
        external
        pure
        override
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IWardenFactory).interfaceId;
    }
}
