// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Contract of the Guild Xp Token
 * @notice ERC20 non-transferrable token 
 * @dev Transfers enabled only from owner address
 */
contract GuildXp is ERC20, Ownable, ERC20Permit{
    address public distributor;

    constructor(address _owner) ERC20("GuildXp", "XP") Ownable(_owner) ERC20Permit("GuildXp"){}
    
    // set decimals to 2
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    // Override `transfer` and `transferFrom` to prevent token transfers
    function transfer(address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: transfer not allowed");
    }

    // Override `transferFrom` to allow transfers only from the owner's address
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(distributor != address(0), "Distributor address not set");
        require(from == distributor, "DistributorTransferOnlyToken: transfers are allowed only from the distributor");
        return super.transferFrom(from, to, amount);
    }

    /**
     * @notice Mints tokens to the specified address
     * @param to The address of the recipient
     * @param amount Amount of tokens (with 2 decimals)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens function
     * @dev only callable by the owner 
     * @param from The address from which the tokens get burned
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
    }
}
