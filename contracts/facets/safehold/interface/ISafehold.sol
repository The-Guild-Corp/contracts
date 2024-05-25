// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface ISafehold {
    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    function receiveFunds(uint256 _price) external payable;

    function retrieveFunds(uint256 _price) external;
}
