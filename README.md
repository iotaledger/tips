# Tangle Improvement Proposal (TIP) Repository

TIPs are improvement proposals for bettering the IOTA technology stack.

Building the IOTA ecosystem is a community effort, therefore we welcome anyone to propose, discuss and debate ideas that will later become formalized TIPs.

## Propose new ideas

Do you have an idea how to improve the IOTA technology stack?
- Head over to the [discussions](https://github.com/iotaledger/tips/discussions) page to browse already submitted ideas or share yours!
- Once your idea is discussed, you can submit a draft TIP ([template here](https://github.com/iotaledger/tips/blob/main/tip-template.md) as a PR to the repository.
- You will receive feedback from the TIP Editors and review from core devs.
- Once accepted, your TIP is merged as Draft.
- It is your responsibility to drive its implementation and to present a clear plan on how the new feature will be adopted by the network.
- Once implementation is ready and testing yields satisfactory result, the TIP becomes Proposed.
- Proposed TIPs that are supported by majority of the network become Active.

You may find more information about the TIP Process in [TIP-1](./tips/TIP-0001/tip-0001.md).

## Stardust TIPs

Stardust is the next upgrade of the IOTA protocol that adds tokenization and smart contract chain support besides many
more improvements. Browse the [list of TIPs](#list-of-tips) below with the _Stardust_ tag to learn more about what changes.

## List of TIPs

 - Last updated: 2023-10-19
 - The _Status_ of a TIP reflects its current state with respect to its progression to being supported on the IOTA mainnet.
   - `Draft` TIPs are work in progress. They may or may not have a working implementation on a testnet.
   - `Proposed` TIPs are demonstrated to have a working implementation. These TIPs are supported on Shimmer, the staging network of IOTA.
   - `Active` TIPs are supported on the IOTA mainnet.
   - `Replaced` TIPs have been replaced by a newer TIP.
   - `Obsolete` TIPs are no longer in use.

![image](tips/TIP-0001/process.svg)


| #  | Title                                                                     | Description                                                                                                                                      | Type      | Layer     | Status             | Initial Target |
|----|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|-----------|-----------|--------------------|----------------|
| 1  | [TIP Process](tips/TIP-0001/tip-0001.md)                                  | Purpose and guidelines of the contribution framework                                                                                             | Process   | -         | Active             | -              |
| 2  | [White Flag Ordering](tips/TIP-0002/tip-0002.md)                          | Mitigate conflict spamming by ignoring conflicts                                                                                                 | Standards | Core      | Active             | Chrysalis      |
| 3  | [Uniform Random Tip Selection](tips/TIP-0003/tip-0003.md)                 | Perform fast tip-selection to increase message throughput                                                                                        | Standards | Core      | Active             | Chrysalis      |
| 4  | [Milestone Merkle Validation](tips/TIP-0004/tip-0004.md)                  | Add Merkle tree hash to milestone for local ledger state verification                                                                            | Standards | Core      | Active             | Chrysalis      |
| 5  | [Binary To Ternary Encoding](tips/TIP-0005/tip-0005.md)                   | Define the conversion between binary and ternary data                                                                                            | Standards | Core      | Active             | Chrysalis      |
| 6  | [Tangle Message](tips/TIP-0006/tip-0006.md)                               | Generalization of the Tangle transaction concept                                                                                                 | Standards | Core      | Replaced by TIP-24 | Chrysalis      |
| 7  | [Transaction Payload](tips/TIP-0007/tip-0007.md)                          | UTXO-based transaction structure                                                                                                                 | Standards | Core      | Replaced by TIP-20 | Chrysalis      |
| 8  | [Milestone Payload](tips/TIP-0008/tip-0008.md)                            | Coordinator issued milestone structure with Ed25519 authentication                                                                               | Standards | Core      | Replaced by TIP-29 | Chrysalis      |
| 9  | [Local Snapshot File Format](tips/TIP-0009/tip-0009.md)                   | File format to export/import ledger state                                                                                                        | Standards | Interface | Replaced by TIP-35 | Chrysalis      |
| 10 | [Mnemonic Ternary Seed](tips/TIP-0010/tip-0010.md)                        | Represent ternary seed as a mnemonic sentence                                                                                                    | Standards | IRC       | Obsolete           | Legacy IOTA    |
| 11 | [Bech32 Address Format](tips/TIP-0011/tip-0011.md)                        | Extendable address format supporting various signature schemes and address types                                                                 | Standards | Interface | Replaced by TIP-31 | Chrysalis      |
| 12 | [Message PoW](tips/TIP-0012/tip-0012.md)                                  | Define message proof-of-work as a means to rate-limit the network                                                                                | Standards | Core      | Active             | Chrysalis      |
| 13 | [REST API](tips/TIP-0013/tip-0013.md)                                     | Node REST API routes and objects in OpenAPI Specification                                                                                        | Standards | Interface | Replaced by TIP-25 | Chrysalis      |
| 14 | [Ed25519 Validation](tips/TIP-0014/tip-0014.md)                           | Adopt [ZIP-215](https://zips.z.cash/zip-0215) to explicitly define Ed25519 validation criteria                                                   | Standards | Core      | Active             | Chrysalis      |
| 15 | [Dust Protection](tips/TIP-0015/tip-0015.md)                              | Prevent bloating the ledger size with to dust outputs                                                                                            | Standards | Core      | Replaced by TIP-19 | Chrysalis      |
| 16 | [Event API](tips/TIP-0016/tip-0016.md)                                    | Node event API definitions in AsyncAPI Specification                                                                                             | Standards | Interface | Replaced by TIP-28 | Chrysalis      |
| 17 | [Wotsicide](tips/TIP-0017/tip-0017.md)                                    | Define migration from legacy WOTS addresses to post-Chrysalis Phase 2 network                                                                    | Standards | Core      | Obsolete           | Chrysalis      |
| 18 | [Multi-Asset Ledger and ISC Support](tips/TIP-0018/tip-0018.md)           | Transform IOTA into a multi-asset ledger that supports running IOTA Smart Contracts                                                              | Standards | Core      | Active             | **Stardust**   |
| 19 | [Dust Protection Based on Byte Costs](tips/TIP-0019/tip-0019.md)          | Prevent bloating the ledger size with dust outputs                                                                                               | Standards | Core      | Active             | **Stardust**   |
| 20 | [Transaction Payload with New Output Types](tips/TIP-0020/tip-0020.md)    | UTXO-based transaction structure with TIP-18                                                                                                     | Standards | Core      | Active             | **Stardust**   |
| 21 | [Serialization Primitives](tips/TIP-0021/tip-0021.md)                     | Introduce primitives to describe the binary serialization of objects                                                                             | Standards | Core      | Active             | **Stardust**   |
| 22 | [IOTA Protocol Parameters](tips/TIP-0022/tip-0022.md)                     | Describes the global protocol parameters for the IOTA protocol                                                                                   | Standards | Core      | Active             | **Stardust**   |
| 23 | [Tagged Data Payload](tips/TIP-0023/tip-0023.md)                          | Payload for arbitrary data                                                                                                                       | Standards | Core      | Active             | **Stardust**   |
| 24 | [Tangle Block](tips/TIP-0024/tip-0024.md)                                 | A new version of TIP-6 that renames messages to blocks and removes the Indexation Payload in favor of the Tagged Data Payload. Replaces TIP-6.   | Standards | Core      | Active             | **Stardust**   |
| 25 | [Core REST API](tips/TIP-0025/tip-0025.md)                                | Node Core REST API routes and objects in OpenAPI Specification. Replaces TIP-13.                                                                 | Standards | Interface | Active             | **Stardust**   |
| 26 | [UTXO Indexer REST API](tips/TIP-0026/tip-0026.md)                        | UTXO Indexer REST API routes and objects in OpenAPI Specification.                                                                               | Standards | Interface | Active             | **Stardust**   |
| 27 | [IOTA NFT standards](tips/TIP-0027/tip-0027.md)                           | Define NFT metadata standard, collection system and creator royalties                                                                            | Standards | IRC       | Active             | **Stardust**   |
| 28 | [Node Event API](tips/TIP-0028/tip-0028.md)                               | Node event API definitions in AsyncAPI Specification. Replaces TIP-16.                                                                           | Standards | Interface | Active             | **Stardust**   |
| 29 | [Milestone Payload](tips/TIP-0029/tip-0029.md)                            | Milestone Payload with keys removed from essence. Replaces TIP-8.                                                                                | Standards | Core      | Active             | **Stardust**   |
| 30 | [Native Token Metadata Standard](tips/TIP-0030/tip-0030.md)               | A JSON schema that describes token metadata format for native token foundries                                                                    | Standards | IRC       | Active             | **Stardust**   |
| 31 | [Bech32 Address Format for IOTA and Shimmer](tips/TIP-0031/tip-0031.md)   | Extendable address format supporting various signature schemes and address types. Replaces TIP-11.                                               | Standards | Interface | Active             | **Stardust**   |
| 32 | [Shimmer Protocol Parameters](tips/TIP-0032/tip-0032.md)                  | Describes the global protocol parameters for the Shimmer network                                                                                 | Standards | Core      | Active             | **Stardust**   |
| 33 | [Public Token Registry](https://github.com/iotaledger/tips/pull/72)       | Defines an open public registry for NFT collection ID and native tokens metadata                                                                 | Standards | IRC       | Draft              | **Stardust**   |
| 34 | [Wotsicide (Stardust update)](tips/TIP-0034/tip-0034.md)                  | Define migration from legacy W-OTS addresses to post-Chrysalis networks. Replaces TIP-17.                                                        | Standards | Core      | Obsolete           | **Stardust**   |
| 35 | [Local Snapshot File Format (Stardust Update)](tips/TIP-0035/tip-0035.md) | File format to export/import ledger state. Replaces TIP-9.                                                                                       | Standards | Interface | Active             | **Stardust**   |
| 37 | [Dynamic Proof-of-Work](https://github.com/iotaledger/tips/pull/81)       | Dynamically adapt the PoW difficulty                                                                                                             | Standards | Core      | Withdrawn          | **Stardust**   |

## Need help?

If you want to get involved in the community, need help getting started, have any issues related to the repository or just want to discuss blockchain, distributed ledgers, and IoT with other people, feel free to join our [Discord](https://discord.iota.org/).
