// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MockExecuteEth {
    
    event ChangedValue(bytes32 _newValue, bool _success );

    bytes32 public value;

    constructor() {
        value = "0x";
    }

    receive() external payable {}

    function changeValue(bytes32 _newValue) external returns (bool) {
        value = _newValue;

        emit ChangedValue(_newValue, true);

        return true;
    }
}