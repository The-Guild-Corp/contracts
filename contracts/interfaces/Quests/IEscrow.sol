//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface IEscrow {
    function processPayment() external;

    function processStartDispute() external payable;
    function processResolution(
        uint32 solverShare 
    ) external;

    function initialize(
        address _token, 
        uint32 _seekerId, 
        uint32 _solverId, 
        uint256 _paymentAmount
    ) external payable;

}