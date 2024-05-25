// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;
import "./ITierManager.sol";
import "./ITaxManager.sol";

interface IReferralHandler {
    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event LevelChanged(uint8 oldTier, uint8 newTier);

    /*//////////////////////////////////////////////////////////////
                            Functions
    //////////////////////////////////////////////////////////////*/

    function initialize(address _referredBy) external;

    function tierUp() external returns (bool _status);

    function setNexus(address _nexus) external;

    function owner_setReferredBy(address _referredBy) external;

    function setTier(uint8 _tier) external;

    function changeEligibility(bool _status) external;

    function addToReferralTree(
        uint8 refDepth,
        address referralHandler
    ) external;

    function getNft() external view returns (address nftContract);

    function getNftId() external view returns (uint32 nftId);

    function getTier() external view returns (uint8 _tier);

    function getTierManager() external view returns (ITierManager _tierManager);

    function getTaxManager() external view returns (ITaxManager _taxManager);

    function checkReferralExistence(
        uint8 refDepth,
        address referralHandler
    ) external view returns (uint8 _tier);

    function getTierCounts() external view returns (uint32[5] memory);

    function referredBy() external view returns (address referrerHandler);

    function nftOwner() external view returns (address owner);
}
