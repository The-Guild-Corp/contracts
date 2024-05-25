//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../interfaces/IERC6551/IERC6551Account.sol";
import "../../interfaces/IERC6551/IER6551Executable.sol";
import "../../interfaces/IReferralHandler.sol";
import "../../interfaces/ITierManager.sol";
import "../../interfaces/ITaxManager.sol";
import "../../interfaces/INexus.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {AccountStorage} from "./storage/AccountStorage.sol";

/**
 * @title The Guild User Account
 * @notice Erc6551 Account + Referral Handler
 */
contract AccountFacet is
    IERC165,
    IERC1271,
    IERC6551Account,
    IERC6551Executable,
    IReferralHandler,
    IERC721Receiver,
    IFacet
{
    receive() external payable {}

    modifier onlyOwner() {
        LibOwnership._isOwner();
        _;
    }

    modifier onlyProtocol() {
        require(
            msg.sender ==
                INexus(AccountStorage.accountStorage().nexus).getGuardian() ||
                msg.sender == address(AccountStorage.accountStorage().nexus),
            "Account: Only Guardian or Nexus"
        );
        _;
    }

    modifier onlyNexus() {
        require(
            msg.sender == AccountStorage.accountStorage().nexus,
            "only nexus"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          Referral-Handler
    //////////////////////////////////////////////////////////////*/

    function initialize(address _referredBy) external {
        require(
            !AccountStorage.accountStorage().initialized,
            "Already initialized"
        );
        AccountStorage.accountStorage().nexus = msg.sender;
        AccountStorage.accountStorage().initialized = true;
        AccountStorage.accountStorage().referredBy = _referredBy;
        AccountStorage.accountStorage().mintTime = block.timestamp;
        AccountStorage.accountStorage().tier = 1; // Default tier is 1 instead of 0, since solidity 0 can also mean non-existent
        AccountStorage.accountStorage().canLevel = true;
    }

    /**
     * @dev Can be called by anyone
     */
    function tierUp() external returns (bool) {
        // An account with tier 0 (Banned) can't tier up
        require(
            getTier() < 5 &&
                getTier() > 0 &&
                AccountStorage.accountStorage().canLevel,
            "Can't increase the tier"
        );

        require(
            getTierManager().checkTierUpgrade(
                getTierCounts(),
                address(this),
                AccountStorage.accountStorage().tier
            ),
            "Tier upgrade condition not met"
        );

        uint8 oldTier = getTier();
        AccountStorage.accountStorage().tier++;

        emit LevelChanged(oldTier, getTier());

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////*/

    function setNexus(address account) public onlyOwner {
        AccountStorage.accountStorage().nexus = account;
    }

    function owner_setReferredBy(address account) public onlyOwner {
        AccountStorage.accountStorage().referredBy = account;
    }

    /**
     * Update the user tier
     * @param _tier New tier to be set for user (from 0 to 5)
     */
    function setTier(uint8 _tier) public onlyProtocol {
        require(_tier >= 0 && _tier <= 5, "Invalid Tier");
        uint8 oldTier = getTier();
        AccountStorage.accountStorage().tier = _tier;

        emit LevelChanged(oldTier, getTier());
    }

    function changeEligibility(bool status) public onlyOwner {
        AccountStorage.accountStorage().canLevel = status;
    }

    /**
     * @notice Adds new Handler to the Referral Tree
     * @param refDepth Number of layers between the referral and referee
     * @param referralHandler Address of the handler of referred person(referral)
     * @dev Can be called only by Nexus
     */
    function addToReferralTree(
        uint8 refDepth,
        address referralHandler
    ) external onlyNexus {
        require(refDepth <= 4 && refDepth >= 1, "Invalid depth");
        require(referralHandler != address(0), "Invalid referral address");
        AccountStorage.StorageStruct storage s = AccountStorage
            .accountStorage();
        if (refDepth == 1) {
            s.firstLevelRefs[s.firstLevelCount] = referralHandler;
            s.firstLevelCount++;
        } else if (refDepth == 2) {
            s.secondLevelRefs[s.secondLevelCount] = referralHandler;
            s.secondLevelCount++;
        } else if (refDepth == 3) {
            s.thirdLevelRefs[s.thirdLevelCount] = referralHandler;
            s.thirdLevelCount++;
        } else if (refDepth == 4) {
            s.fourthLevelRefs[s.fourthLevelCount] = referralHandler;
            s.fourthLevelCount++;
        }
    }

    // /*//////////////////////////////////////////////////////////////
    //                         Read-Functions
    // //////////////////////////////////////////////////////////////*/

    function getNft() public view returns (address) {
        (, address nftAddr, ) = token();
        return nftAddr;
    }

    function getNftId() public view returns (uint32) {
        (, , uint256 nftId) = token();
        return uint32(nftId);
    }

    function getTier() public view returns (uint8) {
        return AccountStorage.accountStorage().tier;
    }

    function getTierManager() public view returns (ITierManager) {
        address tierManager = INexus(AccountStorage.accountStorage().nexus)
            .getTierManager();
        return ITierManager(tierManager);
    }

    function getTaxManager() public view returns (ITaxManager) {
        address taxManager = INexus(AccountStorage.accountStorage().nexus)
            .getTaxManager();
        return ITaxManager(taxManager);
    }

    /**
     * @notice Checks for existence of the given address on the given depth of the tree
     * @param refDepth A layer of the referral connection (from 1 to 4)
     * @param referralHandler Address of the Handler Account of referral
     * @return _tier Returns 0 if it does not exist, else returns the NFT tier
     */
    function checkReferralExistence(
        uint8 refDepth,
        address referralHandler
    ) public view returns (uint8 _tier) {
        require(refDepth <= 4 && refDepth >= 1, "Invalid depth");
        require(referralHandler != address(0), "Invalid referred address");

        return IReferralHandler(referralHandler).getTier();
    }

    /**
     * @notice Returns number of referrals for each tier
     * @return Returns array of counts for Tiers 1 to 5 under the user
     */
    function getTierCounts() public view returns (uint32[5] memory) {
        AccountStorage.StorageStruct storage s = AccountStorage
            .accountStorage();
        uint32[5] memory tierCounts; // Tiers can be 0 to 5, here we account only tiers 1 to 5
        for (uint32 i = 0; i < s.firstLevelCount; ++i) {
            address referral = s.firstLevelRefs[i];
            uint8 _tier = IReferralHandler(referral).getTier();
            // If tier is 0, which is blacklisted, then we just skip it
            if (_tier == 0) {
                continue;
            }

            tierCounts[_tier - 1]++;
        }
        for (uint32 i = 0; i < s.secondLevelCount; ++i) {
            address referral = s.secondLevelRefs[i];
            uint8 _tier = IReferralHandler(referral).getTier();

            // If tier is 0, which is blacklisted, then we just skip it
            if (_tier == 0) {
                continue;
            }

            tierCounts[_tier - 1]++;
        }
        for (uint32 i = 0; i < s.thirdLevelCount; ++i) {
            address referral = s.thirdLevelRefs[i];
            uint8 _tier = IReferralHandler(referral).getTier();

            // If tier is 0, which is blacklisted, then we just skip it
            if (_tier == 0) {
                continue;
            }

            tierCounts[_tier - 1]++;
        }
        for (uint32 i = 0; i < s.fourthLevelCount; ++i) {
            address referral = s.fourthLevelRefs[i];
            uint8 _tier = IReferralHandler(referral).getTier();

            // If tier is 0, which is blacklisted, then we just skip it
            if (_tier == 0) {
                continue;
            }

            tierCounts[_tier - 1]++;
        }

        return tierCounts;
    }

    /*//////////////////////////////////////////////////////////////
                            PSEUDO-ERC-6551
    //////////////////////////////////////////////////////////////*/

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8
    ) external payable returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        ++AccountStorage.accountStorage()._state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    function isValidSigner(
        address signer,
        bytes calldata
    ) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            nftOwner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId);
    }

    function token() public view returns (uint256, address, uint256) {
        address nft = AccountStorage.accountStorage().NFT;
        uint256 nftId = AccountStorage.accountStorage().NFTid;
        uint256 chaindId = AccountStorage.accountStorage().chainId;

        return (chaindId, nft, nftId);
    }

    function nftOwner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == nftOwner();
    }

    function state() external view override returns (uint256) {
        return AccountStorage.accountStorage()._state;
    }

    function referredBy() external view override returns (address) {
        return AccountStorage.accountStorage().referredBy;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // End of Account

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](24);
        s[0] = IERC6551Account.token.selector;
        s[1] = IERC6551Account.state.selector;
        s[2] = IERC6551Account.isValidSigner.selector;
        s[3] = AccountFacet.isValidSignature.selector;
        s[4] = IERC6551Executable.execute.selector;
        s[5] = IReferralHandler.initialize.selector;
        s[6] = IReferralHandler.tierUp.selector;
        s[7] = IReferralHandler.setNexus.selector;
        s[8] = IReferralHandler.setTier.selector;
        s[9] = IReferralHandler.changeEligibility.selector;
        s[10] = IReferralHandler.addToReferralTree.selector;
        s[11] = IReferralHandler.getNft.selector;
        s[12] = IReferralHandler.getNftId.selector;
        s[13] = IReferralHandler.getTier.selector;
        s[14] = IReferralHandler.getTierManager.selector;
        s[15] = IReferralHandler.getTaxManager.selector;
        s[16] = IReferralHandler.checkReferralExistence.selector;
        s[17] = IReferralHandler.getTierCounts.selector;
        s[18] = IReferralHandler.referredBy.selector;
        s[19] = IReferralHandler.nftOwner.selector;
        s[20] = AccountFacet.supportsInterface.selector;
        s[21] = AccountFacet.pluginMetadata.selector;
        s[22] = AccountFacet.onERC721Received.selector;
        s[23] = IReferralHandler.owner_setReferredBy.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IERC6551Account).interfaceId;
    }
}
