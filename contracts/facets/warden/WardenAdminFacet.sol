// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IWardenAdmin} from "./interface/IWardenAdmin.sol";
import {WardenStorage} from "./storage/WardenStorage.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";

contract WardenAdminFacet is IWardenAdmin, IFacet {
    /*//////////////////////////////////////////////////////////////
                                 WARDEN
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(
            msg.sender == LibOwnership._owner(),
            "Warden: Only Owner can call this function"
        );
        _;
    }

    modifier onlyChief() {
        require(
            msg.sender == WardenStorage.wardenStorage().chief,
            "Warden: Only Chief can call this function"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Owner
    //////////////////////////////////////////////////////////////*/

    function setParty(address _party) external override onlyOwner {
        WardenStorage.wardenStorage().party = _party;
    }

    function setChief(address _chief) external override onlyOwner {
        WardenStorage.wardenStorage().chief = _chief;
    }

    function setRewarder(address _rewarder) external override onlyOwner {
        WardenStorage.wardenStorage().rewarder = _rewarder;
    }

    function setRationPriceManager(
        address _rationPriceManager
    ) external override onlyOwner {
        WardenStorage.wardenStorage().rationPriceManager = _rationPriceManager;
    }

    function setDiamondCutImplementation(
        address _diamondCutImplementation
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondCutImplementation = _diamondCutImplementation;
    }

    function setDiamondSafeholdFacet(
        address _diamondSafeholdFacet
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondSafeholdFacet = _diamondSafeholdFacet;
    }

    function setDiamondLootFacet(
        address _diamondLootFacet
    ) external override onlyOwner {
        WardenStorage.wardenStorage().diamondLootFacet = _diamondLootFacet;
    }

    function setDiamondOwnershipFacet(
        address _diamondOwnershipFacet
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondOwnershipFacet = _diamondOwnershipFacet;
    }

    function setDiamondPausableFacet(
        address _diamondPausableFacet
    ) external override onlyOwner {
        WardenStorage
            .wardenStorage()
            .diamondPausableFacet = _diamondPausableFacet;
    }

    function setDiamondLoupeFacet(
        address _diamondLoupeFacet
    ) external override onlyOwner {
        WardenStorage.wardenStorage().diamondLoupeFacet = _diamondLoupeFacet;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Chief
    //////////////////////////////////////////////////////////////*/

    function pauseChief() external onlyChief {
        LibPausable._pause();
    }

    function unpauseChief() external onlyChief {
        LibPausable._unpause();
    }

    /*//////////////////////////////////////////////////////////////
                            IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](12);
        s[0] = IWardenAdmin.setParty.selector;
        s[1] = IWardenAdmin.setChief.selector;
        s[2] = IWardenAdmin.setRewarder.selector;
        s[3] = IWardenAdmin.setRationPriceManager.selector;
        s[4] = IWardenAdmin.setDiamondCutImplementation.selector;
        s[5] = IWardenAdmin.setDiamondSafeholdFacet.selector;
        s[6] = IWardenAdmin.setDiamondLootFacet.selector;
        s[7] = IWardenAdmin.setDiamondOwnershipFacet.selector;
        s[8] = IWardenAdmin.setDiamondPausableFacet.selector;
        s[9] = IWardenAdmin.setDiamondLoupeFacet.selector;
        s[10] = IWardenAdmin.pauseChief.selector;
        s[11] = IWardenAdmin.unpauseChief.selector;
    }

    function pluginMetadata()
        external
        pure
        override
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IWardenAdmin).interfaceId;
    }
}
