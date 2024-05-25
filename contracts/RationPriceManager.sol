// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

contract RationPriceManager {
    uint256 public constant SCALING_FACTOR = 1e18;
    uint256 public constant segmentSize = 10;

    function calculatePrice(
        uint256 _supply,
        uint256 _amount
    ) external pure returns (uint256 _totalPrice) {
        for (uint256 i = 1; i < _amount + 1; i++) {
            _supply++;

            uint256 segment = (_supply - 1) / segmentSize + 1; // Calculate the segment based on supply
            if (segment == 1) {
                _totalPrice += ((_supply * SCALING_FACTOR * 10000) / 80000);
            } else if (segment == 2) {
                _totalPrice +=
                    (((_supply - 10) * SCALING_FACTOR * 10000) / 50000) +
                    ((10 * SCALING_FACTOR) / 8);
            } else if (segment == 3) {
                _totalPrice +=
                    (((_supply - 20) * SCALING_FACTOR * 10000) / 62500) +
                    ((10 * SCALING_FACTOR) / 5) +
                    ((10 * SCALING_FACTOR) / 8);
            } else if (segment == 4) {
                _totalPrice +=
                    (((_supply - 30) * SCALING_FACTOR * 10000) / 125000) +
                    ((10 * SCALING_FACTOR * 10000) / 62500) +
                    ((10 * SCALING_FACTOR) / 5) +
                    ((10 * SCALING_FACTOR) / 8);
            } else if (segment == 5) {
                _totalPrice +=
                    (((_supply - 40) * SCALING_FACTOR) / 50) +
                    ((10 * SCALING_FACTOR * 10000) / 125000) +
                    ((10 * SCALING_FACTOR * 10000) / 62500) +
                    ((10 * SCALING_FACTOR) / 5) +
                    ((10 * SCALING_FACTOR) / 8);
            } else {
                _totalPrice +=
                    (((_supply - 50) * SCALING_FACTOR) / 100) +
                    ((10 * SCALING_FACTOR) / 50) +
                    ((10 * SCALING_FACTOR * 10000) / 125000) +
                    ((10 * SCALING_FACTOR * 10000) / 62500) +
                    ((10 * SCALING_FACTOR) / 5) +
                    ((10 * SCALING_FACTOR) / 8);
            }
        }

        return _totalPrice;
    }
}
