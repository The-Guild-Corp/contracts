// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITaxManager.sol";

/**
 * @title Tax Manager contract
 * @notice Holds tax rates and pool addresses
 * @dev Readonly contract; functions divided by pool and rate relation
 */
contract TaxManager is ITaxManager {
    using SafeERC20 for IERC20;

    address public custodian;

    // Seeker and Solver fees broken down
    SeekerFees public seekerFees;
    SolverFees public solverFees;
    PartyFees public partyFees;

    // Tax Rates variables
    uint256 public disputeDepositRate; // with base divisor

    // Pools
    address public platformTreasury;
    address public platformRevenuePool;
    address public referralTaxTreasury;
    address public disputeFeesTreasury;
    address public participationRewardPool;

    uint256 public constant taxBaseDivisor = 10000;

    mapping(uint8 => ReferralTaxRates) referralRatesByTier; // tier to referral rates by refDepth

    uint256 public referralRewardsTax;
    ReferralRewardsFees public referralRewardsFees;

    LeftoverReferralRewards public leftoverReferralRewards;

    modifier onlyCustodian() {
        require(msg.sender == custodian, "only custodian"); // need multiple admins
        _;
    }

    modifier validTaxRate(uint256 _taxRate) {
        require(_taxRate < taxBaseDivisor, "Tax rate too high");
        _;
    }

    constructor() {
        custodian = msg.sender;
    }

    function setCustodian(address account) public onlyCustodian {
        custodian = account;
    }

    /**
     * @notice Get Referral reward rate
     * @param depth  A layer of the referral connection (from 1 to 4)
     * @param tier A targeted tier
     * @return Referral reward rate based on the tier and depth of connection
     */
    function getReferralRate(
        uint8 depth,
        uint8 tier
    ) external view returns (uint256) {
        if (depth == 1) {
            return referralRatesByTier[tier].first;
        } else if (depth == 2) {
            return referralRatesByTier[tier].second;
        } else if (depth == 3) {
            return referralRatesByTier[tier].third;
        } else if (depth == 4) {
            return referralRatesByTier[tier].fourth;
        }
        return 0;
    }

    //
    //
    // Setters for Pool Addresses
    //
    //

    function setPlatformTreasuryPool(
        address _platformTreasuryPool
    ) external onlyCustodian {
        require(_platformTreasuryPool != address(0), "Zero address");
        platformTreasury = _platformTreasuryPool;
    }

    function setPlatformRevenuePool(
        address _platformRevenuePool
    ) external onlyCustodian {
        require(_platformRevenuePool != address(0), "Zero address");
        platformRevenuePool = _platformRevenuePool;
    }

    function setReferralTaxTreasury(
        address _referralTaxTreasury
    ) external onlyCustodian {
        require(_referralTaxTreasury != address(0), "Zero address");
        referralTaxTreasury = _referralTaxTreasury;
    }

    function setDisputeFeesTreasury(
        address _disputeFeesTreasury
    ) external onlyCustodian {
        require(_disputeFeesTreasury != address(0), "Zero address");
        disputeFeesTreasury = _disputeFeesTreasury;
    }

    function setParticipationRewardPool(
        address _participationRewardPool
    ) external onlyCustodian {
        require(_participationRewardPool != address(0), "Zero address");
        participationRewardPool = _participationRewardPool;
    }

    //
    //
    // Getters for the Tax Rates
    //
    //

    function getSeekerTaxRate() external view returns (uint256) {
        return
            seekerFees.referralRewards +
            seekerFees.platformRevenue +
            seekerFees.sharesTax;
    }

    function getSolverTaxRate() external view returns (uint256) {
        return
            solverFees.referralRewards +
            solverFees.platformRevenue +
            solverFees.platformTreasury +
            solverFees.sharesTax;
    }

    function getPartyTaxRate() external view returns (uint256) {
        return
            partyFees.leaderRewards +
            partyFees.referralRewards +
            partyFees.platformRevenue +
            partyFees.partyMemberRewards;
    }

    function getReferralRewardsRevenue() external view returns (uint256) {
        return referralRewardsFees.platformRevenue;
    }

    function getReferralRewardsParticipation() external view returns (uint256) {
        return referralRewardsFees.participationRewards;
    }

    function getSeekerFees() external view returns (SeekerFees memory) {
        return seekerFees;
    }

    function getSolverFees() external view returns (SolverFees memory) {
        return solverFees;
    }

    function getPartyFees() external view returns (PartyFees memory) {
        return partyFees;
    }

    function leftoverPlatformRevenue() external view returns (uint256) {
        return leftoverReferralRewards.leftoverPlatformRevenue;
    }

    function leftoverPlatformTreasury() external view returns (uint256) {
        return leftoverReferralRewards.leftoverPlatformTreasury;
    }

    function leftoverMarketing() external view returns (uint256) {
        return leftoverReferralRewards.leftoverMarketing;
    }

    //
    //
    // Setters for the Tax Rates
    //
    //

    function setSeekerFees(
        uint256 _referralRewards,
        uint256 _platformRevenuePool,
        uint256 _sharesTax
    )
        external
        onlyCustodian
        validTaxRate(_referralRewards)
        validTaxRate(_platformRevenuePool)
        validTaxRate(_sharesTax)
    {
        require(platformRevenuePool != address(0), "Zero address");
        require(referralTaxTreasury != address(0), "Zero address");
        require(
            _referralRewards + _platformRevenuePool + _sharesTax <=
                taxBaseDivisor,
            "Tax rate too high"
        );
        seekerFees.referralRewards = _referralRewards;
        seekerFees.platformRevenue = _platformRevenuePool;
        seekerFees.sharesTax = _sharesTax;
    }

    function setSolverFees(
        uint256 _referralTaxReceiver,
        uint256 _platformRevenuePool,
        uint256 _platformTreasuryPool,
        uint256 _sharesTax
    )
        external
        onlyCustodian
        validTaxRate(_referralTaxReceiver)
        validTaxRate(_platformRevenuePool)
        validTaxRate(_platformTreasuryPool)
    {
        require(referralTaxTreasury != address(0), "Zero address");
        require(platformRevenuePool != address(0), "Zero address");
        require(platformTreasury != address(0), "Zero address");

        require(
            _referralTaxReceiver +
                _platformTreasuryPool +
                _platformRevenuePool <=
                taxBaseDivisor,
            "Tax rate too high"
        );

        solverFees.referralRewards = _referralTaxReceiver;
        solverFees.platformRevenue = _platformRevenuePool;
        solverFees.platformTreasury = _platformTreasuryPool;
        solverFees.sharesTax = _sharesTax;
    }

    function setPartyFees(
        uint256 _leaderRewards,
        uint256 _referralRewards,
        uint256 _platformRevenuePool,
        uint256 _partyMemberRewards
    )
        external
        onlyCustodian
        validTaxRate(_leaderRewards)
        validTaxRate(_referralRewards)
        validTaxRate(_platformRevenuePool)
        validTaxRate(_partyMemberRewards)
    {
        require(referralTaxTreasury != address(0), "Zero address");
        require(platformRevenuePool != address(0), "Zero address");

        require(
            _leaderRewards +
                _referralRewards +
                _platformRevenuePool +
                _partyMemberRewards <=
                taxBaseDivisor,
            "Tax rate too high"
        );

        partyFees.leaderRewards = _leaderRewards;
        partyFees.referralRewards = _referralRewards;
        partyFees.platformRevenue = _platformRevenuePool;
        partyFees.partyMemberRewards = _partyMemberRewards;
    }

    function setBulkReferralRate(
        uint8 tier,
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    )
        external
        onlyCustodian
        validTaxRate(first)
        validTaxRate(second)
        validTaxRate(third)
        validTaxRate(fourth)
    {
        referralRatesByTier[tier].first = first;
        referralRatesByTier[tier].second = second;
        referralRatesByTier[tier].third = third;
        referralRatesByTier[tier].fourth = fourth;
    }

    function setDisputeDepositRate(
        uint256 _disputeDepositRate
    ) external onlyCustodian validTaxRate(_disputeDepositRate) {
        disputeDepositRate = _disputeDepositRate;
    }

    function setReferralRewardsTaxRate(
        uint256 _referralRewardsTax
    ) external onlyCustodian validTaxRate(_referralRewardsTax) {
        referralRewardsTax = _referralRewardsTax;
    }

    // Should add up to 100%
    function setReferralRewardsFee(
        uint256 _platformRevenue,
        uint256 _participationRewards
    )
        external
        onlyCustodian
        validTaxRate(_platformRevenue)
        validTaxRate(_participationRewards)
    {
        require(platformRevenuePool != address(0), "Zero address");

        require(
            _platformRevenue + _participationRewards <= taxBaseDivisor,
            "Tax rate too high"
        );
        referralRewardsFees.platformRevenue = _platformRevenue;
        referralRewardsFees.participationRewards = _participationRewards;
    }

    // Should add up to 100%
    function setLeftoverReferralRewards(
        uint256 _leftoverPlatformRevenue,
        uint256 _leftoverPlatformTreasury,
        uint256 _leftoverMarketing
    )
        external
        onlyCustodian
        validTaxRate(_leftoverPlatformRevenue)
        validTaxRate(_leftoverPlatformTreasury)
        validTaxRate(_leftoverMarketing)
    {
        require(platformRevenuePool != address(0), "Zero address");
        require(platformTreasury != address(0), "Zero address");

        require(
            _leftoverPlatformRevenue +
                _leftoverPlatformTreasury +
                _leftoverMarketing <=
                taxBaseDivisor,
            "Tax rate too high"
        );

        leftoverReferralRewards
            .leftoverPlatformRevenue = _leftoverPlatformRevenue;
        leftoverReferralRewards
            .leftoverPlatformTreasury = _leftoverPlatformTreasury;
        leftoverReferralRewards.leftoverMarketing = _leftoverMarketing;
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) external onlyCustodian {
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
