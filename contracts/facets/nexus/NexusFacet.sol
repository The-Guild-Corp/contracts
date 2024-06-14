// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "../../interfaces/IProfileNFT.sol";
import "../../interfaces/IReferralHandler.sol";
import "../../interfaces/INexus.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {IParty} from "../party/interface/IParty.sol";
import {NexusStorage} from "./storage/NexusStorage.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {LibAccountFactory} from "../factory/LibAccountFactory.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Nexus contract
 * @notice Core contract of the Referral system
 * @dev Creates accounts, updates referral tree and gives info about TaxManager, TierManager and Rewarder
 */
contract NexusFacet is INexus, IFacet {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(LibOwnership._owner() == msg.sender, "Only owner");
        _;
    }

    modifier onlyGuardian() {
        require(
            msg.sender == NexusStorage.nexusStorage().guardian,
            "only guardian"
        );
        _;
    }

    modifier onlyRewarder() {
        require(
            msg.sender == NexusStorage.nexusStorage().rewarder,
            "only rewarder"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!LibPausable._paused(), "Contract is paused");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getGuardian() external view override returns (address) {
        return NexusStorage.nexusStorage().guardian;
    }

    function getTierManager() external view override returns (address) {
        return NexusStorage.nexusStorage().tierManager;
    }

    function getTaxManager() external view override returns (address) {
        return NexusStorage.nexusStorage().taxManager;
    }

    function getNFT() external view override returns (address) {
        return NexusStorage.nexusStorage().nft;
    }

    function getParty() external view override returns (address) {
        return NexusStorage.nexusStorage().party;
    }

    function getRewarder() external view override returns (address) {
        return NexusStorage.nexusStorage().rewarder;
    }

    function getDiamondCutImplementation()
        external
        view
        override
        returns (address)
    {
        return NexusStorage.nexusStorage().diamondCutImplementation;
    }

    function getDiamondAccountImplementation()
        external
        view
        override
        returns (address)
    {
        return NexusStorage.nexusStorage().diamondAccountImplementation;
    }

    function getDiamondOwnershipImplementation()
        external
        view
        override
        returns (address)
    {
        return NexusStorage.nexusStorage().diamondOwnershipImplementation;
    }

    function getDiamondLoupeImplementation()
        external
        view
        override
        returns (address)
    {
        return NexusStorage.nexusStorage().diamondLoupeImplementation;
    }

    function getHandler(uint32 tokenID) external view returns (address) {
        return NexusStorage.nexusStorage().NFTToHandler[tokenID];
    }

    function isHandler(address _handler) external view returns (bool) {
        return NexusStorage.nexusStorage().handlerStorage[_handler];
    }

    function getTokenIdFromUUID(
        string memory uuid
    ) external view returns (uint32) {
        return NexusStorage.nexusStorage().uuidToNFT[uuid];
    }

    function getHandlerFromUUID(
        string memory uuid
    ) external view returns (address) {
        return
            NexusStorage.nexusStorage().NFTToHandler[
                NexusStorage.nexusStorage().uuidToNFT[uuid]
            ];
    }

    /*//////////////////////////////////////////////////////////////
                          WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            only-owner
    //////////////////////////////////////////////////////////////*/

    function setGuardian(address _newGuardian) external override onlyOwner {
        address oldGuardian = NexusStorage.nexusStorage().guardian;
        NexusStorage.nexusStorage().guardian = _newGuardian;
        emit newGuardian(oldGuardian, _newGuardian);
    }

    function setTierManager(address _tierManager) external override onlyOwner {
        address oldManager = NexusStorage.nexusStorage().tierManager;
        NexusStorage.nexusStorage().tierManager = _tierManager;
        emit newTierManager(oldManager, _tierManager);
    }

    function setTaxManager(address _taxManager) external override onlyOwner {
        address oldManager = NexusStorage.nexusStorage().taxManager;
        NexusStorage.nexusStorage().taxManager = _taxManager;
        emit newTaxManager(oldManager, _taxManager);
    }

    function setNFT(address _nft) external override onlyOwner {
        address oldNFT = NexusStorage.nexusStorage().nft;
        NexusStorage.nexusStorage().nft = _nft;
        emit newNFT(oldNFT, _nft);
    }

    function setParty(address _party) external override onlyOwner {
        address oldParty = NexusStorage.nexusStorage().party;
        NexusStorage.nexusStorage().party = _party;
        emit newParty(oldParty, _party);
    }

    function setRewarder(address _rewarder) external override onlyOwner {
        address oldRewarder = NexusStorage.nexusStorage().rewarder;
        NexusStorage.nexusStorage().rewarder = _rewarder;
        emit newRewarder(oldRewarder, _rewarder);
    }

    function setDiamondCutImplementation(
        address _addr
    ) external override onlyOwner {
        address oldCutFacet = NexusStorage
            .nexusStorage()
            .diamondCutImplementation;
        NexusStorage.nexusStorage().diamondCutImplementation = _addr;
        emit newDiamondCutImplementation(oldCutFacet, _addr);
    }

    function setDiamondOwnershipImplementation(
        address _addr
    ) external override onlyOwner {
        address oldOwnership = NexusStorage
            .nexusStorage()
            .diamondOwnershipImplementation;
        NexusStorage.nexusStorage().diamondOwnershipImplementation = _addr;
        emit newDiamondOwnershipImplementation(oldOwnership, _addr);
    }

    function setDiamondAccountImplementation(
        address _addr
    ) external override onlyOwner {
        address oldAccount = NexusStorage
            .nexusStorage()
            .diamondAccountImplementation;
        NexusStorage.nexusStorage().diamondAccountImplementation = _addr;
        emit newDiamondAccountImplementation(oldAccount, _addr);
    }

    function setDiamondLoupeImplementation(
        address _addr
    ) external override onlyOwner {
        address oldLoupe = NexusStorage
            .nexusStorage()
            .diamondLoupeImplementation;
        NexusStorage.nexusStorage().diamondLoupeImplementation = _addr;
        emit newDiamondLoupeImplementation(oldLoupe, _addr);
    }

    function addHandler(address _handler) external onlyOwner {
        NexusStorage.nexusStorage().handlerStorage[_handler] = true;
    }

    function owner_addToReferrersAbove(address _handler) external onlyOwner {
        addToReferrersAbove(_handler);
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) external onlyOwner {
        if (_token == address(0)) {
            (bool sent, ) = payable(benefactor).call{
                value: address(this).balance
            }("");
            require(sent, "Send error");
            return;
        }
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(benefactor, tokenBalance);
        return;
    }

    /*//////////////////////////////////////////////////////////////
                        only-guardian
    //////////////////////////////////////////////////////////////*/

    function mintNFT(
        uint32 referrerId,
        address recipient,
        string memory profileLink,
        string memory uuid
    ) external onlyGuardian whenNotPaused returns (uint32) {
        require(
            NexusStorage.nexusStorage().diamondCutImplementation !=
                address(0) &&
                NexusStorage.nexusStorage().diamondOwnershipImplementation !=
                address(0) &&
                NexusStorage.nexusStorage().diamondAccountImplementation !=
                address(0) &&
                NexusStorage.nexusStorage().nft != address(0),
            "Nexus:Implementations"
        );

        NexusStorage.StorageStruct storage s = NexusStorage.nexusStorage();

        require(!s.nftMinted[uuid], "Nexus: NFT minted");

        s.nftMinted[uuid] = true;
        s.uuidToReferrer[uuid] = referrerId;

        IProfileNFT nft = IProfileNFT(s.nft);

        uint32 nftId = nft.issueProfile(recipient, profileLink);
        require(nftId != referrerId, "Cannot be its own referrer");
        require(
            referrerId < nftId, // 0 in case of no referrer
            "Referrer should have a valid profile id"
        );

        s.uuidToNFT[uuid] = nftId;

        return nftId;
    }

    function createProfile(
        string memory uuid
    ) external onlyGuardian whenNotPaused returns (address) {
        NexusStorage.StorageStruct storage s = NexusStorage.nexusStorage();

        require(s.nftMinted[uuid], "Nexus:nft");
        require(!s.handlerCreated[uuid], "Nexus:handler");

        s.handlerCreated[uuid] = true;

        // create account through the account factory now
        address handlerAd = LibAccountFactory.deployAccount(
            LibOwnership._owner(),
            s.uuidToNFT[uuid]
        );

        s.NFTToHandler[s.uuidToNFT[uuid]] = handlerAd;

        return handlerAd;
    }

    function initializeHandler(
        string memory uuid
    ) external onlyGuardian whenNotPaused {
        NexusStorage.StorageStruct storage s = NexusStorage.nexusStorage();

        require(s.nftMinted[uuid], "Nexus:not minted");
        require(s.handlerCreated[uuid], "Nexus:handler created");
        require(!s.uuidInitialized[uuid], "Nexus:initialized");

        uint32 nftId = s.uuidToNFT[uuid];
        address handlerAd = s.NFTToHandler[nftId];
        uint32 referrerId = s.uuidToReferrer[uuid];

        s.HandlerToNFT[handlerAd] = nftId;
        s.handlerStorage[handlerAd] = true;

        address referrerHandler = s.NFTToHandler[referrerId];

        s.uuidInitialized[uuid] = true;

        IReferralHandler Handler = IReferralHandler(handlerAd);
        emit NewProfileIssuance(nftId, handlerAd);

        Handler.initialize(referrerHandler);
        addToReferrersAbove(handlerAd);
    }

    function createParty(
        string memory uuid
    ) external onlyGuardian whenNotPaused {
        NexusStorage.StorageStruct storage s = NexusStorage.nexusStorage();

        require(s.nftMinted[uuid], "Nexus:minted");
        require(s.handlerCreated[uuid], "Nexus:handler");
        require(s.uuidInitialized[uuid], "Nexus:initialized");
        require(!s.partyCreated[uuid], "Nexus:created");

        if (IParty(s.party).isPartiesEnabled()) {
            uint32 nftId = s.uuidToNFT[uuid];
            s.partyCreated[uuid] = true;
            (address safehold, address lootDistributor) = IParty(s.party)
                .createParty(nftId);

            emit PartyCreated(nftId, safehold, lootDistributor);
        }
    }

    function guardianPause() external onlyGuardian {
        LibPausable._pause();
    }

    function guardianUnpause() external onlyGuardian {
        LibPausable._unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        only-rewarder
    //////////////////////////////////////////////////////////////*/

    function notifyPartyReward(
        uint32 _tokenId,
        uint256 _reward
    ) external onlyRewarder {
        NexusStorage.StorageStruct storage s = NexusStorage.nexusStorage();
        if (IParty(s.party).isPartiesEnabled()) {
            IParty(s.party).notifyReward(_tokenId, _reward);
        }
    }

    function notifyPartyRewardToken(
        uint32 _tokenId,
        address _token,
        uint256 _reward
    ) external onlyRewarder {
        NexusStorage.StorageStruct storage s = NexusStorage.nexusStorage();
        if (IParty(s.party).isPartiesEnabled()) {
            IParty(s.party).notifyRewardToken(_tokenId, _token, _reward);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        internal-function
    //////////////////////////////////////////////////////////////*/

    /**
     *
     * @param _handler Address of the handler for the newly created profile
     */
    function addToReferrersAbove(address _handler) internal {
        // handler of the newly created profile
        address firstRef = IReferralHandler(_handler).referredBy();
        if (firstRef != address(0)) {
            IReferralHandler(firstRef).addToReferralTree(1, _handler);
            address secondRef = IReferralHandler(firstRef).referredBy();
            if (secondRef != address(0)) {
                IReferralHandler(secondRef).addToReferralTree(2, _handler);
                address thirdRef = IReferralHandler(secondRef).referredBy();
                if (thirdRef != address(0)) {
                    IReferralHandler(thirdRef).addToReferralTree(3, _handler);
                    address fourthRef = IReferralHandler(thirdRef).referredBy();
                    if (fourthRef != address(0)) {
                        IReferralHandler(fourthRef).addToReferralTree(
                            4,
                            _handler
                        );
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](36);
        s[0] = NexusFacet.getGuardian.selector;
        s[1] = NexusFacet.getTierManager.selector;
        s[2] = NexusFacet.getTaxManager.selector;
        s[3] = NexusFacet.getNFT.selector;
        s[4] = NexusFacet.getParty.selector;
        s[5] = NexusFacet.getRewarder.selector;
        s[6] = NexusFacet.getDiamondCutImplementation.selector;
        s[7] = NexusFacet.getDiamondAccountImplementation.selector;
        s[8] = NexusFacet.getDiamondOwnershipImplementation.selector;
        s[9] = NexusFacet.isHandler.selector;
        s[10] = NexusFacet.getHandler.selector;
        s[11] = NexusFacet.setGuardian.selector;
        s[12] = NexusFacet.setTierManager.selector;
        s[13] = NexusFacet.setTaxManager.selector;
        s[14] = NexusFacet.setNFT.selector;
        s[15] = NexusFacet.setParty.selector;
        s[16] = NexusFacet.setRewarder.selector;
        s[17] = NexusFacet.setDiamondCutImplementation.selector;
        s[18] = NexusFacet.setDiamondAccountImplementation.selector;
        s[19] = NexusFacet.setDiamondOwnershipImplementation.selector;
        s[20] = NexusFacet.addHandler.selector;
        s[21] = NexusFacet.recoverTokens.selector;
        s[22] = NexusFacet.createProfile.selector;
        s[23] = NexusFacet.createParty.selector;
        s[24] = NexusFacet.guardianPause.selector;
        s[25] = NexusFacet.guardianUnpause.selector;
        s[26] = NexusFacet.notifyPartyReward.selector;
        s[27] = NexusFacet.mintNFT.selector;
        s[28] = NexusFacet.initializeHandler.selector;
        s[29] = NexusFacet.pluginMetadata.selector;
        s[30] = NexusFacet.setDiamondLoupeImplementation.selector;
        s[31] = NexusFacet.getDiamondLoupeImplementation.selector;
        s[32] = NexusFacet.getTokenIdFromUUID.selector;
        s[33] = NexusFacet.getHandlerFromUUID.selector;
        s[34] = NexusFacet.owner_addToReferrersAbove.selector;
        s[35] = NexusFacet.notifyPartyRewardToken.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(INexus).interfaceId;
    }
}
