import { ethers } from "hardhat";
import { DiamondNexus } from "../../typechain-types";
import { Signer } from "ethers";
import {
    CommonFacets,
    Facets,
    NexusParams,
    PartyParams,
    TavernParams,
    WardenParams,
    deployCommonDiamondFacets,
    deployFacets,
    deployNexusDiamond,
    deployPartyDiamond,
    deployProfileNFT,
    deployRationPriceManager,
    deployRewarder,
    deployTavernDiamond,
    deployTaxManager,
    deployTierManager,
    deployWardenDiamond,
    deployXpToken,
} from "./diamondSetup";
import {
    PartyTax,
    ReferralRewardsDistribution,
    SeekerTax,
    SolverTax,
    TierConditions,
} from "./types";

async function commonFacetDeployments(
    deployer: Signer,
    displayPrints: boolean
): Promise<CommonFacets> {
    const commonFacets = await deployCommonDiamondFacets(
        deployer,
        displayPrints,
        0
    );

    return commonFacets;
}

async function facetsDeployments(
    deployer: Signer,
    displayPrints: boolean
): Promise<Facets> {
    const facets = await deployFacets(deployer, displayPrints, 0);

    return facets;
}

async function nexusDiamondDeployment(
    deployer: Signer,
    facets: NexusParams,
    displayPrints: boolean
): Promise<DiamondNexus> {
    const nexus = await deployNexusDiamond(deployer, facets, displayPrints, 0);

    return nexus;
}

async function rewarderDeployment(
    deployer: Signer,
    nexus: string,
    displayPrints: boolean
) {
    const rewarder = await deployRewarder(deployer, nexus, displayPrints, 0);
    return rewarder;
}

async function profileNFTDeployment(
    deployer: Signer,
    nexus: string,
    displayPrints: boolean
) {
    const profileNFT = await deployProfileNFT(
        deployer,
        nexus,
        displayPrints,
        0
    );
    return profileNFT;
}

async function tavernDiamondDeployment(
    deployer: Signer,
    tavernParams: TavernParams,
    displayPrints: boolean
) {
    const tavern = await deployTavernDiamond(
        deployer,
        tavernParams,
        displayPrints,
        0
    );
    return tavern;
}

async function xpTokenDeployment(deployer: Signer, displayPrints: boolean) {
    const xpToken = await deployXpToken(deployer, displayPrints, 0);
    return xpToken;
}

async function taxManagerDeployment(deployer: Signer, displayPrints: boolean) {
    const taxManager = await deployTaxManager(deployer, displayPrints, 0);
    return taxManager;
}

async function tierManagerDeployment(
    deployer: Signer,
    xpToken: string,
    displayPrints: boolean
) {
    const tierManager = await deployTierManager(
        deployer,
        xpToken,
        displayPrints,
        0
    );
    return tierManager;
}

async function setupNexusDiamond(
    deployer: Signer,
    guardian: string,
    nexusDiamond: string,
    commonFacets: CommonFacets,
    facets: Facets,
    profileNftAddress: string,
    rewarderAddress: string,
    taxManagerAddress: string,
    tierManagerAddress: string
) {
    const nexusDiamondContract = await ethers.getContractAt(
        "NexusFacet",
        nexusDiamond,
        deployer // signer
    );

    // Setting diamond account implementation
    await nexusDiamondContract.setDiamondAccountImplementation(
        facets.account.target
    );

    // Setting diamond cut implementation
    await nexusDiamondContract.setDiamondCutImplementation(
        commonFacets.cutFacet.target
    );

    // Setting diamond ownership implementation
    await nexusDiamondContract.setDiamondOwnershipImplementation(
        commonFacets.ownership.target
    );

    // Setting diamond loupe implementation
    await nexusDiamondContract.setDiamondLoupeImplementation(
        commonFacets.loupeFacet.target
    );

    // Setting guardian
    await nexusDiamondContract.setGuardian(guardian);

    // Setting NFT
    await nexusDiamondContract.setNFT(profileNftAddress);

    // Setting rewarder
    await nexusDiamondContract.setRewarder(rewarderAddress);

    // Setting tax manager
    await nexusDiamondContract.setTaxManager(taxManagerAddress);

    // Setting tier manager
    await nexusDiamondContract.setTierManager(tierManagerAddress);
}

