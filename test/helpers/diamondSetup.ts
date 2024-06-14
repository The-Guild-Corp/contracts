import { ethers } from "hardhat";
import { Signer } from "ethers";
import {
    AccountFacet,
    DiamondCutFacet,
    DiamondLoupeFacet,
    DiamondNexus,
    DiamondParty,
    DiamondTavern,
    EscrowNative,
    EscrowToken,
    LootDistributorFacet,
    NexusFacet,
    OwnershipFacet,
    PartyFacet,
    PausableFacet,
    ProfileNFT,
    QuestFacet,
    RationPriceManager,
    Rewarder,
    SafeholdFacet,
    TavernFacet,
    WardenAdminFacet,
    WardenFacet,
    WardenFactoryFacet,
} from "../../typechain-types";
import { sleep } from "../../test/helpers/utils";

export type CommonFacets = {
    cutFacet: DiamondCutFacet;
    loupeFacet: DiamondLoupeFacet;
    ownership: OwnershipFacet;
    pausable: PausableFacet;
};

export async function deployCommonDiamondFacets(
    deployer: Signer,
    silent: boolean,
    timeout: number
): Promise<CommonFacets> {
    const DiamondCutFacet = await ethers.deployContract("DiamondCutFacet", {
        signer: deployer,
    });

    await DiamondCutFacet.waitForDeployment();

    if (silent) {
        console.log("DiamondCutFacet deployed to:", DiamondCutFacet.target);
    }

    sleep(timeout);

    const DiamondLoupeFacet = await ethers.deployContract("DiamondLoupeFacet", {
        signer: deployer,
    });

    await DiamondLoupeFacet.waitForDeployment();

    if (silent) {
        console.log("DiamondLoupeFacet deployed to:", DiamondLoupeFacet.target);
    }

    sleep(timeout);

    const OwnershipFacet = await ethers.deployContract("OwnershipFacet", {
        signer: deployer,
    });

    await OwnershipFacet.waitForDeployment();

    if (silent) {
        console.log("OwnershipFacet deployed to:", OwnershipFacet.target);
    }

    sleep(timeout);

    const PausableFacet = await ethers.deployContract("PausableFacet", {
        signer: deployer,
    });

    await PausableFacet.waitForDeployment();

    if (silent) {
        console.log("PausableFacet deployed to:", PausableFacet.target);
    }

    sleep(timeout);

    return {
        cutFacet: DiamondCutFacet,
        loupeFacet: DiamondLoupeFacet,
        ownership: OwnershipFacet,
        pausable: PausableFacet,
    };
}

export type Facets = {
    account: AccountFacet;
    escrow: { native: EscrowNative; token: EscrowToken };
    loot: LootDistributorFacet;
    nexus: NexusFacet;
    party: PartyFacet;
    quest: QuestFacet;
    safehold: SafeholdFacet;
    tavern: TavernFacet;
    warden: WardenFacet;
    wardenAdmin: WardenAdminFacet;
    wardenFactory: WardenFactoryFacet;
    libFactories: {
        account: any;
        loot: any;
        safehold: any;
    };
};

