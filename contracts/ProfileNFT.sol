// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/INexus.sol";
import "./interfaces/IReferralHandler.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Guild Profile NFT
 * @author @cosmodude
 * @notice NFTs tied up to the user account(profile)
 * @dev Nexus controls the mint, use safeTransfer for safety
 */
contract ProfileNFT is ERC721URIStorage {
    using SafeERC20 for IERC20;

    uint32 private _tokenCounter;

    address public counselor;
    address public nexus;

    event NewURI(string oldTokenURI, string newTokenURI);

    modifier onlyNexus() {
        // nexus / hub
        require(msg.sender == nexus, "only nexus");
        _;
    }

    modifier onlyCounselor() {
        require(msg.sender == counselor, "only Counselor");
        _;
    }

    constructor(address _nexus) ERC721("The Guild Profile NFT", "GuildNFT") {
        counselor = msg.sender;
        nexus = _nexus;
        _tokenCounter++; // Start Token IDs from 1 instead of 0, we use 0 to indicate absence of NFT on a wallet
    }

    function issueProfile(
        address user,
        string memory _tokenURI
    ) public onlyNexus returns (uint32) {
        uint32 newNFTId = _tokenCounter;
        _tokenCounter++;
        _mint(user, newNFTId);
        _setTokenURI(newNFTId, _tokenURI);
        return newNFTId;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint32 _tokenId) external {
        super.safeTransferFrom(msg.sender, _to, _tokenId);
    }

    function changeURI(uint32 tokenID, string memory _tokenURI) external {
        address guardian = INexus(nexus).getGuardian();
        require(msg.sender == guardian, "Only Guardian can update Token's URI");
        string memory oldURI = tokenURI(tokenID);
        _setTokenURI(tokenID, _tokenURI);
        emit NewURI(oldURI, tokenURI(tokenID));
    }

    function setCounselor(address account) public onlyCounselor {
        counselor = account;
    }

    function setNexus(address account) public onlyCounselor {
        nexus = account;
    }

    function getTier(uint32 tokenID) public view returns (uint8) {
        address handler = INexus(nexus).getHandler(tokenID);
        return IReferralHandler(handler).getTier();
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) external onlyCounselor {
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
}