async function setupTavernDiamond(
    deployer: Signer,
    tavernBarkeeper: string,
    tavernDiamond: string,
    nexusDiamond: string,
    reviewPeriod: number,
    mediator: string,
    implementation: {
        native: string;
        token: string;
        quest: string;
    }
) {
    const tavernDiamondContract = await ethers.getContractAt(
        "TavernFacet",
        tavernDiamond,
        deployer
    );

    // Setting barkeeper
    await tavernDiamondContract.setBarkeeper(tavernBarkeeper);

    // Setting nexus
    await tavernDiamondContract.setNexus(nexusDiamond);

    // Setting review period
    await tavernDiamondContract.setReviewPeriod(reviewPeriod);

    // Setting mediator
    await tavernDiamondContract.setMediator(mediator);

    // Setting implementation
    await tavernDiamondContract.setImplementation(
        implementation.native,
        implementation.token,
        implementation.quest
    );
}

async function setupTaxManagerTreasuries(
    deployer: Signer,
    taxManagerAddress: string
) {
    const taxManager = await ethers.getContractAt(
        "TaxManager",
        taxManagerAddress,
        deployer
    );

    // Setting platform treasury pool
    await taxManager.setPlatformTreasuryPool(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    );

    // Setting platform revenue pool
    await taxManager.setPlatformRevenuePool(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    );

    // Setting referral tax treasury
    await taxManager.setReferralTaxTreasury(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    );

    // Setting dispute fees treasury
    await taxManager.setDisputeFeesTreasury(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    );

    // Setting participation rewards treasury pool
    await taxManager.setParticipationRewardPool(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    );
}

const seekerFees: SeekerTax = {
    referralRewards: 100n,
    platformRevenue: 100n,
    sharesFee: 100n,
};

const solverFees: SolverTax = {
    referralRewards: 200n,
    platformRevenue: 500n,
    platformTreasury: 100n,
    sharesFee: 200n,
};

export const partyFees: PartyTax = {
    leaderRewards: 500n,
    referralRewards: 100n,
    platformRevenue: 300n,
    membersRewards: 100n,
};

const DISPUTE_RATE = 1000n;

const referralRewardsTax = 3000n;

export const referralRewardsTaxRate = 5000n;

async function setupTaxManagerFees(
    deployer: Signer,
    taxManagerAddress: string
) {
    const taxManager = await ethers.getContractAt(
        "TaxManager",
        taxManagerAddress,
        deployer
    );

    // Set seeker fees
    await taxManager.setSeekerFees(
        seekerFees.referralRewards,
        seekerFees.platformRevenue,
        seekerFees.sharesFee
    );

    // Set solver fees
    await taxManager.setSolverFees(
        solverFees.referralRewards,
        solverFees.platformRevenue,
        solverFees.platformTreasury,
        solverFees.sharesFee
    );

    // Set party fees
    await taxManager.setPartyFees(
        partyFees.leaderRewards,
        partyFees.referralRewards,
        partyFees.platformRevenue,
        partyFees.membersRewards
    );

    await taxManager.setDisputeDepositRate(DISPUTE_RATE);

    await taxManager.setReferralRewardsTaxRate(referralRewardsTax);

    await taxManager.setReferralRewardsFee(
        referralRewardsTaxRate,
        referralRewardsTaxRate
    );
}

const referralRewardsDistribution: ReferralRewardsDistribution = {
    tier1: {
        layer1: 1200,
        layer2: 800,
        layer3: 400,
        layer4: 200,
    },
    tier2: {
        layer1: 1600,
        layer2: 1050,
        layer3: 525,
        layer4: 260,
    },
    tier3: {
        layer1: 2000,
        layer2: 1300,
        layer3: 650,
        layer4: 375,
    },
    tier4: {
        layer1: 2400,
        layer2: 1600,
        layer3: 800,
        layer4: 400,
    },
    tier5: {
        layer1: 3000,
        layer2: 2000,
        layer3: 1000,
        layer4: 600,
    },
};