export async function deployFacets(
    deployer: Signer,
    silent: boolean,
    timeout: number
): Promise<Facets> {
    const AccountFacet = await ethers.deployContract("AccountFacet", {
        signer: deployer,
    });

    await AccountFacet.waitForDeployment();

    if (silent) {
        console.log("AccountFacet deployed to:", AccountFacet.target);
    }

    await sleep(timeout);

    const EscrowNative = await ethers.deployContract("EscrowNative", {
        signer: deployer,
    });

    await EscrowNative.waitForDeployment();

    if (silent) {
        console.log("EscrowNative deployed to:", EscrowNative.target);
    }

    await sleep(timeout);

    const EscrowToken = await ethers.deployContract("EscrowToken", {
        signer: deployer,
    });

    await EscrowToken.waitForDeployment();

    if (silent) {
        console.log("EscrowToken deployed to:", EscrowToken.target);
    }

    await sleep(timeout);

    const LootDistributorFacet = await ethers.deployContract(
        "LootDistributorFacet",
        {
            signer: deployer,
        }
    );

    await LootDistributorFacet.waitForDeployment();

    if (silent) {
        console.log(
            "LootDistributorFacet deployed to:",
            LootDistributorFacet.target
        );
    }

    await sleep(timeout);

    const LibAccountFactory = await ethers.deployContract("LibAccountFactory", {
        signer: deployer,
    });

    await LibAccountFactory.waitForDeployment();

    if (silent) {
        console.log("LibAccountFactory deployed to:", LibAccountFactory.target);
    }

    await sleep(timeout);

    const LibLootDistributor = await ethers.deployContract(
        "LibLootDistributorFactory",
        {
            signer: deployer,
        }
    );

    await LibLootDistributor.waitForDeployment();

    if (silent) {
        console.log(
            "LibLootDistributor deployed to:",
            LibLootDistributor.target
        );
    }

    await sleep(timeout);

    const LibSafeholdFactory = await ethers.deployContract(
        "LibSafeholdFactory",
        {
            signer: deployer,
        }
    );

    await LibSafeholdFactory.waitForDeployment();

    if (silent) {
        console.log(
            "LibSafeholdFactory deployed to:",
            LibSafeholdFactory.target
        );
    }

    await sleep(timeout);

    const NexusFacet = await ethers.deployContract("NexusFacet", {
        signer: deployer,
    });

    await NexusFacet.waitForDeployment();

    if (silent) {
        console.log("NexusFacet deployed to:", NexusFacet.target);
    }

    await sleep(timeout);

    const PartyFacet = await ethers.deployContract("PartyFacet", {
        signer: deployer,
    });

    await PartyFacet.waitForDeployment();

    if (silent) {
        console.log("PartyFacet deployed to:", PartyFacet.target);
    }

    await sleep(timeout);

    const QuestFacet = await ethers.deployContract("QuestFacet", {
        signer: deployer,
    });

    await QuestFacet.waitForDeployment();

    if (silent) {
        console.log("QuestFacet deployed to:", QuestFacet.target);
    }

    await sleep(timeout);

    const SafeholdFacet = await ethers.deployContract("SafeholdFacet", {
        signer: deployer,
    });

    await SafeholdFacet.waitForDeployment();

    if (silent) {
        console.log("SafeholdFacet deployed to:", SafeholdFacet.target);
    }

    await sleep(timeout);

    const TavernFacet = await ethers.deployContract("TavernFacet", {
        signer: deployer,
    });

    await TavernFacet.waitForDeployment();

    if (silent) {
        console.log("TavernFacet deployed to:", TavernFacet.target);
    }

    await sleep(timeout);

    const WardenFacet = await ethers.deployContract("WardenFacet", {
        signer: deployer,
    });

    await WardenFacet.waitForDeployment();

    if (silent) {
        console.log("WardenFacet deployed to:", WardenFacet.target);
    }

    await sleep(timeout);

    const WardenAdminFacet = await ethers.deployContract("WardenAdminFacet", {
        signer: deployer,
    });

    await WardenAdminFacet.waitForDeployment();

    if (silent) {
        console.log("WardenAdminFacet deployed to:", WardenAdminFacet.target);
    }

    await sleep(timeout);

    const wardenFactoryFacet = await ethers.deployContract(
        "WardenFactoryFacet",
        {
            signer: deployer,
        }
    );

    await wardenFactoryFacet.waitForDeployment();

    if (silent) {
        console.log(
            "WardenFactoryFacet deployed to:",
            wardenFactoryFacet.target
        );
    }

    return {
        account: AccountFacet,
        escrow: { native: EscrowNative, token: EscrowToken },
        loot: LootDistributorFacet,
        nexus: NexusFacet,
        party: PartyFacet,
        quest: QuestFacet,
        safehold: SafeholdFacet,
        tavern: TavernFacet,
        warden: WardenFacet,
        wardenAdmin: WardenAdminFacet,
        wardenFactory: wardenFactoryFacet,
        libFactories: {
            account: LibAccountFactory,
            loot: LibLootDistributor,
            safehold: LibSafeholdFactory,
        },
    };
}

export type NexusParams = {
    cutFacet: string;
    nexusFacet: string;
    ownershipFacet: string;
    pausableFacet: string;
};

export async function deployNexusDiamond(
    deployer: Signer,
    facets: NexusParams,
    silent: boolean,
    timeout: number
): Promise<DiamondNexus> {
    const deployerAddress = await deployer.getAddress();

    const DiamondNexus = await ethers.deployContract(
        "DiamondNexus",
        [
            deployerAddress,
            facets.cutFacet,
            facets.nexusFacet,
            facets.ownershipFacet,
            facets.pausableFacet,
        ],
        {
            signer: deployer,
        }
    );

    await DiamondNexus.waitForDeployment();

    if (silent) {
        console.log("DiamondNexus deployed to:", DiamondNexus.target);
    }

    await sleep(timeout);

    return DiamondNexus;
}

export async function deployRewarder(
    deployer: Signer,
    nexus: string,
    silent: boolean,
    timeout: number
): Promise<Rewarder> {
    const steward = await deployer.getAddress();

    const rewarder = await ethers.deployContract("Rewarder", [steward, nexus], {
        signer: deployer,
    });

    await rewarder.waitForDeployment();

    if (silent) {
        console.log("rewarder deployed to:", rewarder.target);
    }

    sleep(timeout);

    return rewarder;
}

export async function deployProfileNFT(
    deployer: Signer,
    nexus: string,
    silent: boolean,
    timeout: number
): Promise<ProfileNFT> {
    const profileNFT = await ethers.deployContract("ProfileNFT", [nexus], {
        signer: deployer,
    });

    await profileNFT.waitForDeployment();

    if (silent) {
        console.log("profileNFT deployed to:", profileNFT.target);
    }

    await sleep(timeout);

    return profileNFT;
}

