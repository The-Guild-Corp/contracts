import {
    loadFixture,
    takeSnapshot,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractTransactionReceipt, Signer } from "ethers";
import {
    GuildXp,
    ProfileNFT,
    RationPriceManager,
    Rewarder,
    TaxManager,
    TierManager,
} from "../typechain-types";
import { diamond_integration_fixture } from "./helpers/diamondFixtures";
import { CommonFacets, Facets } from "./helpers/diamondSetup";
import { parseEventLogs } from "./helpers/utils";

describe("Account", function () {
    async function mockAccounts(): Promise<Signer[]> {
        const [
            owner,
            user1,
            user2,
            user3,
            user4,
            user5,
            user6,
            user7,
            user8,
            user9,
            user10,
        ] = await ethers.getSigners();

        return [
            owner,
            user1,
            user2,
            user3,
            user4,
            user5,
            user6,
            user7,
            user8,
            user9,
            user10,
        ];
    }

    async function fixture_integration_tests() {
        const accounts = await mockAccounts();
        return await diamond_integration_fixture(accounts[0]);
    }

    describe("Account Test", function () {
        let accounts_: Signer[],
            commonFacets: CommonFacets,
            facets: Facets,
            nexusDiamond: string,
            rewarder: Rewarder,
            profileNFT: ProfileNFT,
            tavernDiamond: string,
            xpToken: GuildXp,
            taxManager: TaxManager,
            tierManager: TierManager,
            partyDiamond: string,
            wardenDiamond: string,
            rationPriceManager: RationPriceManager;

        let snapshot: any; // snapshot.restore(); to restore state during snapshot

        it("All of the contracts should be deployed successfully", async function () {
            const accounts = await mockAccounts();
            const { contracts } = await loadFixture(fixture_integration_tests);

            accounts_ = accounts;

            commonFacets = contracts.commonFacets;
            facets = contracts.facets;
            nexusDiamond = contracts.nexus.target as string;
            rewarder = contracts.rewarder;
            profileNFT = contracts.profileNFT;
            tavernDiamond = contracts.tavern.target as string;
            xpToken = contracts.xpToken;
            taxManager = contracts.taxManager;
            tierManager = contracts.tierManager;
            partyDiamond = contracts.party.target as string;
            wardenDiamond = contracts.warden.target as string;
            rationPriceManager = contracts.rationPriceManager;

            snapshot = await takeSnapshot();
        });

        it("Contract values should be initiated properly", async function () {
            // Rewarder
            expect(
                ethers.getAddress(
                    ethers.stripZerosLeft(
                        await ethers.provider.getStorage(rewarder.target, 2)
                    )
                )
            ).to.not.equal(ethers.ZeroAddress);

            expect(
                ethers.getAddress(
                    ethers.stripZerosLeft(
                        await ethers.provider.getStorage(rewarder.target, 3)
                    )
                )
            ).to.equal(nexusDiamond);

            expect(
                ethers.getAddress(
                    ethers.stripZerosLeft(
                        await ethers.provider.getStorage(rewarder.target, 4)
                    )
                )
            ).to.equal(partyDiamond);

            // ProfileNFT
            // expect(
            //     await ethers.provider.getStorage(profileNFT.target, 1)
            // ).to.equal(ethers.ZeroHash);

            expect(await profileNFT.counselor()).to.equal(
                await accounts_[0].getAddress()
            );

            expect(await profileNFT.nexus()).to.equal(nexusDiamond);

            // GuildXp
            expect(await xpToken.owner()).to.equal(
                await accounts_[0].getAddress()
            );

            // TaxManager
            expect(await taxManager.custodian()).to.equal(
                await accounts_[0].getAddress()
            );
            expect(await taxManager.getSeekerFees()).to.deep.equal([
                100n,
                100n,
                100n,
            ]);
            expect(await taxManager.getSolverFees()).to.deep.equal([
                200n,
                500n,
                100n,
                200n,
            ]);
            expect(await taxManager.getPartyFees()).to.deep.equal([
                500n,
                100n,
                300n,
                100n,
            ]);
            expect(await taxManager.disputeDepositRate()).to.equal(1000n);
            expect(await taxManager.referralRewardsTax()).to.equal(3000n);
            expect(await taxManager.getReferralRewardsRevenue()).to.equal(
                5000n
            );
            expect(await taxManager.platformTreasury()).to.equal(
                "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
            );
            expect(await taxManager.platformRevenuePool()).to.equal(
                "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
            );
            expect(await taxManager.referralTaxTreasury()).to.equal(
                "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
            );
            expect(await taxManager.disputeFeesTreasury()).to.equal(
                "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
            );
            expect(await taxManager.participationRewardPool()).to.equal(
                "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
            );

            // Tier Manager
            expect(await tierManager.magistrate()).to.equal(
                await accounts_[0].getAddress()
            );
            expect(await tierManager.xpToken()).to.equal(xpToken.target);
            expect(await tierManager.tierUpConditions(1)).to.deep.equal([
                300n,
                0n,
                0n,
                0n,
                0n,
                0n,
            ]);
            expect(await tierManager.tierUpConditions(2)).to.deep.equal([
                447000n,
                3n,
                0n,
                0n,
                0n,
                0n,
            ]);
            expect(await tierManager.tierUpConditions(3)).to.deep.equal([
                3722400n,
                5n,
                1n,
                0n,
                0n,
                0n,
            ]);
            expect(await tierManager.tierUpConditions(4)).to.deep.equal([
                73762700n,
                5n,
                2n,
                1n,
                0n,
                0n,
            ]);
            expect(await tierManager.tierUpConditions(5)).to.deep.equal([
                534633200n,
                5n,
                2n,
                1n,
                1n,
                0n,
            ]);

            // Nexus
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            expect(await nexusInstance.getGuardian()).to.equal(
                await accounts_[0].getAddress()
            );

            expect(await nexusInstance.getTierManager()).to.equal(
                tierManager.target
            );

            expect(await nexusInstance.getTaxManager()).to.equal(
                taxManager.target
            );

            expect(await nexusInstance.getNFT()).to.equal(profileNFT.target);

            expect(await nexusInstance.getParty()).to.equal(partyDiamond);

            expect(await nexusInstance.getRewarder()).to.equal(rewarder.target);

            expect(await nexusInstance.getDiamondCutImplementation()).to.equal(
                commonFacets.cutFacet.target
            );

            expect(
                await nexusInstance.getDiamondAccountImplementation()
            ).to.equal(facets.account.target);

            expect(
                await nexusInstance.getDiamondOwnershipImplementation()
            ).to.equal(commonFacets.ownership.target);

            expect(
                await nexusInstance.getDiamondLoupeImplementation()
            ).to.equal(commonFacets.loupeFacet.target);

            const nexusOwnerInstance = await ethers.getContractAt(
                "OwnershipFacet",
                nexusDiamond
            );

            expect(await nexusOwnerInstance.owner()).to.equal(
                await accounts_[0].getAddress()
            );

            // Tavern
            const tavernInstance = await ethers.getContractAt(
                "TavernFacet",
                tavernDiamond
            );

            expect(await tavernInstance.nexus()).to.equal(nexusDiamond);

            expect(await tavernInstance.getRewarder()).to.equal(
                rewarder.target
            );

            expect(await tavernInstance.mediator()).to.equal(
                await accounts_[0].getAddress()
            );

            expect(await tavernInstance.getBarkeeper()).to.equal(
                await accounts_[0].getAddress()
            );

            expect(await tavernInstance.getProfileNFT()).to.equal(
                profileNFT.target
            );

            const tavernOwnerInstance = await ethers.getContractAt(
                "OwnershipFacet",
                tavernDiamond
            );

            expect(await tavernOwnerInstance.owner()).to.equal(
                await accounts_[0].getAddress()
            );

            // Party

            const partyInstance = await ethers.getContractAt(
                "PartyFacet",
                partyDiamond
            );

            expect(await partyInstance.getWarden()).to.equal(wardenDiamond);

            expect(await partyInstance.getNexus()).to.equal(nexusDiamond);

            const partyOwnerInstance = await ethers.getContractAt(
                "OwnershipFacet",
                partyDiamond
            );

            expect(await partyOwnerInstance.owner()).to.equal(
                await accounts_[0].getAddress()
            );

            // Warden
            const wardenInstance = await ethers.getContractAt(
                "WardenFacet",
                wardenDiamond
            );

            expect(await wardenInstance.getParty()).to.equal(partyDiamond);

            expect(await wardenInstance.getChief()).to.equal(
                await accounts_[0].getAddress()
            );

            expect(await wardenInstance.getRewarder()).to.equal(
                rewarder.target
            );

            expect(await wardenInstance.getRationPriceManager()).to.equal(
                rationPriceManager.target
            );

            expect(await wardenInstance.getDiamondCutImplementation()).to.equal(
                commonFacets.cutFacet.target
            );

            expect(await wardenInstance.getDiamondSafeholdFacet()).to.equal(
                facets.safehold.target
            );

            expect(await wardenInstance.getDiamondLootFacet()).to.equal(
                facets.loot.target
            );

            expect(await wardenInstance.getDiamondOwnershipFacet()).to.equal(
                commonFacets.ownership.target
            );

            expect(await wardenInstance.getDiamondPausableFacet()).to.equal(
                commonFacets.pausable.target
            );

            expect(await wardenInstance.getDiamondLoupeFacet()).to.equal(
                commonFacets.loupeFacet.target
            );

            const wardenOwnerInstance = await ethers.getContractAt(
                "OwnershipFacet",
                wardenDiamond
            );

            expect(await wardenOwnerInstance.owner()).to.equal(
                await accounts_[0].getAddress()
            );
        });

        it("Only owner should be able to trigger only owner functions on nexus", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setGuardian(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setTierManager(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setTaxManager(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setNFT(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setParty(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setRewarder(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setDiamondCutImplementation(
                        await accounts_[1].getAddress()
                    )
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setDiamondAccountImplementation(
                        await accounts_[1].getAddress()
                    )
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .setDiamondOwnershipImplementation(
                        await accounts_[1].getAddress()
                    )
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .addHandler(await accounts_[1].getAddress())
            ).to.be.revertedWith("Only owner");

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .recoverTokens(
                        await accounts_[1].getAddress(),
                        await accounts_[1].getAddress()
                    )
            ).to.be.revertedWith("Only owner");
        });

        it("Only guardian should be able to trigger only guardian functions on nexus", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            await expect(
                nexusInstance
                    .connect(accounts_[1])
                    .mintNFT(
                        1,
                        await accounts_[1].getAddress(),
                        "Test link",
                        "123"
                    )
            ).to.be.revertedWith("only guardian");

            await expect(
                nexusInstance.connect(accounts_[1]).createProfile("123")
            ).to.be.revertedWith("only guardian");

            await expect(
                nexusInstance.connect(accounts_[1]).initializeHandler("123")
            ).to.be.revertedWith("only guardian");

            await expect(
                nexusInstance.connect(accounts_[1]).createParty("123")
            ).to.be.revertedWith("only guardian");
        });

        it("Pause and unpause should work properly", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            await expect(
                nexusInstance.connect(accounts_[1]).guardianPause()
            ).to.be.revertedWith("only guardian");

            await nexusInstance.guardianPause();

            await expect(
                nexusInstance.mintNFT(
                    1,
                    await accounts_[1].getAddress(),
                    "Test link",
                    "123"
                )
            ).to.be.revertedWith("Contract is paused");

            await expect(nexusInstance.createProfile("123")).to.be.revertedWith(
                "Contract is paused"
            );

            await expect(
                nexusInstance.initializeHandler("123")
            ).to.be.revertedWith("Contract is paused");

            await expect(nexusInstance.createParty("123")).to.be.revertedWith(
                "Contract is paused"
            );

            await expect(
                nexusInstance.connect(accounts_[1]).guardianUnpause()
            ).to.be.revertedWith("only guardian");

            await nexusInstance.guardianUnpause();
        });

        type Profile = {
            id: number;
            handler: string;
            owner: Signer;
        };

        let profiles: Profile[] = [];

        it("Create profile flow should work properly", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            // Should not be able to create profile without minting NFT
            await expect(nexusInstance.createProfile("123")).to.be.revertedWith(
                "Nexus:nft"
            );

            // Should not be able to initializeHandler without minting NFT
            await expect(
                nexusInstance.initializeHandler("123")
            ).to.be.revertedWith("Nexus:not minted");

            // Should not be able to create party without minting NFT
            await expect(nexusInstance.createParty("123")).to.be.revertedWith(
                "Nexus:minted"
            );

            // Mint NFT
            await nexusInstance.mintNFT(
                0,
                await accounts_[1].getAddress(),
                "Test link",
                "123"
            );

            // Account 1 should have 1 NFT
            const nftCount = await profileNFT.balanceOf(
                await accounts_[1].getAddress()
            );
            expect(nftCount).to.equal(1);

            // Should not be able to initialize handler before creating a profile
            await expect(
                nexusInstance.initializeHandler("123")
            ).to.be.revertedWith("Nexus:handler created");

            // Should not be able to create party before creating a profile
            await expect(nexusInstance.createParty("123")).to.be.revertedWith(
                "Nexus:handler"
            );

            // Create profile
            await nexusInstance.createProfile("123");

            // Should not be able to create profile again
            await expect(nexusInstance.createProfile("123")).to.be.revertedWith(
                "Nexus:handler"
            );

            // Should be able to get handler address
            const handler = await nexusInstance.getHandler(1);
            expect(handler).to.not.equal(ethers.ZeroAddress);

            // Should not be able to create party without initializing handler
            await expect(nexusInstance.createParty("123")).to.be.revertedWith(
                "Nexus:initialized"
            );

            // Initialize handler
            await nexusInstance.initializeHandler("123");

            // Should not be able to initialize handler again
            await expect(
                nexusInstance.initializeHandler("123")
            ).to.be.revertedWith("Nexus:initialized");

            // Should be able to create party
            await nexusInstance.createParty("123");

            // Should be able to call create party again, because party hasn't been enabled
            await nexusInstance.createParty("123");

            profiles.push({
                id: 1,
                handler,
                owner: accounts_[1],
            });

            // Create more profiles
            await nexusInstance.mintNFT(
                1,
                await accounts_[2].getAddress(),
                "Test12345",
                "234"
            );

            await nexusInstance.createProfile("234");

            await nexusInstance.initializeHandler("234");

            await nexusInstance.createParty("234");

            profiles.push({
                id: 2,
                handler: await nexusInstance.getHandler(2),
                owner: accounts_[2],
            });

            await nexusInstance.mintNFT(
                2,
                await accounts_[3].getAddress(),
                "Test123456",
                "345"
            );

            await nexusInstance.createProfile("345");

            await nexusInstance.initializeHandler("345");

            await nexusInstance.createParty("345");

            profiles.push({
                id: 3,
                handler: await nexusInstance.getHandler(3),
                owner: accounts_[3],
            });

            await nexusInstance.mintNFT(
                3,
                await accounts_[4].getAddress(),
                "Test1234567",
                "456"
            );

            await nexusInstance.createProfile("456");

            await nexusInstance.initializeHandler("456");

            await nexusInstance.createParty("456");

            profiles.push({
                id: 4,
                handler: await nexusInstance.getHandler(4),
                owner: accounts_[4],
            });
        });

        it("Should support standard interfaces", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            // Account should support ERC165
            expect(await handlerInstance.supportsInterface("0x01ffc9a7")).to.be
                .true;

            // Account should also support IERC6551Account interface
            expect(await handlerInstance.supportsInterface("0x6faff5f1")).to.be
                .true;

            // Account should also support IERC6551Executable interface
            expect(await handlerInstance.supportsInterface("0x51945447")).to.be
                .true;

            // Account should support onErc721Received
            expect(
                await handlerInstance.onERC721Received(
                    ethers.ZeroAddress,
                    ethers.ZeroAddress,
                    0,
                    "0x"
                )
            ).to.be.equal("0x150b7a02");

            // Account should not support random interface
            expect(await handlerInstance.supportsInterface("0x12345678")).to.be
                .false;
        });

        it("Should be able to get correct token details from an account handler", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const token = await handlerInstance.token();
            expect(token).to.deep.equal(["31337", profileNFT.target, "1"]);
        });

        it("Should be able to get the owner of an account handler", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const owner = await handlerInstance.nftOwner();
            expect(owner).to.equal(await accounts_[1].getAddress());
        });

        it("Only the master should be able to set the nexus contract address", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await expect(
                handlerInstance.connect(accounts_[1]).setNexus(nexusDiamond)
            ).to.be.revertedWith("LibDiamond: Must be contract owner");
        });

        it("Owner of the account should be a valid signer", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const owner = await handlerInstance.nftOwner();

            const validSigner = await handlerInstance.isValidSigner(
                owner,
                "0x"
            );

            expect(validSigner).to.be.ok;
            expect(validSigner).to.equal("0x523e3260");
        });

        it("Other users should not be a valid signer", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const validSigner = await handlerInstance.isValidSigner(
                profiles[1].owner,
                "0x"
            );

            expect(validSigner).to.be.ok;
            expect(validSigner).to.equal("0x00000000"); // Invalid signer value
        });

        it("Should be able to provide a valid signature as the owner", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const messageHash = ethers.hashMessage("Hello world!");

            const owner = await handlerInstance.nftOwner();

            const signature = await profiles[0].owner.signMessage(
                "Hello world!"
            );

            const validSignature = await handlerInstance
                .connect(profiles[0].owner)
                .isValidSignature(messageHash, signature);

            expect(validSignature).to.be.ok;
            expect(validSignature).to.equal("0x1626ba7e"); // Valid signature return value
        });

        it("Should not be able to provide a valid signature as a different user", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const messageHash = ethers.hashMessage("Hello world!");

            const signature = await profiles[1].owner.signMessage(
                "Hello world!"
            );

            const invalidSignature = await handlerInstance
                .connect(profiles[0].owner)
                .isValidSignature(messageHash, signature);

            expect(invalidSignature).to.be.ok;
            expect(invalidSignature).to.equal("0x00000000"); // Invalid signature return value

            const invalidSignature2 = await handlerInstance
                .connect(profiles[1].owner)
                .isValidSignature(messageHash, signature);

            expect(invalidSignature2).to.be.ok;
            expect(invalidSignature2).to.equal("0x00000000"); // Invalid signature return value
        });

        it("Should be able to execute a simple transfer to a contract as an account", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await profiles[1].owner.sendTransaction({
                to: handlerInstance.target,
                value: 10000,
            });

            await handlerInstance
                .connect(profiles[0].owner)
                .execute(ethers.ZeroAddress, 10000, "0x", 0);

            const balance = await ethers.provider.getBalance(
                ethers.ZeroAddress
            );

            expect(balance).to.equal(10000);
        });

        it("Should be able to execute a simple function call as an account", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            // Deploy mock contract to test function call
            const mockExecute = await ethers.deployContract("MockExecute");

            await mockExecute.waitForDeployment();

            const result = await handlerInstance
                .connect(profiles[0].owner)
                .execute(
                    mockExecute.target,
                    0,
                    mockExecute.interface.encodeFunctionData("changeValue", [
                        ethers.encodeBytes32String("Hello world!"),
                    ]),
                    0
                );

            const receipt = (await result.wait()) as ContractTransactionReceipt;

            expect(receipt).to.be.ok;

            const keys = ["newValue", "success"];

            const changedValue = parseEventLogs(
                receipt.logs,
                mockExecute.interface,
                "ChangedValue",
                keys
            );

            expect(changedValue.newValue.toString()).to.equal(
                ethers.encodeBytes32String("Hello world!")
            );

            expect(changedValue.success).to.be.true;
        });

        it("Should not be able to transfer to an address that doesn't accept ETH", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await profiles[1].owner.sendTransaction({
                to: handlerInstance.target,
                value: 10000,
            });

            // Deploy mock contract to test function call
            const mockExecute = await ethers.deployContract("MockExecute");

            await mockExecute.waitForDeployment();

            await expect(
                handlerInstance
                    .connect(profiles[0].owner)
                    .execute(mockExecute.target, 10000, "0x", 0)
            ).to.be.revertedWithoutReason();
        });

        it("State of the contract should have been incremented after executions", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const state = await handlerInstance.state();
            expect(state).to.equal(2);
        });

        it("Current account tier should be at 1 since there was no tier up", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const tier = await handlerInstance.getTier();
            expect(tier).to.equal(1);
        });

        it("Tier counts should match the number of referrals", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const tierCounts = await handlerInstance.getTierCounts();
            // The first account should have 3 referrals under it
            expect(tierCounts).to.deep.equal([3n, 0n, 0n, 0n, 0n]);

            const handler2 = await nexusInstance.getHandler(2);

            const handlerInstance2 = await ethers.getContractAt(
                "AccountFacet",
                handler2
            );

            const tierCounts2 = await handlerInstance2.getTierCounts();
            // The second account should have 2 referrals under it
            expect(tierCounts2).to.deep.equal([2n, 0n, 0n, 0n, 0n]);

            const handler3 = await nexusInstance.getHandler(3);

            const handlerInstance3 = await ethers.getContractAt(
                "AccountFacet",
                handler3
            );

            const tierCounts3 = await handlerInstance3.getTierCounts();
            // The third account should have 1 referral under it
            expect(tierCounts3).to.deep.equal([1n, 0n, 0n, 0n, 0n]);

            const handler4 = await nexusInstance.getHandler(4);

            const handlerInstance4 = await ethers.getContractAt(
                "AccountFacet",
                handler4
            );

            const tierCounts4 = await handlerInstance4.getTierCounts();
            // The fourth account should have 0 referrals under it
            expect(tierCounts4).to.deep.equal([0n, 0n, 0n, 0n, 0n]);
        });

        it("Tier manager and Tax manager should return a valid address", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const tierManagerAddress = await nexusInstance.getTierManager();
            const taxManagerAddress = await nexusInstance.getTaxManager();

            expect(tierManagerAddress).to.equal(tierManager.target);
            expect(taxManagerAddress).to.equal(taxManager.target);
        });

        it("Attempt to tier up should fail since the account hasn't met the requirements", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await expect(
                handlerInstance.connect(profiles[0].owner).tierUp()
            ).to.be.revertedWith("Tier upgrade condition not met");
        });

        it("Tier level should still be at 1 after a failed tier up attempt", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            const tier = await handlerInstance.getTier();
            expect(tier).to.equal(1);
        });

        it("Only owner should be able to change the eligibility for a level up", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await expect(
                handlerInstance
                    .connect(profiles[3].owner)
                    .changeEligibility(true)
            ).to.be.revertedWith("LibDiamond: Must be contract owner");
        });

        it("Should not be able to tier up if the account is not eligible for tier up", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler4 = await nexusInstance.getHandler(4);

            const handlerInstance4 = await ethers.getContractAt(
                "AccountFacet",
                handler4
            );

            await handlerInstance4.changeEligibility(false);

            await expect(handlerInstance4.tierUp()).to.be.revertedWith(
                "Can't increase the tier"
            );
        });

        it("The second account should have the first account as its referrer", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handler2 = await nexusInstance.getHandler(2);

            const handlerInstance2 = await ethers.getContractAt(
                "AccountFacet",
                handler2
            );

            const referrer = await handlerInstance2.referredBy();
            expect(referrer).to.equal(handler);
        });

        it("Should not be able to go out of search bounds when running checkReferralExistence", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handler4 = await nexusInstance.getHandler(4);

            const handlerInstance4 = await ethers.getContractAt(
                "AccountFacet",
                handler4
            );

            await expect(
                handlerInstance4.checkReferralExistence(5, handler)
            ).to.be.revertedWith("Invalid depth");
        });

        it("Should not be able to search for a non-existent account", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler4 = await nexusInstance.getHandler(4);

            const handlerInstance4 = await ethers.getContractAt(
                "AccountFacet",
                handler4
            );

            await expect(
                handlerInstance4.checkReferralExistence(1, ethers.ZeroAddress)
            ).to.be.revertedWith("Invalid referred address");

            // And will revert if using a non-existent account
            await expect(
                handlerInstance4.checkReferralExistence(
                    1,
                    await handlerInstance4.nftOwner()
                )
            ).to.be.reverted;
        });

        it("Should return correct tier for referral users under the first account", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);
            const handler2 = await nexusInstance.getHandler(2);
            const handler3 = await nexusInstance.getHandler(3);
            const handler4 = await nexusInstance.getHandler(4);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            let referralExistence =
                await handlerInstance.checkReferralExistence(1, handler2);

            expect(referralExistence).to.be.ok;
            expect(referralExistence).to.equal(1);

            referralExistence = await handlerInstance.checkReferralExistence(
                2,
                handler3
            );

            expect(referralExistence).to.be.ok;
            expect(referralExistence).to.equal(1);

            referralExistence = await handlerInstance.checkReferralExistence(
                3,
                handler4
            );

            expect(referralExistence).to.be.ok;
            expect(referralExistence).to.equal(1);
        });

        it("Should not be able to addToReferralTree unless called from the nexus", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler4 = await nexusInstance.getHandler(4);

            const handlerInstance4 = await ethers.getContractAt(
                "AccountFacet",
                handler4
            );

            await expect(
                handlerInstance4.addToReferralTree(1, handler4)
            ).to.be.revertedWith("only nexus");
        });

        it("Should be able to tier up once xp token is minted to the account", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(1);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            // mints slightly more xp to level up to the next tier
            await xpToken.mint(handler, 500000);

            await handlerInstance.tierUp();

            const tier = await handlerInstance.getTier();
            expect(tier).to.equal(2);
        });

        it("Only the protocol should be able to set the tier level of the accounts and update the referrers above", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(2);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await expect(
                handlerInstance.connect(profiles[1].owner).setTier(3)
            ).to.be.revertedWith("Account: Only Guardian or Nexus");
        });

        it("The protocol should be able to set the tier level of the accounts and update the referrers above", async function () {
            const nexusInstance = await ethers.getContractAt(
                "NexusFacet",
                nexusDiamond
            );

            const handler = await nexusInstance.getHandler(2);

            const handlerInstance = await ethers.getContractAt(
                "AccountFacet",
                handler
            );

            await handlerInstance.setTier(3);

            const tier = await handlerInstance.getTier();
            expect(tier).to.equal(3);

            const handler2 = await nexusInstance.getHandler(1);

            const handlerInstance2 = await ethers.getContractAt(
                "AccountFacet",
                handler2
            );

            const referrer = await handlerInstance.referredBy();
            expect(referrer).to.equal(handler2);

            // account 1 should have updated tier counts
            const tierCounts = await handlerInstance2.getTierCounts();

            expect(tierCounts).to.deep.equal([2n, 0n, 1n, 0n, 0n]);
        });
    });
});
