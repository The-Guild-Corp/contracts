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

    function extensionPeriod() external view returns (uint256);

    function deadlineMultiplier() external view returns (uint256);

    function questIdToAddress(
        string memory _questId
    ) external view returns (address);

    function escrowNativeImplementation() external view returns (address);

    function escrowTokenImplementation() external view returns (address);

    function questImplementation() external view returns (address);

    function isTokenWhitelisted(address _token) external view returns (bool);

    function isExtendEnabled() external view returns (bool);

    function isDisputeEnabled() external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                            write-functions
    //////////////////////////////////////////////////////////////*/

    function createNewQuest(
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        uint256 _days,
        string memory _questId
    ) external payable;

    function createNewQuest(
        uint32 _seekerId,
        uint32 _solverId,
        uint256 _paymentAmount,
        string memory infoURI,
        uint256 _maxExtensions,
        uint256 _days,
        address _token,
        string memory _questId
    ) external;

    function pauseAdmin() external;

    function unpauseAdmin() external;

    function setBarkeeper(address _barkeeper) external;

    function setNexus(address _nexus) external;

    function setMediator(address _mediator) external;

    function setReviewPeriod(uint256 _reviewPeriod) external;

    function setExtensionPeriod(uint256 _extensionPeriod) external;

    function setDeadlineMultiplier(uint256 _multiplier) external;

    function setImplementation(
        address _implNative,
        address _implToken,
        address _implQuest
    ) external;

    function setWhitelistToken(address _whitelist, bool _status) external;

    function setExtendEnabled(bool _status) external;

    function setDisputeEnabled(bool _status) external;
}