async function setupTaxManagerBulkReferralRate(
    deployer: Signer,
    taxManagerAddress: string
) {
    const taxManager = await ethers.getContractAt(
        "TaxManager",
        taxManagerAddress,
        deployer
    );

    // Set referral rate for tier 1
    await taxManager.setBulkReferralRate(
        1,
        referralRewardsDistribution.tier1.layer1,
        referralRewardsDistribution.tier1.layer2,
        referralRewardsDistribution.tier1.layer3,
        referralRewardsDistribution.tier1.layer4
    );

    // Set referral rate for tier 2
    await taxManager.setBulkReferralRate(
        2,
        referralRewardsDistribution.tier2.layer1,
        referralRewardsDistribution.tier2.layer2,
        referralRewardsDistribution.tier2.layer3,
        referralRewardsDistribution.tier2.layer4
    );

    // Set referral rate for tier 3
    await taxManager.setBulkReferralRate(
        3,
        referralRewardsDistribution.tier3.layer1,
        referralRewardsDistribution.tier3.layer2,
        referralRewardsDistribution.tier3.layer3,
        referralRewardsDistribution.tier3.layer4
    );

    // Set referral rate for tier 4
    await taxManager.setBulkReferralRate(
        4,
        referralRewardsDistribution.tier4.layer1,
        referralRewardsDistribution.tier4.layer2,
        referralRewardsDistribution.tier4.layer3,
        referralRewardsDistribution.tier4.layer4
    );

    // Set referral rate for tier 5
    await taxManager.setBulkReferralRate(
        5,
        referralRewardsDistribution.tier5.layer1,
        referralRewardsDistribution.tier5.layer2,
        referralRewardsDistribution.tier5.layer3,
        referralRewardsDistribution.tier5.layer4
    );
}

const tierConditions: TierConditions = {
    tier1: {
        xpPoints: ethers.parseUnits("3", 2),
        novicesReferred: 0n,
        adeptsReferred: 0n,
        expertsReferred: 0n,
        mastersReferred: 0n,
        godsReferred: 0n,
    },
    tier2: {
        xpPoints: ethers.parseUnits("4470", 2),
        novicesReferred: 3n,
        adeptsReferred: 0n,
        expertsReferred: 0n,
        mastersReferred: 0n,
        godsReferred: 0n,
    },
    tier3: {
        xpPoints: ethers.parseUnits("37224", 2),
        novicesReferred: 5n,
        adeptsReferred: 1n,
        expertsReferred: 0n,
        mastersReferred: 0n,
        godsReferred: 0n,
    },
    tier4: {
        xpPoints: ethers.parseUnits("737627", 2),
        novicesReferred: 5n,
        adeptsReferred: 2n,
        expertsReferred: 1n,
        mastersReferred: 0n,
        godsReferred: 0n,
    },
    tier5: {
        xpPoints: ethers.parseUnits("5346332", 2),
        novicesReferred: 5n,
        adeptsReferred: 2n,
        expertsReferred: 1n,
        mastersReferred: 1n,
        godsReferred: 0n,
    },
};

async function setupTierManagerConditions(
    deployer: Signer,
    tierManagerAddress: string
) {
    const tierManager = await ethers.getContractAt(
        "TierManager",
        tierManagerAddress,
        deployer
    );

    // Set tier conditions - tier 1
    await tierManager.setConditions(
        1,
        tierConditions.tier1.xpPoints,
        tierConditions.tier1.novicesReferred,
        tierConditions.tier1.adeptsReferred,
        tierConditions.tier1.expertsReferred,
        tierConditions.tier1.mastersReferred,
        tierConditions.tier1.godsReferred
    );

    // Set tier conditions - tier 2
    await tierManager.setConditions(
        2,
        tierConditions.tier2.xpPoints,
        tierConditions.tier2.novicesReferred,
        tierConditions.tier2.adeptsReferred,
        tierConditions.tier2.expertsReferred,
        tierConditions.tier2.mastersReferred,
        tierConditions.tier2.godsReferred
    );

    // Set tier conditions - tier 3
    await tierManager.setConditions(
        3,
        tierConditions.tier3.xpPoints,
        tierConditions.tier3.novicesReferred,
        tierConditions.tier3.adeptsReferred,
        tierConditions.tier3.expertsReferred,
        tierConditions.tier3.mastersReferred,
        tierConditions.tier3.godsReferred
    );

    // Set tier conditions - tier 4
    await tierManager.setConditions(
        4,
        tierConditions.tier4.xpPoints,
        tierConditions.tier4.novicesReferred,
        tierConditions.tier4.adeptsReferred,
        tierConditions.tier4.expertsReferred,
        tierConditions.tier4.mastersReferred,
        tierConditions.tier4.godsReferred
    );

    // Set tier conditions - tier 5
    await tierManager.setConditions(
        5,
        tierConditions.tier5.xpPoints,
        tierConditions.tier5.novicesReferred,
        tierConditions.tier5.adeptsReferred,
        tierConditions.tier5.expertsReferred,
        tierConditions.tier5.mastersReferred,
        tierConditions.tier5.godsReferred
    );

    // Set ration limit - tier 1
    await tierManager.setRationLimit(1, 2);

    // Set ration limit - tier 2
    await tierManager.setRationLimit(2, 3);

    // Set ration limit - tier 3
    await tierManager.setRationLimit(3, 4);

    // Set ration limit - tier 4
    await tierManager.setRationLimit(4, 5);

    // Set ration limit - tier 5
    await tierManager.setRationLimit(5, 6);
}

