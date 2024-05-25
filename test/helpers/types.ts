import { TaxManager, TierManager } from "../../typechain-types";

export type Managers = {
    tierManager: TierManager;
    taxManager: TaxManager;
};

export type FilteredLogEvent = {
    args: [];
};

export type AccountDetails = {
    implementation: string;
    salt: string;
    chainId: number;
    tokenContract: string;
    tokenId: number;
};

export type CreatedAccount = {
    nftId: number;
    handlerAddress: string;
};

export type CreatedAccountWithOwner = CreatedAccount & {
    owner: string;
};

export type SeekerTax = {
    referralRewards: bigint;
    platformRevenue: bigint;
    sharesFee: bigint;
};

export type SolverTax = {
    referralRewards: bigint;
    platformRevenue: bigint;
    platformTreasury: bigint;
    sharesFee: bigint;
};

export type PartyTax = {
    leaderRewards: bigint;
    referralRewards: bigint;
    platformRevenue: bigint;
    membersRewards: bigint;
};

export type ReferralRewardsDistribution = {
    tier1: {
        layer1: number;
        layer2: number;
        layer3: number;
        layer4: number;
    };
    tier2: {
        layer1: number;
        layer2: number;
        layer3: number;
        layer4: number;
    };
    tier3: {
        layer1: number;
        layer2: number;
        layer3: number;
        layer4: number;
    };
    tier4: {
        layer1: number;
        layer2: number;
        layer3: number;
        layer4: number;
    };
    tier5: {
        layer1: number;
        layer2: number;
        layer3: number;
        layer4: number;
    };
};

export type LayerKeys = "layer1" | "layer2" | "layer3" | "layer4";

export type TierConditions = {
    tier1: {
        xpPoints: bigint;
        novicesReferred: bigint;
        adeptsReferred: bigint;
        expertsReferred: bigint;
        mastersReferred: bigint;
        godsReferred: bigint;
    };
    tier2: {
        xpPoints: bigint;
        novicesReferred: bigint;
        adeptsReferred: bigint;
        expertsReferred: bigint;
        mastersReferred: bigint;
        godsReferred: bigint;
    };
    tier3: {
        xpPoints: bigint;
        novicesReferred: bigint;
        adeptsReferred: bigint;
        expertsReferred: bigint;
        mastersReferred: bigint;
        godsReferred: bigint;
    };
    tier4: {
        xpPoints: bigint;
        novicesReferred: bigint;
        adeptsReferred: bigint;
        expertsReferred: bigint;
        mastersReferred: bigint;
        godsReferred: bigint;
    };
    tier5: {
        xpPoints: bigint;
        novicesReferred: bigint;
        adeptsReferred: bigint;
        expertsReferred: bigint;
        mastersReferred: bigint;
        godsReferred: bigint;
    };
};

export type NonDeployerConfigAccounts = {
    nexusGuardian: string;
    rewarderSteward: string;
    tavernBarkeeper: string;
    tavernMediator: string;
    taxManagerPlatformTreasury: string;
    taxManagerPlatformRevenuePool: string;
    taxManagerReferralTaxTreasury: string;
    taxManagerDisputeFeesTreasury: string;
    guildXpOwner: string;
};
