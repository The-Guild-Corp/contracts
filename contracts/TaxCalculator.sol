// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import "./interfaces/ITaxManager.sol";

library TaxCalculator {
    function _calculateSeekerTax(
        ITaxManager _taxManager,
        uint256 _paymentAmount
    )
        internal
        view
        returns (uint256 platformTax_, uint256 referralTax_, uint256 sharesTax_)
    {
        ITaxManager.SeekerFees memory seekerFees = _taxManager.getSeekerFees();
        uint256 taxRateDivisor = _taxManager.taxBaseDivisor();

        referralTax_ =
            (_paymentAmount * seekerFees.referralRewards) /
            taxRateDivisor;

        platformTax_ =
            (_paymentAmount * seekerFees.platformRevenue) /
            taxRateDivisor;

        sharesTax_ = (_paymentAmount * seekerFees.sharesTax) / taxRateDivisor;

        return (platformTax_, referralTax_, sharesTax_);
    }

    function _calculateSolverTax(
        ITaxManager _taxManager,
        uint256 _paymentAmount
    )
        internal
        view
        returns (
            uint256 platformTax_,
            uint256 referralTax_,
            uint256 platformTreasuryTax_,
            uint256 sharesTax_
        )
    {
        ITaxManager.SolverFees memory solverFees = _taxManager.getSolverFees();
        uint256 taxRateDivisor = _taxManager.taxBaseDivisor();

        referralTax_ =
            (_paymentAmount * solverFees.referralRewards) /
            taxRateDivisor;

        platformTax_ =
            (_paymentAmount * solverFees.platformRevenue) /
            taxRateDivisor;

        platformTreasuryTax_ =
            (_paymentAmount * solverFees.platformTreasury) /
            taxRateDivisor;

        sharesTax_ = (_paymentAmount * solverFees.sharesTax) / taxRateDivisor;

        return (referralTax_, platformTax_, platformTreasuryTax_, sharesTax_);
    }

    function _calculateRationsTax(
        ITaxManager _taxManager,
        uint256 _price
    )
        internal
        view
        returns (
            uint256 leaderRewardsTax_,
            uint256 referralRewardsTax_,
            uint256 platformRevenueTax_,
            uint256 partyMemberRewardsTax
        )
    {
        ITaxManager.PartyFees memory partyFees = _taxManager.getPartyFees();
        uint256 taxRateDivisor = _taxManager.taxBaseDivisor();

        leaderRewardsTax_ = (_price * partyFees.leaderRewards) / taxRateDivisor;
        referralRewardsTax_ =
            (_price * partyFees.referralRewards) /
            taxRateDivisor;
        platformRevenueTax_ =
            (_price * partyFees.platformRevenue) /
            taxRateDivisor;
        partyMemberRewardsTax =
            (_price * partyFees.partyMemberRewards) /
            taxRateDivisor;

        return (
            leaderRewardsTax_,
            referralRewardsTax_,
            platformRevenueTax_,
            partyMemberRewardsTax
        );
    }
}