async function partyDiamondDeployment(
    deployer: Signer,
    partyParams: PartyParams,
    displayPrints: boolean
) {
    const party = await deployPartyDiamond(
        deployer,
        partyParams,
        displayPrints,
        0
    );
    return party;
}

async function wardenDiamondDeployment(
    deployer: Signer,
    wardenParams: WardenParams,
    displayPrints: boolean
) {
    const warden = await deployWardenDiamond(
        deployer,
        wardenParams,
        displayPrints,
        0
    );
    return warden;
}

async function rationPriceManagerDeployment(
    deployer: Signer,
    displayPrints: boolean
) {
    const rationPriceManager = await deployRationPriceManager(
        deployer,
        displayPrints,
        0
    );
    return rationPriceManager;
}

async function setupRewarder(
    deployer: Signer,
    rewarderAddress: string,
    partyAddress: string
) {
    const rewarder = await ethers.getContractAt(
        "Rewarder",
        rewarderAddress,
        deployer
    );

    // Setting nexus
    await rewarder.setParty(partyAddress);
}

async function setupPartyDiamond(
    deployer: Signer,
    partyDiamond: string,
    nexusDiamond: string,
    wardenDiamond: string
) {
    const partyDiamondContract = await ethers.getContractAt(
        "PartyFacet",
        partyDiamond,
        deployer
    );

    // Setting nexus
    await partyDiamondContract.setNexus(nexusDiamond);

    // Setting warden
    await partyDiamondContract.setWarden(wardenDiamond);
}

async function setupPartyOnNexus(
    deployer: Signer,
    nexusDiamond: string,
    partyDiamond: string
) {
    const nexusDiamondContract = await ethers.getContractAt(
        "NexusFacet",
        nexusDiamond,
        deployer
    );

    // Setting party
    await nexusDiamondContract.setParty(partyDiamond);
}

async function setupWardenDiamond(
    deployer: Signer,
    wardenDiamond: string,
    partyDiamond: string,
    chiefAddress: string,
    rewarderAddress: string,
    rationPriceManagerAddress: string,
    commonFacets: CommonFacets,
    facets: Facets
) {
    const wardenDiamondContract = await ethers.getContractAt(
        "WardenFacet",
        wardenDiamond,
        deployer
    );

    // Setting party
    await wardenDiamondContract.setParty(partyDiamond);

    // Setting chief
    await wardenDiamondContract.setChief(chiefAddress);

    // Setting rewarder
    await wardenDiamondContract.setRewarder(rewarderAddress);

    // Setting ration price manager
    await wardenDiamondContract.setRationPriceManager(
        rationPriceManagerAddress
    );

    // Setting diamond cut implementation
    await wardenDiamondContract.setDiamondCutImplementation(
        commonFacets.cutFacet.target
    );

    // Setting diamond safehold implementation
    await wardenDiamondContract.setDiamondSafeholdFacet(facets.safehold.target);

    // Setting diamond loot implementation
    await wardenDiamondContract.setDiamondLootFacet(facets.loot.target);

    // Setting diamond ownership implementation
    await wardenDiamondContract.setDiamondOwnershipFacet(
        commonFacets.ownership.target
    );

    // Setting diamond pausable implementation
    await wardenDiamondContract.setDiamondPausableFacet(
        commonFacets.pausable.target
    );

    // Setting diamond loupe implementation
    await wardenDiamondContract.setDiamondLoupeFacet(
        commonFacets.loupeFacet.target
    );
}

