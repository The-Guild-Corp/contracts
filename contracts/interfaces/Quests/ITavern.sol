//SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

interface ITavern {
    /*//////////////////////////////////////////////////////////////
                                Interface
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    // quests with payments in native token
    event QuestCreatedNative(
        uint32 seekerId,
        uint32 solverId,
        address quest,
        uint256 maxExtensions,
        uint256 paymentAmount
    );

    // quests with token payments
    event QuestCreatedToken(
        uint32 seekerId,
        uint32 solverId,
        address quest,
        uint256 maxExtensions,
        uint256 paymentAmount,
        address token
    );

    /*//////////////////////////////////////////////////////////////
                            read-functions
    //////////////////////////////////////////////////////////////*/

    function nexus() external view returns (address);

    function getRewarder() external view returns (address);

    function mediator() external view returns (address);

    function getBarkeeper() external view returns (address);

    function getProfileNFT() external view returns (address);

    function ownerOf(uint32) external view returns (address);

    function confirmNFTOwnership(address seeker) external view returns (bool);

    function reviewPeriod() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            write-functions
    //////////////////////////////////////////////////////////////*/

    function createNewQuest(
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        string memory _questId
    ) external payable;

    function createNewQuest(
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        address _token,
        string memory _questId
    ) external;

    function pauseAdmin() external;

    function unpauseAdmin() external;

    function setBarkeeper(address _barkeeper) external;

    function setNexus(address _nexus) external;

    function setMediator(address _mediator) external;

    function setReviewPeriod(uint256 _reviewPeriod) external;

    function setImplementation(
        address _implNative,
        address _implToken,
        address _implQuest
    ) external;

    function setWhitelistToken(address _whitelist, bool _status) external;
}
