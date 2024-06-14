// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {IWarden} from "./interface/IWarden.sol";
import {WardenStorage} from "./storage/WardenStorage.sol";
import {LibOwnership} from "../ownership/LibOwnership.sol";
import {RationPriceManager} from "../../RationPriceManager.sol";
import {ISafehold} from "../safehold/interface/ISafehold.sol";
import {IRewarder} from "../../interfaces/IRewarder.sol";
import {ILoot} from "../loot/interface/ILoot.sol";
import {IFacet} from "../../interfaces/IFacet.sol";
import {LibPausable} from "../pauseable/LibPausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WardenFacet is IWarden, IFacet {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 WARDEN
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyParty() {
        require(
            msg.sender == WardenStorage.wardenStorage().party,
            "Warden: Only Nexus can call this function"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!LibPausable._paused(), "Warden: Contract is paused");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                Only-Party
    //////////////////////////////////////////////////////////////*/

    function purchaseRation(
        IWarden.RationPurchase memory purchase
    ) public payable onlyParty whenNotPaused {
        // Gets the total tax for the ration purchase
        uint256 totalTax = purchase.leaderRewardsTax +
            purchase.referralRewardsTax +
            purchase.platformRevenueTax +
            purchase.partyMemberRewardsTax;

        // Gets the total price for the ration purchase
        uint256 totalPrice = purchase.price + totalTax;

        address safehold = WardenStorage.wardenStorage().safeholds[
            purchase.leaderTokenId
        ];

        address lootDistributor = WardenStorage
            .wardenStorage()
            .lootDistributors[purchase.leaderTokenId];

        // Increase the safehold balance
        WardenStorage.wardenStorage().safeholdTokenBalances[
            safehold
        ] += purchase.price;

        // Get the total ration for a loot distributor
        uint256 currentMemberRations = WardenStorage
            .wardenStorage()
            .memberRationsAmount[
                WardenStorage.wardenStorage().lootDistributors[
                    purchase.leaderTokenId
                ]
            ][purchase.memberTokenId];

        // If the total ration is 0, then the member is a new member
        if (currentMemberRations == 0) {
            // Goes through the current loot distributer holders and checks if any members are not holding any rations, due to selling
            (bool update, uint256 updateIndex) = _checkLootRationCountIndex(
                lootDistributor
            );

            // If there is a member that is not holding any rations, then update the member with the new member token id
            if (update) {
                WardenStorage.wardenStorage().lootRationHolder[lootDistributor][
                        updateIndex
                    ] = purchase.memberTokenId;
            } else {
                // If there are no members that are not holding any rations, then add the new member token id to the list
                uint256 lootRationCount = WardenStorage
                    .wardenStorage()
                    .lootRationHoldersCount[lootDistributor];

                WardenStorage.wardenStorage().lootRationHolder[lootDistributor][
                        lootRationCount
                    ] = purchase.memberTokenId;

                WardenStorage.wardenStorage().lootRationHoldersCount[
                    lootDistributor
                ]++;
            }
        }

        // Increase the member rations amount
        WardenStorage.wardenStorage().memberRationsAmount[
            WardenStorage.wardenStorage().lootDistributors[
                purchase.leaderTokenId
            ]
        ][purchase.memberTokenId] += purchase.amount;

        // Increase the total rations for the loot distributor
        WardenStorage.wardenStorage().lootTotalRations[
            lootDistributor
        ] += purchase.amount;

        // Update the rewards for the leaders holders
        _updateTaxRewards(
            purchase.leaderTokenId,
            purchase.partyMemberRewardsTax
        );

        // Update native rewards for the holder
        _updateNativeReward(purchase.leaderTokenId, purchase.memberTokenId);

        // Update token rewards for the holder
        _updateTokenReward(purchase.leaderTokenId, purchase.memberTokenId);

        // Set the ration holder rewardsOffset to the current rewards
        WardenStorage.wardenStorage().lootRewardsOffset[lootDistributor][
                purchase.memberTokenId
            ] = WardenStorage.wardenStorage().lootRewards[lootDistributor];

        {
            require(msg.value == totalPrice, "Warden: Invalid payment amount");

            ISafehold(safehold).receiveFunds{value: purchase.price}(
                purchase.price
            );

            IRewarder(WardenStorage.wardenStorage().rewarder).handleRationsTax{
                value: totalTax
            }(
                purchase.leaderTokenId,
                purchase.leaderRewardsTax,
                purchase.referralRewardsTax,
                purchase.platformRevenueTax,
                purchase.partyMemberRewardsTax,
                lootDistributor
            );
        }
    }

    function sellRation(
        IWarden.RationSell memory sell
    ) external onlyParty whenNotPaused {
        uint256 totalTax = sell.leaderRewardsTax +
            sell.referralRewardsTax +
            sell.platformRevenueTax +
            sell.partyMemberRewardsTax;

        address safehold = WardenStorage.wardenStorage().safeholds[
            sell.leaderTokenId
        ];

        address lootDistributor = WardenStorage
            .wardenStorage()
            .lootDistributors[sell.leaderTokenId];

        WardenStorage.wardenStorage().safeholdTokenBalances[safehold] -= sell
            .price;

        // Update native rewards for the holder
        _updateNativeReward(sell.leaderTokenId, sell.memberTokenId);

        // Update token rewards for the holder
        _updateTokenReward(sell.leaderTokenId, sell.memberTokenId);

        WardenStorage.wardenStorage().memberRationsAmount[
            WardenStorage.wardenStorage().lootDistributors[sell.leaderTokenId]
        ][sell.memberTokenId] -= sell.amount;

        WardenStorage.wardenStorage().lootTotalRations[lootDistributor] -= sell
            .amount;

        _updateTaxRewards(sell.leaderTokenId, sell.partyMemberRewardsTax);

        // If there are no ration holders, send the reward to the lootRewards for the first user that buys the key again
        if (
            WardenStorage.wardenStorage().lootTotalRations[lootDistributor] == 0
        ) {
            WardenStorage.wardenStorage().lootRewards[lootDistributor] += sell
                .partyMemberRewardsTax;
        }

        // Set the ration holder rewardsOffset to the current rewards
        WardenStorage.wardenStorage().lootRewardsOffset[lootDistributor][
                sell.memberTokenId
            ] = WardenStorage.wardenStorage().lootRewards[lootDistributor];

        {
            uint256 balance = address(safehold).balance;

            ISafehold(safehold).retrieveFunds(sell.price);

            uint256 balanceAfter = address(safehold).balance;

            require(
                balance - balanceAfter == sell.price,
                "Warden: Invalid transfer"
            );

            IRewarder(WardenStorage.wardenStorage().rewarder).handleRationsTax{
                value: totalTax
            }(
                sell.leaderTokenId,
                sell.leaderRewardsTax,
                sell.referralRewardsTax,
                sell.platformRevenueTax,
                sell.partyMemberRewardsTax,
                lootDistributor
            );

            (bool success, ) = payable(sell.receiver).call{
                value: sell.price - totalTax
            }("");
            require(success, "Native token transfer error");
        }
    }

    function claimLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _memberOwner
    ) public onlyParty whenNotPaused returns (uint256) {
        uint256 pendingLoot = calculatePartyLoot(
            _partyLeaderTokenId,
            _partyMemberTokenId,
            getTotalRations(_partyLeaderTokenId),
            getMemberRations(_partyLeaderTokenId, _partyMemberTokenId),
            address(0)
        );

        // Reduce rewards from the lootMemberRewards since it has all been claimed
        WardenStorage.wardenStorage().lootMemberRewards[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ][_partyMemberTokenId] = 0;

        // Add to offset since reward has been claimed
        WardenStorage.wardenStorage().lootRewardsOffset[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ][_partyMemberTokenId] = WardenStorage.wardenStorage().lootRewards[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ];

        if (pendingLoot > 0) {
            _lootTransfer(
                _partyLeaderTokenId,
                pendingLoot,
                _memberOwner,
                address(0)
            );

            return pendingLoot;
        }

        return 0;
    }

    function claimLootToken(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _token,
        address _memberHandler
    ) public onlyParty whenNotPaused returns (uint256) {
        uint256 pendingLoot = calculatePartyLoot(
            _partyLeaderTokenId,
            _partyMemberTokenId,
            getTotalRations(_partyLeaderTokenId),
            getMemberRations(_partyLeaderTokenId, _partyMemberTokenId),
            _token
        );

        // Reduce rewards from the lootMemberTokenRewards since it has all been claimed
        WardenStorage.wardenStorage().lootMemberTokenRewards[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ][_token][_partyMemberTokenId] = 0;

        // Add to offset since reward has been claimed
        WardenStorage.wardenStorage().lootTokenRewardsOffset[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ][_token][_partyMemberTokenId] = WardenStorage
            .wardenStorage()
            .lootTokenRewards[
                WardenStorage.wardenStorage().lootDistributors[
                    _partyLeaderTokenId
                ]
            ][_token];

        if (pendingLoot > 0) {
            _lootTransfer(
                _partyLeaderTokenId,
                pendingLoot,
                _memberHandler,
                _token
            );

            return pendingLoot;
        }

        return 0;
    }

    function notifyReward(
        uint32 _tokenId,
        uint256 _amount
    ) external override onlyParty {
        // Increase reward amount from other sources thats not from tax
        WardenStorage.wardenStorage().lootRewards[
            WardenStorage.wardenStorage().lootDistributors[_tokenId]
        ] += _amount;
    }

    function notifyRewardToken(
        uint32 _tokenId,
        address _token,
        uint256 _amount
    ) external override onlyParty {
        // Check if token exists
        bool tokenExists = WardenStorage.wardenStorage().tokenExistence[_token];

        if (!tokenExists) {
            WardenStorage.wardenStorage().lootToken[
                WardenStorage.wardenStorage().lootTokenCount
            ] = _token;
            WardenStorage.wardenStorage().tokenExistence[_token] = true;
            WardenStorage.wardenStorage().lootTokenCount++;
        }

        // Increase reward amount
        WardenStorage.wardenStorage().lootTokenRewards[
            WardenStorage.wardenStorage().lootDistributors[_tokenId]
        ][_token] += _amount;
    }

    /*//////////////////////////////////////////////////////////////
                                Read-Only
    //////////////////////////////////////////////////////////////*/

    function getRationPrice(
        uint256 _supply,
        uint256 _amount
    ) external view override returns (uint256) {
        return
            RationPriceManager(WardenStorage.wardenStorage().rationPriceManager)
                .calculatePrice(_supply, _amount);
    }

    function getParty() external view override returns (address) {
        return WardenStorage.wardenStorage().party;
    }

    function getChief() external view override returns (address) {
        return WardenStorage.wardenStorage().chief;
    }

    function getRewarder() external view override returns (address) {
        return WardenStorage.wardenStorage().rewarder;
    }

    function getRationPriceManager() external view override returns (address) {
        return WardenStorage.wardenStorage().rationPriceManager;
    }

    function getDiamondCutImplementation()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondCutImplementation;
    }

    function getDiamondSafeholdFacet()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondSafeholdFacet;
    }

    function getDiamondLootFacet() external view override returns (address) {
        return WardenStorage.wardenStorage().diamondLootFacet;
    }

    function getDiamondOwnershipFacet()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondOwnershipFacet;
    }

    function getDiamondPausableFacet()
        external
        view
        override
        returns (address)
    {
        return WardenStorage.wardenStorage().diamondPausableFacet;
    }

    function getDiamondLoupeFacet() external view override returns (address) {
        return WardenStorage.wardenStorage().diamondLoupeFacet;
    }

    function getMemberRations(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) public view override returns (uint256) {
        return
            WardenStorage.wardenStorage().memberRationsAmount[
                WardenStorage.wardenStorage().lootDistributors[
                    _partyLeaderTokenId
                ]
            ][_partyMemberTokenId];
    }

    function getTotalRations(
        uint32 _tokenId
    ) public view override returns (uint256) {
        return
            WardenStorage.wardenStorage().lootTotalRations[
                WardenStorage.wardenStorage().lootDistributors[_tokenId]
            ];
    }

    function getLootEligible(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId
    ) external view override returns (uint256 pendingLoot_) {
        uint256 totalRations = WardenStorage.wardenStorage().lootTotalRations[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ];

        uint256 memberRations = WardenStorage
            .wardenStorage()
            .memberRationsAmount[
                WardenStorage.wardenStorage().lootDistributors[
                    _partyLeaderTokenId
                ]
            ][_partyMemberTokenId];

        return
            pendingLoot_ = calculatePartyLoot(
                _partyLeaderTokenId,
                _partyMemberTokenId,
                totalRations,
                memberRations,
                address(0)
            );
    }

    function getLootEligibleToken(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        address _token
    ) external view override returns (uint256 pendingLoot_) {
        uint256 totalRations = WardenStorage.wardenStorage().lootTotalRations[
            WardenStorage.wardenStorage().lootDistributors[_partyLeaderTokenId]
        ];

        uint256 memberRations = WardenStorage
            .wardenStorage()
            .memberRationsAmount[
                WardenStorage.wardenStorage().lootDistributors[
                    _partyLeaderTokenId
                ]
            ][_partyMemberTokenId];

        return
            pendingLoot_ = calculatePartyLoot(
                _partyLeaderTokenId,
                _partyMemberTokenId,
                totalRations,
                memberRations,
                _token
            );
    }

    /*//////////////////////////////////////////////////////////////
                                Internal
    //////////////////////////////////////////////////////////////*/

    // Update token reward for holder
    function _updateTokenReward(
        uint32 _leaderTokenId,
        uint32 _memberTokenId
    ) internal {
        uint256 lootTokenCount = WardenStorage.wardenStorage().lootTokenCount;

        // Get the total rations for the loot distributor
        uint256 lootTotalRations = WardenStorage
            .wardenStorage()
            .lootTotalRations[
                WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
            ];

        uint256 memberRations = WardenStorage
            .wardenStorage()
            .memberRationsAmount[
                WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
            ][_memberTokenId];

        // Go through all registered tokens and update the rewards for the member
        for (uint256 i = 0; i < lootTokenCount; i++) {
            address token = WardenStorage.wardenStorage().lootToken[i];

            uint256 tokenReward = WardenStorage
                .wardenStorage()
                .lootTokenRewards[
                    WardenStorage.wardenStorage().lootDistributors[
                        _leaderTokenId
                    ]
                ][token];

            uint256 tokenOffset = WardenStorage
                .wardenStorage()
                .lootTokenRewardsOffset[
                    WardenStorage.wardenStorage().lootDistributors[
                        _leaderTokenId
                    ]
                ][token][_memberTokenId];

            // If the token reward is 0, then continue to the next token
            if (tokenReward == 0) {
                continue;
            }

            if (tokenOffset > 0) {
                // Get the new token rewards
                uint256 newTokenRewards = tokenReward - tokenOffset;

                // Gets the user share of the new token rewards
                uint256 rewardShare = (newTokenRewards * memberRations) /
                    lootTotalRations;

                // Increase the rewards for the member
                WardenStorage.wardenStorage().lootMemberTokenRewards[
                    WardenStorage.wardenStorage().lootDistributors[
                        _leaderTokenId
                    ]
                ][token][_memberTokenId] += rewardShare;

                // Increase the rewardsOffset for the member
                WardenStorage.wardenStorage().lootTokenRewardsOffset[
                    WardenStorage.wardenStorage().lootDistributors[
                        _leaderTokenId
                    ]
                ][token][_memberTokenId] = tokenReward;

                // Decrease the amount of the token rewards by the share
                WardenStorage.wardenStorage().lootTokenRewards[
                    WardenStorage.wardenStorage().lootDistributors[
                        _leaderTokenId
                    ]
                ][token] -= rewardShare;
            } else {
                WardenStorage.wardenStorage().lootTokenRewardsOffset[
                    WardenStorage.wardenStorage().lootDistributors[
                        _leaderTokenId
                    ]
                ][token][_memberTokenId] = tokenReward;
            }
        }
    }

    // Update native reward for holder
    function _updateNativeReward(
        uint32 _leaderTokenId,
        uint32 _memberTokenId
    ) internal {
        // Get the total rations for the loot distributor
        uint256 lootTotalRations = WardenStorage
            .wardenStorage()
            .lootTotalRations[
                WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
            ];

        uint256 memberRations = WardenStorage
            .wardenStorage()
            .memberRationsAmount[
                WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
            ][_memberTokenId];

        // Get the total rewards
        uint256 rewards = WardenStorage.wardenStorage().lootRewards[
            WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
        ];

        // Get the rewards offset for the member
        uint256 rewardsOffset = WardenStorage.wardenStorage().lootRewardsOffset[
            WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
        ][_memberTokenId];

        // If the rewards offset is higher than the actual rewards, then return
        if (rewardsOffset > rewards) {
            return;
        }

        // Get the unseen rewards derived from other sources thats not from taxes
        uint256 unseenRewards = rewards - rewardsOffset;

        // Determines share of unseen rewards
        uint256 userRewards = (unseenRewards * memberRations) /
            lootTotalRations;

        // Increase the rewards for the member
        WardenStorage.wardenStorage().lootMemberRewards[
            WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
        ][_memberTokenId] += userRewards;

        // Decrease the rewards for the loot distributor
        WardenStorage.wardenStorage().lootRewards[
            WardenStorage.wardenStorage().lootDistributors[_leaderTokenId]
        ] -= userRewards;
    }

    // Updates the rewards for the leaders holders, with an amount
    function _updateTaxRewards(
        uint32 _partyLeaderTokenId,
        uint256 _rewards
    ) internal {
        // Get the total rations holders for the loot distributor
        uint256 lootRationHolderCount = WardenStorage
            .wardenStorage()
            .lootRationHoldersCount[
                WardenStorage.wardenStorage().lootDistributors[
                    _partyLeaderTokenId
                ]
            ];

        // Get the total rations for the loot distributor
        uint256 lootTotalRations = WardenStorage
            .wardenStorage()
            .lootTotalRations[
                WardenStorage.wardenStorage().lootDistributors[
                    _partyLeaderTokenId
                ]
            ];

        // Loop through all current holders and update their rewards
        for (uint256 i = 0; i < lootRationHolderCount; i++) {
            // Gets indexed member token id
            uint32 memberTokenId = WardenStorage
                .wardenStorage()
                .lootRationHolder[
                    WardenStorage.wardenStorage().lootDistributors[
                        _partyLeaderTokenId
                    ]
                ][i];

            // Gets the rations amount for the member
            uint256 rationsAmount = WardenStorage
                .wardenStorage()
                .memberRationsAmount[
                    WardenStorage.wardenStorage().lootDistributors[
                        _partyLeaderTokenId
                    ]
                ][memberTokenId];

            // If the member has rations, then calculate the rewards for the member
            if (rationsAmount > 0) {
                uint256 reward = (_rewards * rationsAmount) / lootTotalRations;

                // Increase the rewards for the member
                WardenStorage.wardenStorage().lootMemberRewards[
                    WardenStorage.wardenStorage().lootDistributors[
                        _partyLeaderTokenId
                    ]
                ][memberTokenId] += reward;
            }
        }
    }

    function calculatePartyLoot(
        uint32 _partyLeaderTokenId,
        uint32 _partyMemberTokenId,
        uint256 _totalRations,
        uint256 _memberRations,
        address _token
    ) internal view returns (uint256) {
        address lootDistributor = WardenStorage
            .wardenStorage()
            .lootDistributors[_partyLeaderTokenId];

        if (_token == address(0)) {
            uint256 pendingRewards = WardenStorage
                .wardenStorage()
                .lootMemberRewards[lootDistributor][_partyMemberTokenId];

            if (_memberRations == 0) {
                return pendingRewards;
            }

            if (_totalRations == 0) {
                return pendingRewards;
            }

            uint256 lootRewards = WardenStorage.wardenStorage().lootRewards[
                lootDistributor
            ];

            uint256 rewardsOffset = WardenStorage
                .wardenStorage()
                .lootRewardsOffset[lootDistributor][_partyMemberTokenId];

            if (rewardsOffset > lootRewards) {
                return pendingRewards;
            }

            // unseen rewards derived from other sources thats not from taxes
            uint256 unseenRewards = lootRewards - rewardsOffset;

            // Determines share of unseen rewards
            uint256 userRewards = (unseenRewards * _memberRations) /
                _totalRations;

            return pendingRewards + userRewards;
        } else {
            uint256 tokenRewards = WardenStorage
                .wardenStorage()
                .lootMemberTokenRewards[lootDistributor][_token][
                    _partyMemberTokenId
                ];

            if (_memberRations == 0) {
                return tokenRewards;
            }

            if (_totalRations == 0) {
                return tokenRewards;
            }

            uint256 lootTokenReward = WardenStorage
                .wardenStorage()
                .lootTokenRewards[lootDistributor][_token];

            uint256 tokenOffset = WardenStorage
                .wardenStorage()
                .lootTokenRewardsOffset[lootDistributor][_token][
                    _partyMemberTokenId
                ];

            if (tokenOffset > lootTokenReward) {
                return tokenRewards;
            }

            uint256 unseenTokenRewards = lootTokenReward - tokenOffset;

            uint256 userTokenRewards = (unseenTokenRewards * _memberRations) /
                _totalRations;

            return tokenRewards + userTokenRewards;
        }
    }

    function _checkLootRationCountIndex(
        address _lootDistributor
    ) internal view returns (bool, uint256) {
        uint256 lootRationCount = WardenStorage
            .wardenStorage()
            .lootRationHoldersCount[_lootDistributor];

        if (lootRationCount != 0) {
            // Checks the mapping for ration holders and get the index that has 0 holdings, so it can be overwritten
            // We do this so that we don't have to keep track of holders with 0 holdings when updating
            for (uint256 i = 0; i < lootRationCount; i++) {
                uint32 memberTokenId = WardenStorage
                    .wardenStorage()
                    .lootRationHolder[_lootDistributor][i];

                if (
                    WardenStorage.wardenStorage().memberRationsAmount[
                        _lootDistributor
                    ][memberTokenId] == 0
                ) {
                    return (true, i);
                }
            }
        }

        return (false, 0);
    }

    function _lootTransfer(
        uint32 _partyLeaderTokenId,
        uint256 _amount,
        address _memberOwner,
        address _token
    ) internal {
        address loot = WardenStorage.wardenStorage().lootDistributors[
            _partyLeaderTokenId
        ];

        if (_token == address(0)) {
            uint256 balance = address(this).balance;

            ILoot(loot).lootTransfer(_amount);

            uint256 balanceAfter = address(this).balance;

            require(
                balanceAfter - balance >= _amount,
                "Warden: Invalid transfer"
            );

            (bool success, ) = payable(_memberOwner).call{value: _amount}("");
            require(success, "Native token transfer error");
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));

            ILoot(loot).lootTransferToken(_token, _amount);

            uint256 balanceAfter = IERC20(_token).balanceOf(address(this));

            require(
                balanceAfter - balance >= _amount,
                "Warden: Invalid transfer"
            );

            IERC20(_token).transfer(_memberOwner, _amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            IFacet
    //////////////////////////////////////////////////////////////*/

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](22);
        s[0] = IWarden.purchaseRation.selector;
        s[1] = IWarden.sellRation.selector;
        s[2] = IWarden.claimLoot.selector;
        s[3] = IWarden.notifyReward.selector;
        s[4] = IWarden.getRationPrice.selector;
        s[5] = IWarden.getParty.selector;
        s[6] = IWarden.getChief.selector;
        s[7] = IWarden.getRewarder.selector;
        s[8] = IWarden.getRationPriceManager.selector;
        s[9] = IWarden.getDiamondCutImplementation.selector;
        s[10] = IWarden.getDiamondSafeholdFacet.selector;
        s[11] = IWarden.getDiamondLootFacet.selector;
        s[12] = IWarden.getDiamondOwnershipFacet.selector;
        s[13] = IWarden.getDiamondPausableFacet.selector;
        s[14] = IWarden.getDiamondLoupeFacet.selector;
        s[15] = IFacet.pluginMetadata.selector;
        s[16] = IWarden.getLootEligible.selector;
        s[17] = IWarden.getLootEligibleToken.selector;
        s[18] = IWarden.getMemberRations.selector;
        s[19] = IWarden.getTotalRations.selector;
        s[20] = IWarden.notifyRewardToken.selector;
        s[21] = IWarden.claimLootToken.selector;
    }

    function pluginMetadata()
        external
        pure
        override
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IWarden).interfaceId;
    }
}