export type TavernParams = {
    cutFacet: string;
    tavernFacet: string;
    pausableFacet: string;
    ownableFacet: string;
    nexusAddress: string;
    escrowNativeFacet: string;
    escrowTokenFacet: string;
    questFacet: string;
};

export async function deployTavernDiamond(
    deployer: Signer,
    tavernParams: TavernParams,
    silent: boolean,
    timeout: number
): Promise<DiamondTavern> {
    const deployerAddress = await deployer.getAddress();

    const TavernDiamond = await ethers.deployContract(
        "DiamondTavern",
        [
            deployerAddress,
            tavernParams.cutFacet,
            tavernParams.tavernFacet,
            tavernParams.pausableFacet,
            tavernParams.ownableFacet,
            tavernParams.nexusAddress,
            tavernParams.escrowNativeFacet,
            tavernParams.escrowTokenFacet,
            tavernParams.questFacet,
        ],
        {
            signer: deployer,
        }
    );

    await TavernDiamond.waitForDeployment();

    if (silent) {
        console.log("TavernDiamond deployed to:", TavernDiamond.target);
    }

    await sleep(timeout);

    return TavernDiamond;
}

export async function deployXpToken(
    deployer: Signer,
    silent: boolean,
    timeout: number
) {
    const deployerAddress = await deployer.getAddress();

    const XpToken = await ethers.deployContract("GuildXp", [deployerAddress], {
        signer: deployer,
    });

    await XpToken.waitForDeployment();

    if (silent) {
        console.log("XpToken deployed to:", XpToken.target);
    }

    await sleep(timeout);

    return XpToken;
}

export async function deployTaxManager(
    deployer: Signer,
    silent: boolean,
    timeout: number
) {
    const deployerAddress = await deployer.getAddress();

    const TaxManager = await ethers.deployContract("TaxManager", {
        signer: deployer,
    });

    await TaxManager.waitForDeployment();

    if (silent) {
        console.log("TaxManager deployed to:", TaxManager.target);
    }

    await sleep(timeout);

    return TaxManager;
}

export async function deployTierManager(
    deployer: Signer,
    xpToken: string,
    silent: boolean,
    timeout: number
) {
    const TierManager = await ethers.deployContract("TierManager", [xpToken], {
        signer: deployer,
    });

    await TierManager.waitForDeployment();

    if (silent) {
        console.log("TierManager deployed to:", TierManager.target);
    }

    await sleep(timeout);

    return TierManager;
}

export type PartyParams = {
    cutFacet: string;
    partyFacet: string;
    ownershipFacet: string;
    pausableFacet: string;
};

export async function deployPartyDiamond(
    deployer: Signer,
    facets: PartyParams,
    silent: boolean,
    timeout: number
): Promise<DiamondParty> {
    const deployerAddress = await deployer.getAddress();

    const PartyDiamond = await ethers.deployContract(
        "DiamondParty",
        [
            deployerAddress,
            facets.cutFacet,
            facets.partyFacet,
            facets.ownershipFacet,
            facets.pausableFacet,
        ],
        {
            signer: deployer,
        }
    );

    await PartyDiamond.waitForDeployment();

    if (silent) {
        console.log("PartyDiamond deployed to:", PartyDiamond.target);
    }

    await sleep(timeout);

    return PartyDiamond;
}

export type WardenParams = {
    cutFacet: string;
    wardenFacet: string;
    wardenAdminFacet: string;
    wardenFactoryFacet: string;
    ownershipFacet: string;
    pausableFacet: string;
};

export async function deployWardenDiamond(
    deployer: Signer,
    facets: WardenParams,
    silent: boolean,
    timeout: number
): Promise<DiamondParty> {
    const deployerAddress = await deployer.getAddress();

    const WardenDiamond = await ethers.deployContract(
        "DiamondWarden",
        [
            deployerAddress,
            facets.cutFacet,
            facets.wardenFacet,
            facets.wardenAdminFacet,
            facets.wardenFactoryFacet,
            facets.ownershipFacet,
            facets.pausableFacet,
        ],
        {
            signer: deployer,
        }
    );

    await WardenDiamond.waitForDeployment();

    if (silent) {
        console.log("WardenDiamond deployed to:", WardenDiamond.target);
    }

    await sleep(timeout);

    return WardenDiamond;
}

export async function deployRationPriceManager(
    deployer: Signer,
    silent: boolean,
    timeout: number
): Promise<RationPriceManager> {
    const RationPriceManager = await ethers.deployContract(
        "RationPriceManager",
        {
            signer: deployer,
        }
    );

    await RationPriceManager.waitForDeployment();

    if (silent) {
        console.log(
            "RationPriceManager deployed to:",
            RationPriceManager.target
        );
    }

    await sleep(timeout);

    return RationPriceManager;
}
