//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface INexus {
    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event newGuardian(address oldGuardian, address newGuardian);
    event newTierManager(address oldTierManager, address newTierManager);
    event newTaxManager(address oldTaxManager, address newTaxManager);
    event newNFT(address oldNFT, address newNFT);
    event newParty(address oldParty, address newParty);
    event newRewarder(address oldRewarder, address newRewarder);
    event newDiamondCutImplementation(address oldFacet, address newFacet);
    event newDiamondOwnershipImplementation(address oldFacet, address newFacet);
    event newDiamondAccountImplementation(address oldFacet, address newFacet);
    event newDiamondLoupeImplementation(address oldFacet, address newFacet);

    event NewProfileIssuance(uint32 id, address account);
    event LevelChange(address handler, uint8 oldTier, uint8 newTier);
    event SelfTaxClaimed(
        address indexed handler,
        uint256 amount,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed handler,
        uint256 amount,
        uint256 timestamp
    );
    event PartyCreated(
        uint32 indexed tokenId,
        address safehold,
        address lootDistributor
    );

    /*//////////////////////////////////////////////////////////////
                          READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Var Getters

    function getGuardian() external view returns (address);

    function getTierManager() external view returns (address);

    function getTaxManager() external view returns (address);

    function getNFT() external view returns (address);

    function getParty() external view returns (address);

    function getRewarder() external view returns (address);

    function getDiamondCutImplementation() external view returns (address);

    function getDiamondAccountImplementation() external view returns (address);

    function getDiamondOwnershipImplementation()
        external
        view
        returns (address);

    function getDiamondLoupeImplementation() external view returns (address);

    // Functions

    function isHandler(address) external view returns (bool);

    function getHandler(uint32) external view returns (address);

    /*//////////////////////////////////////////////////////////////
                          WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            only-owner
    //////////////////////////////////////////////////////////////*/

    function setGuardian(address) external;

    function setTierManager(address) external;

    function setTaxManager(address) external;

    function setNFT(address) external;

    function setParty(address) external;

    function setRewarder(address) external;

    function setDiamondCutImplementation(address) external;

    function setDiamondAccountImplementation(address) external;

    function setDiamondOwnershipImplementation(address) external;

    function setDiamondLoupeImplementation(address) external;

    function addHandler(address) external;

    function recoverTokens(address, address) external;

    /*//////////////////////////////////////////////////////////////
                            only-guardian
    //////////////////////////////////////////////////////////////*/

    function mintNFT(
        uint32 _referrerId,
        address _recipient,
        string memory _profileLink,
        string memory _uuid
    ) external returns (uint32);

    function createProfile(string memory _uuid) external returns (address);

    function initializeHandler(string memory _uuid) external;

    function createParty(string memory _uuid) external;

    function guardianPause() external;

    function guardianUnpause() external;

    function notifyPartyReward(uint32 _tokenId, uint256 _amount) external;

    function notifyPartyRewardToken(
        uint32 _tokenId,
        address _token,
        uint256 _amount
    ) external;
}
