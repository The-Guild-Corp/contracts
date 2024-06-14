// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface IWardenAdmin {
    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Only-Owner
    //////////////////////////////////////////////////////////////*/

    function setParty(address _party) external;

    function setChief(address _chief) external;

    function setRewarder(address _rewarder) external;

    function setRationPriceManager(address _rationPriceManager) external;

    function setDiamondCutImplementation(
        address _diamondCutImplementation
    ) external;

    function setDiamondSafeholdFacet(address _diamondSafeholdFacet) external;

    function setDiamondLootFacet(address _diamondLootFacet) external;

    function setDiamondOwnershipFacet(address _diamondOwnershipFacet) external;

    function setDiamondPausableFacet(address _diamondPausableFacet) external;

    function setDiamondLoupeFacet(address _diamondLoupeFacet) external;

    /*//////////////////////////////////////////////////////////////
                                Only-Chief
    //////////////////////////////////////////////////////////////*/

    function pauseChief() external;

    function unpauseChief() external;
}