export async function diamond_integration_fixture(deployer: Signer) {
    const displayPrints = false;

    // Deploying common facets {cut, loupe, ownership, pausable}

    const commonFacets = await commonFacetDeployments(deployer, displayPrints);

    // Deploying the rest of the facets
    const facets = await facetsDeployments(deployer, displayPrints);

    // Deploying the Nexus Diamond
    const nexus = await nexusDiamondDeployment(
        deployer,
        {
            cutFacet: commonFacets.cutFacet.target as string,
            nexusFacet: facets.nexus.target as string,
            ownershipFacet: commonFacets.ownership.target as string,
            pausableFacet: commonFacets.pausable.target as string,
        },
        displayPrints
    );

    // Deploying rewarder
    const rewarder = await rewarderDeployment(
        deployer,
        nexus.target as string,
        displayPrints
    );

    // Deploying profileNFT
    const profileNFT = await profileNFTDeployment(
        deployer,
        nexus.target as string,
        displayPrints
    );

    // Deploying tavern diamond
    const tavern = await tavernDiamondDeployment(
        deployer,
        {
            cutFacet: commonFacets.cutFacet.target as string,
            tavernFacet: facets.tavern.target as string,
            ownableFacet: commonFacets.ownership.target as string,
            pausableFacet: commonFacets.pausable.target as string,
            nexusAddress: nexus.target as string,
            escrowNativeFacet: facets.escrow.native.target as string,
            escrowTokenFacet: facets.escrow.token.target as string,
            questFacet: facets.quest.target as string,
        },
        displayPrints
    );

    // Deploying XP Token
    const xpToken = await xpTokenDeployment(deployer, displayPrints);

    // Deploy Tax Manager
    const taxManager = await taxManagerDeployment(deployer, displayPrints);

    // Deploy Tier Manager
    const tierManager = await tierManagerDeployment(
        deployer,
        xpToken.target as string,
        displayPrints
    );

    // Setup nexus contract
    await setupNexusDiamond(
        deployer,
        await deployer.getAddress(),
        nexus.target as string,
        commonFacets,
        facets,
        profileNFT.target as string,
        rewarder.target as string,
        taxManager.target as string,
        tierManager.target as string
    );

    // Setup tavern diamond
    await setupTavernDiamond(
        deployer,
        await deployer.getAddress(),
        tavern.target as string,
        nexus.target as string,
        86400,
        await deployer.getAddress(),
        {
            native: facets.escrow.native.target as string,
            token: facets.escrow.token.target as string,
            quest: facets.quest.target as string,
        }
    );

    // Setup Tax Manager Treasuries
    await setupTaxManagerTreasuries(deployer, taxManager.target as string);

    // Setup Tax Manager Fees
    await setupTaxManagerFees(deployer, taxManager.target as string);

    // Setup Tax Manager Bulk Referral Rate
    await setupTaxManagerBulkReferralRate(
        deployer,
        taxManager.target as string
    );

    // Setup Tier Manager Conditions
    await setupTierManagerConditions(deployer, tierManager.target as string);

    // Deploy Party Diamond
    const party = await partyDiamondDeployment(
        deployer,
        {
            cutFacet: commonFacets.cutFacet.target as string,
            partyFacet: facets.party.target as string,
            ownershipFacet: commonFacets.ownership.target as string,
            pausableFacet: commonFacets.pausable.target as string,
        },
        displayPrints
    );

    // Deploy warden diamond
    const warden = await wardenDiamondDeployment(
        deployer,
        {
            cutFacet: commonFacets.cutFacet.target as string,
            wardenFacet: facets.warden.target as string,
            ownershipFacet: commonFacets.ownership.target as string,
            pausableFacet: commonFacets.pausable.target as string,
        },
        displayPrints
    );

    // Deploy ration price manager
    const rationPriceManager = await rationPriceManagerDeployment(
        deployer,
        displayPrints
    );

    // Rewarder setup
    await setupRewarder(
        deployer,
        rewarder.target as string,
        party.target as string
    );

    // Setup party diamond
    await setupPartyDiamond(
        deployer,
        party.target as string,
        nexus.target as string,
        warden.target as string
    );

    // Set party contract on nexus
    await setupPartyOnNexus(
        deployer,
        nexus.target as string,
        party.target as string
    );

    // Warden setup
    await setupWardenDiamond(
        deployer,
        warden.target as string,
        party.target as string,
        await deployer.getAddress(),
        rewarder.target as string,
        rationPriceManager.target as string,
        commonFacets,
        facets
    );

    return {
        contracts: {
            commonFacets,
            facets,
            nexus,
            rewarder,
            profileNFT,
            tavern,
            xpToken,
            taxManager,
            tierManager,
            party,
            warden,
            rationPriceManager,
        },
    };
}
