//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface IQuest {
    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event QuestStarted(
        uint32 seekerId,
        uint32 solverId,
        address token,
        uint256 paymentAmount,
        address escrow
    );
    event DisputeStarted(uint32 seekerId, uint32 solverId);
    event DisputeResolved(uint32 seekerId, uint32 solverId, uint32 solverShare);
    event QuestFinished(uint32 seekerId, uint32 solverId);
    event QuestExtended(
        uint32 seekerId,
        uint32 solverId,
        uint256 extendedCount
    );
    event RewardReceived(
        uint32 seekerId,
        uint32 solverId,
        uint256 paymentAmount
    );

    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    function initialize(
        uint32 seekerId,
        uint32 solverId,
        uint256 paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        address token,
        address escrowImpl
    ) external;

    /*//////////////////////////////////////////////////////////////
                            only-seeker
    //////////////////////////////////////////////////////////////*/

    function startQuest() external payable;

    function startDispute() external payable;

    function extend() external;

    /*//////////////////////////////////////////////////////////////
                            only-mediator
    //////////////////////////////////////////////////////////////*/

    function resolveDispute(uint32 solverShare) external;

    /*//////////////////////////////////////////////////////////////
                            only-solver
    //////////////////////////////////////////////////////////////*/

    function finishQuest() external;

    function receiveReward() external;

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function getRewarder() external view returns (address);
}
