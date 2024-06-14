// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface ITaxManager {
    struct SeekerFees {
        uint256 referralRewards;
        uint256 platformRevenue;
        uint256 sharesTax;
    }

    struct SolverFees {
        uint256 referralRewards;
        uint256 platformRevenue;
        uint256 platformTreasury;
        uint256 sharesTax;
    }

    struct PartyFees {
        uint256 leaderRewards;
        uint256 referralRewards;
        uint256 platformRevenue;
        uint256 partyMemberRewards;
    }

    struct ReferralTaxRates {
        uint256 first;
        uint256 second;
        uint256 third;
        uint256 fourth;
    }

    struct ReferralRewardsFees {
        uint256 platformRevenue;
        uint256 participationRewards;
    }

    struct LeftoverReferralRewards {
        uint256 leftoverPlatformRevenue;
        uint256 leftoverPlatformTreasury;
        uint256 leftoverMarketing;
    }

    function taxBaseDivisor() external view returns (uint256);

    function getSeekerTaxRate() external view returns (uint256);

    function getSolverTaxRate() external view returns (uint256);

    function getPartyTaxRate() external view returns (uint256);

    function getSeekerFees() external view returns (SeekerFees memory);

    function getSolverFees() external view returns (SolverFees memory);

    function getPartyFees() external view returns (PartyFees memory);

    function getReferralRewardsRevenue() external view returns (uint256);

    function getReferralRewardsParticipation() external view returns (uint256);

    function platformTreasury() external view returns (address);

    function platformRevenuePool() external view returns (address);

    function referralTaxTreasury() external view returns (address);

    function disputeFeesTreasury() external view returns (address);

    function participationRewardPool() external view returns (address);

    function disputeDepositRate() external view returns (uint256);

    function referralRewardsTax() external view returns (uint256);

    function leftoverPlatformRevenue() external view returns (uint256);

    function leftoverPlatformTreasury() external view returns (uint256);

    function leftoverMarketing() external view returns (uint256);

    function getReferralRate(
        uint8 depth,
        uint8 tier
    ) external view returns (uint256);
}
