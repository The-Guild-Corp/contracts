// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface IRewarder {
    event RewardNativeClaimed(
        address indexed solverAccount,
        address escrow,
        uint256 solverReward
    );

    event RewardTokenClaimed(
        address indexed solverAccount,
        address escrow,
        uint256 solverReward,
        address token
    );

    event SeekerTaxPaidNative(
        address indexed seekerAccount,
        address escrow,
        uint256 tax
    );

    event SeekerTaxPaidToken(
        address indexed seekerAccount,
        address escrow,
        uint256 tax,
        address token
    );

    event DisputeDepositPaidNative(address escrow, uint256 deposit);

    event DisputeDepositPaidToken(
        address escrow,
        uint256 deposit,
        address token
    );

    event ReferralRewardReceived(
        address account,
        uint256 amount,
        address token
    );

    event RationsTaxPaid(
        address partyLeader,
        uint256 leaderRewardsTax,
        uint256 referralRewardsTax,
        uint256 platformRevenueTax,
        uint256 partyMemberRewardsTax,
        address token
    );

    function handleRewardNative(
        uint32 solverId,
        uint256 amount
    ) external payable;

    function handleRewardToken(
        address token,
        uint32 solverId,
        uint256 amount
    ) external;

    function handleStartDisputeNative(uint256 paymentAmount) external payable;

    function handleStartDisputeToken(
        uint256 paymentAmount,
        address token,
        uint32 seekerId
    ) external;

    function processResolutionNative(
        uint32 seekerId,
        uint32 solverId,
        uint32 solverShare
    ) external payable;

    function processResolutionToken(
        uint32 seekerId,
        uint32 solverId,
        uint32 solverShare,
        address token,
        uint256 payment
    ) external;

    function calculateSeekerTax(
        uint256 paymentAmount
    )
        external
        returns (uint256 platformTax, uint256 referralTax, uint256 sharesTax);

    function calculateRationsTax(
        uint256 price
    )
        external
        returns (
            uint256 leaderRewardsTax,
            uint256 referralRewardsTax,
            uint256 platformRevenueTax,
            uint256 partyMemberRewardsTax
        );

    function handleSeekerTaxNative(
        uint32 _seekerId,
        uint256 _referralTaxAmount,
        uint256 _platformTaxAmount,
        uint256 _sharesTaxAmount
    ) external payable;

    function handleSeekerTaxToken(
        uint32 _seekerId,
        uint256 _referralTaxAmount,
        uint256 _platformTaxAmount,
        uint256 _sharesTaxAmount,
        address token
    ) external;

    function handleRationsTax(
        uint32 leaderTokenId,
        uint256 leaderRewardsTax,
        uint256 referralRewardsTax,
        uint256 platformRevenueTax,
        uint256 partyMemberRewardsTax,
        address safehold
    ) external payable;
}
