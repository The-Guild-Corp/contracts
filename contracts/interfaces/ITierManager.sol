// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface ITierManager {
    function checkTierUpgrade(
        uint32[5] memory tierCounts,
        address account,
        uint8 tier
    ) external returns (bool);

    function getRationLimit(uint8 tier) external view returns (uint256);
}
