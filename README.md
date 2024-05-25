# The Guild Corp Smart Contracts

Built with [EIP-2535: Diamond](https://eips.ethereum.org/EIPS/eip-2535). The protocols has 4 core components, which is the Referral contracts, Quest contracts, Shares (a.k.a Party) contracts, and also the Accounts contracts.

## Contracts Included:

-   Guild Referral System (NexusFacet, Rewarder, TaxManager, TierManager)
-   Account Profiles (AccountFacet)
-   NFT Profiles
-   Quest Factory (TavernFacet)
-   Quest Center (QuestFacet)
-   Quest Escrows (Native and Token)
-   XP Token
-   Party Center (PartyFacet)
-   Warden Factory (WardenFacet)
-   Loot (LootFacet)
-   Safehold (SafeholdFacet)

### Test Included:

-   [x] Referral System (NexusFacet and TierManager)
-   [ ] Referral System (Rewarder and TaxManager)
-   [x] Account Profiles
-   [ ] Quest Factory (TavernFacet)
-   [ ] Quest Center (QuestFacet)
-   [ ] Quest Escrows (Native and Token)
-   [ ] XP Token
-   [ ] Party Center (PartyFacet)
-   [ ] Warden Factory (WardenFacet)
-   [ ] Loot Escrow (LootFacet)
-   [ ] Safehold Escrow (SafeholdFacet)

Additional Tests will be added gradually for better context.

### Context:

-   Guild Referral System: The nexus acts as a center for minting profile nfts, creating profiles, and also getting started with the party system by creating a party.
-   Account Profiles: The account profiles is where rewards are submitted to, it is also bound to the profile nft which includes referral data. User would also be able to sign transactions to execute functions. A user's tier can also be updated here. 
-   Quest Factory (TavernFacet): The tavern is in charge of deploying quest contracts. As well as managing the review and extension period.
-   Quest Centre: Seekers and solvers will primarily be interacting with this contract to make further progress on their quest, or bring up any disputes.
-   Quest Escrow: Basic escrow functions to hold the funds for a quest.
-   XP Token: Token used as a leveling requirement.
-   Part Center: Acts as the contract for user interaction for buy/selling shares.
-   Warden Factory: Acts as an intermediary between the party contract and the escrows, also deploys new escrow for new parties. Price is calculated from the ration price manager.
-   Loot Escrow: Basic escrow contract for party members to get loot.
-   Safehold Escrow: Basic escrow contract for parties to hold the value of shares purchased.
