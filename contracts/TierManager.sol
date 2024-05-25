// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "./interfaces/IReferralHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITierManager.sol";

/**
 * @title Tier Manager contract
 * @notice Holds tier up requirements and checks these conditions
 */
contract TierManager is ITierManager {
    using SafeERC20 for IERC20;

    struct TierParameters {
        uint256 xpPoints;
        uint256 novicesReferred;
        uint256 adeptsReferred;
        uint256 expertsReferred;
        uint256 mastersReferred;
        uint256 godsReferred;
    }

    address public magistrate;
    address public xpToken;
    mapping(uint256 => TierParameters) public tierUpConditions;
    mapping(uint256 => uint256) public rationLimits;
    mapping(uint256 => uint256) public transferLimits;

    modifier onlyMagistrate() {
        require(msg.sender == magistrate, "only magistrate");
        _;
    }

    constructor(address _xpToken) {
        magistrate = msg.sender;
        xpToken = _xpToken;
    }

    function setMagistrate(address account) external onlyMagistrate {
        magistrate = account;
    }

    function setXpToken(address token) external onlyMagistrate {
        xpToken = token;
    }

    function setConditions(
        uint8 tier,
        uint256 xpPoints,
        uint256 novicesReferred,
        uint256 adeptsReferred,
        uint256 expertsReferred,
        uint256 mastersReferred,
        uint256 godsReferred
    ) external onlyMagistrate {
        tierUpConditions[tier].novicesReferred = novicesReferred;
        tierUpConditions[tier].adeptsReferred = adeptsReferred;
        tierUpConditions[tier].expertsReferred = expertsReferred;
        tierUpConditions[tier].mastersReferred = mastersReferred;
        tierUpConditions[tier].godsReferred = godsReferred;
        tierUpConditions[tier].xpPoints = xpPoints;
    }

    function setRationLimit(uint8 tier, uint256 limit) external onlyMagistrate {
        rationLimits[tier] = limit;
    }

    function getRationLimit(uint8 tier) external view returns (uint256) {
        return rationLimits[tier];
    }

    /**
     * @notice Check if user is valid for the tier upgrade
     * @param tierCounts Number of referrals of each tier, referred by this person
     * @param account User account(referral handler)
     * @param tier Desired tier to be upgraded to
     * @dev If it returns true, means user has the requirement for the tier sent as parameter
     */
    function validateUserTier(
        uint32[5] memory tierCounts,
        address account,
        uint8 tier
    ) internal view returns (bool) {
        require(
            tierUpConditions[tier].xpPoints != 0,
            "Tier conditions not set"
        );

        uint64 totalTierCounts;
        for (uint8 i = 0; i < 5; i++) {
            totalTierCounts += tierCounts[i];
        }

        if (totalTierCounts < tierUpConditions[tier].novicesReferred) {
            return false;
        }
        totalTierCounts -= tierCounts[0];

        if (totalTierCounts < tierUpConditions[tier].adeptsReferred) {
            return false;
        }
        totalTierCounts -= tierCounts[1];

        if (totalTierCounts < tierUpConditions[tier].expertsReferred) {
            return false;
        }
        totalTierCounts -= tierCounts[2];

        if (totalTierCounts < tierUpConditions[tier].mastersReferred) {
            return false;
        }
        totalTierCounts -= tierCounts[3];

        if (totalTierCounts < tierUpConditions[tier].godsReferred) {
            return false;
        }
        totalTierCounts -= tierCounts[4];

        IERC20 xp = IERC20(xpToken);
        if (xp.balanceOf(account) < tierUpConditions[tier].xpPoints)
            return false;

        return true;
    }

    function checkTierUpgrade(
        uint32[5] memory tierCounts,
        address account,
        uint8 tier
    ) external view override returns (bool) {
        uint8 newTier = tier + 1;
        return validateUserTier(tierCounts, account, newTier); // If it returns true it means user is eligible for an upgrade in tier
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) external onlyMagistrate {
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
