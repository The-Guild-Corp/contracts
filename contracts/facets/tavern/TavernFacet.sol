// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "../../interfaces/IProfileNFT.sol";
import "../../interfaces/INexus.sol";
import "../../interfaces/Quests/IQuest.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITavern} from "../../interfaces/Quests/ITavern.sol";
import {TavernStorage} from "./storage/TavernStorage.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {DiamondQuest} from "../../DiamondQuest.sol";

/**
 * @title Quest Factory (Tavern)
 * @notice Deploys Quest Contracts and manages them
 */

contract TavernFacet is ITavern, IFacet {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBarkeeper() {
        require(
            msg.sender == TavernStorage.tavernStorage().barkeeper,
            "Tavern: Only barkeeper"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == LibOwnership._owner(), "Tavern: Only owner");
        _;
    }

    modifier whenNotPaused() {
        require(!LibPausable._paused(), "Contract is paused");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            write-functions/only-barkeeper
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to create quests with Native token payments
     * @param _seekerId Nft id of the seeker of the quest
     * @param _solverId Nft id of the solver of the quest
     * @param _paymentAmount Amount of Native tokens to be paid
     * @param infoURI Link to the info about quest (flexible)
     */
    function createNewQuest(
        // user identifiers
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        uint256 _duration,
        string memory _questId
    ) external payable onlyBarkeeper whenNotPaused {
        require(
            !TavernStorage.tavernStorage().questExists2[_questId],
            "Quest already exists"
        );

        DiamondQuest quest = new DiamondQuest(
            LibOwnership._owner(),
            INexus(TavernStorage.tavernStorage().nexus)
                .getDiamondCutImplementation(),
            TavernStorage.tavernStorage().questImplementation
        );

        address taxManager = INexus(TavernStorage.tavernStorage().nexus)
            .getTaxManager();

        require(taxManager != address(0), "TaxManager not set");

        emit QuestCreatedNative(
            _seekerId,
            _solverId,
            address(quest),
            _maxExtensions,
            _paymentAmount
        );

        TavernStorage.tavernStorage().questExists2[_questId] = true;
        TavernStorage.tavernStorage().questIdToAddress[_questId] = address(
            quest
        );

        IQuest(address(quest)).initialize(
            _seekerId,
            _solverId,
            _paymentAmount,
            infoURI,
            _maxExtensions,
            _duration,
            address(0),
            TavernStorage.tavernStorage().escrowNativeImplementation
        );
    }

    /**
     * @notice Function to create quests with ERC20 token payments
     * @param _seekerId Nft id of the seeker of the quest
     * @param _solverId Nft id of the solver of the quest
     * @param _paymentAmount Amount of Native tokens to be paid
     * @param infoURI Link to the info a bout quest (flexible, decide with backend)
     * @param _token Address of the payment token
     */
    function createNewQuest(
        // user identifiers
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        uint256 _duration,
        address _token,
        string memory _questId
    ) external onlyBarkeeper whenNotPaused {
        require(
            !TavernStorage.tavernStorage().questExists2[_questId],
            "Quest already exists"
        );
        require(
            TavernStorage.tavernStorage().whitelistedTokens[_token],
            "Invalid token"
        );

        DiamondQuest quest = new DiamondQuest(
            LibOwnership._owner(),
            INexus(TavernStorage.tavernStorage().nexus)
                .getDiamondCutImplementation(),
            TavernStorage.tavernStorage().questImplementation
        );
        address taxManager = INexus(TavernStorage.tavernStorage().nexus)
            .getTaxManager();

        require(taxManager != address(0), "TaxManager not set");

        emit QuestCreatedToken(
            _seekerId,
            _solverId,
            address(quest),
            _maxExtensions,
            _paymentAmount,
            _token
        );

        TavernStorage.tavernStorage().questExists2[_questId] = true;
        TavernStorage.tavernStorage().questIdToAddress[_questId] = address(
            quest
        );

        IQuest(address(quest)).initialize(
            _seekerId,
            _solverId,
            _paymentAmount,
            infoURI,
            _maxExtensions,
            _duration,
            _token,
            TavernStorage.tavernStorage().escrowTokenImplementation
        );
    }

    function pauseAdmin() external onlyBarkeeper {
        LibPausable._pause();
    }

    function unpauseAdmin() external onlyBarkeeper {
        LibPausable._unpause();
    }

    /*//////////////////////////////////////////////////////////////
                            only-owner
    //////////////////////////////////////////////////////////////*/

    function setBarkeeper(address keeper) external onlyOwner {
        TavernStorage.tavernStorage().barkeeper = keeper;
    }

    function setNexus(address _nexus) external onlyOwner {
        TavernStorage.tavernStorage().nexus = _nexus;
    }

    function setMediator(address _mediator) external onlyOwner {
        TavernStorage.tavernStorage().mediator = _mediator;
    }

    function setReviewPeriod(uint256 period) external onlyOwner {
        TavernStorage.tavernStorage().reviewPeriod = period;
    }

    function setExtensionPeriod(uint256 period) external onlyOwner {
        TavernStorage.tavernStorage().extensionPeriod = period;
    }

    function setDeadlineMultiplier(uint256 multiplier) external onlyOwner {
        TavernStorage.tavernStorage().deadlineMultiplier = multiplier;
    }

    function setImplementation(
        address implNative,
        address implToken,
        address implQuest
    ) external onlyOwner {
        TavernStorage.tavernStorage().escrowNativeImplementation = implNative;
        TavernStorage.tavernStorage().escrowTokenImplementation = implToken;
        TavernStorage.tavernStorage().questImplementation = implQuest;
    }

    /**
     * @dev Add/remove whitelisted token
     */
    function setWhitelistToken(address _token, bool value) external onlyOwner {
        require(_token != address(0));
        TavernStorage.tavernStorage().whitelistedTokens[_token] = value;
    }

    function setExtendEnabled(bool value) external onlyOwner {
        TavernStorage.tavernStorage().extendEnabled = value;
    }

    function setDisputeEnabled(bool value) external onlyOwner {
        TavernStorage.tavernStorage().disputeEnabled = value;
    }

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function nexus() external view returns (address) {
        return TavernStorage.tavernStorage().nexus;
    }

    function getRewarder() external view returns (address) {
        return INexus(TavernStorage.tavernStorage().nexus).getRewarder();
    }

    function mediator() external view returns (address) {
        return TavernStorage.tavernStorage().mediator;
    }

    function getBarkeeper() external view returns (address) {
        return TavernStorage.tavernStorage().barkeeper;
    }

    function getProfileNFT() public view returns (address) {
        return INexus(TavernStorage.tavernStorage().nexus).getNFT();
    }

    function ownerOf(uint32 nftId) external view returns (address) {
        return
            IProfileNFT(INexus(TavernStorage.tavernStorage().nexus).getNFT())
                .ownerOf(nftId);
    }

    function confirmNFTOwnership(
        address identity
    ) external view returns (bool confirmed) {
        confirmed =
            IProfileNFT(INexus(TavernStorage.tavernStorage().nexus).getNFT())
                .balanceOf(identity) >
            0;
    }

    function reviewPeriod() external view returns (uint256) {
        return TavernStorage.tavernStorage().reviewPeriod;
    }

    function extensionPeriod() external view returns (uint256) {
        return TavernStorage.tavernStorage().extensionPeriod;
    }

    function deadlineMultiplier() external view returns (uint256) {
        return TavernStorage.tavernStorage().deadlineMultiplier;
    }

    function questIdToAddress(
        string memory questId
    ) external view returns (address) {
        return TavernStorage.tavernStorage().questIdToAddress[questId];
    }

    function escrowNativeImplementation() external view returns (address) {
        return TavernStorage.tavernStorage().escrowNativeImplementation;
    }

    function escrowTokenImplementation() external view returns (address) {
        return TavernStorage.tavernStorage().escrowTokenImplementation;
    }

    function questImplementation() external view returns (address) {
        return TavernStorage.tavernStorage().questImplementation;
    }

    function isTokenWhitelisted(address _token) external view returns (bool) {
        return TavernStorage.tavernStorage().whitelistedTokens[_token];
    }

    function isExtendEnabled() external view returns (bool) {
        return TavernStorage.tavernStorage().extendEnabled;
    }

    function isDisputeEnabled() external view returns (bool) {
        return TavernStorage.tavernStorage().disputeEnabled;
    }

    /*//////////////////////////////////////////////////////////////
                            IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](32);
        s[0] = bytes4(
            keccak256(
                bytes(
                    "createNewQuest(uint32,uint32,uint256,string,uint256,uint256,string)"
                )
            )
        );
        s[1] = bytes4(
            keccak256(
                bytes(
                    "createNewQuest(uint32,uint32,uint256,string,uint256,uint256,address,string)"
                )
            )
        );
        s[2] = ITavern.setBarkeeper.selector;
        s[3] = ITavern.setNexus.selector;
        s[4] = ITavern.setMediator.selector;
        s[5] = ITavern.setReviewPeriod.selector;
        s[6] = ITavern.setImplementation.selector;
        s[7] = ITavern.setWhitelistToken.selector;
        s[8] = ITavern.nexus.selector;
        s[9] = ITavern.getRewarder.selector;
        s[10] = ITavern.mediator.selector;
        s[11] = ITavern.getBarkeeper.selector;
        s[12] = ITavern.getProfileNFT.selector;
        s[13] = ITavern.ownerOf.selector;
        s[14] = ITavern.confirmNFTOwnership.selector;
        s[15] = ITavern.reviewPeriod.selector;
        s[16] = ITavern.pauseAdmin.selector;
        s[17] = ITavern.unpauseAdmin.selector;
        s[18] = ITavern.extensionPeriod.selector;
        s[19] = ITavern.setExtensionPeriod.selector;
        s[20] = ITavern.deadlineMultiplier.selector;
        s[21] = ITavern.setDeadlineMultiplier.selector;
        s[22] = ITavern.questIdToAddress.selector;
        s[23] = ITavern.escrowNativeImplementation.selector;
        s[24] = ITavern.escrowTokenImplementation.selector;
        s[25] = ITavern.questImplementation.selector;
        s[26] = IFacet.pluginMetadata.selector;
        s[27] = ITavern.isTokenWhitelisted.selector;
        s[28] = ITavern.isExtendEnabled.selector;
        s[29] = ITavern.setExtendEnabled.selector;
        s[30] = ITavern.isDisputeEnabled.selector;
        s[31] = ITavern.setDisputeEnabled.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(ITavern).interfaceId;
    }
}
