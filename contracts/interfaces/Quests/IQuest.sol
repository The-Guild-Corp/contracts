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
        address escrow,
        uint256 deadline,
        uint256 timestamp
    );

    event DisputeStarted(uint32 seekerId, uint32 solverId, uint256 timestamp);

    event DisputeResolved(
        uint32 seekerId,
        uint32 solverId,
        uint32 solverShare,
        uint256 timestamp
    );

    event QuestFinished(uint32 seekerId, uint32 solverId, uint256 timestamp);

    event QuestExtended(
        uint32 seekerId,
        uint32 solverId,
        uint256 extendedCount,
        uint256 timestamp
    );

    event RewardsReleased(uint32 seekerId, uint32 solverId, uint256 timestamp);

    event RewardReceived(
        uint32 seekerId,
        uint32 solverId,
        uint256 paymentAmount,
        uint256 timestamp
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
        uint256 _duration,
        address token,
        address escrowImpl
    ) external;

    /*//////////////////////////////////////////////////////////////
                            only-seeker
    //////////////////////////////////////////////////////////////*/

    function startQuest() external payable;

    function startDispute() external payable;

    function extend() external;

    function releaseRewards() external;

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

    function initialized() external view returns (bool);

    function started() external view returns (bool);

    function beingDisputed() external view returns (bool);

    function finished() external view returns (bool);

    function rewarded() external view returns (bool);

    function token() external view returns (address);

    function seekerId() external view returns (uint32);

    function solverId() external view returns (uint32);

    function paymentAmount() external view returns (uint256);

    function infoURI() external view returns (string memory);

    function maxExtensions() external view returns (uint256);

    function extendedCount() external view returns (uint256);

    function rewardTime() external view returns (uint256);

    function released() external view returns (bool);

    function deadline() external view returns (uint256);

    function reviewPeriod() external view returns (uint256);

    function extensionPeriod() external view returns (uint256);

    function duration() external view returns (uint256);

    function finishedTime() external view returns (uint256);
}
