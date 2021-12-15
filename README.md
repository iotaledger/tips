# Tangle Improvement Proposal (TIP) Repository

TIPs are improvement proposals for bettering the IOTA technology stack.

Building the IOTA ecosystem is a community effort, therefore we welcome anyone to propose, discuss and debate ideas that will later become formalized TIPs.

## Propose new ideas

Do you have an idea how to improve the IOTA technology stack?
- Head over to the [discussions](https://github.com/iotaledger/tips/discussions) page to browse already submitted ideas or share yours!
- Once your idea is discussed, you can submit a draft TIP ([template here](./tip-template.md)) as a PR to the repository.
- You will receive feedback from the TIP Editors and review from core devs.
- Once accepted, your TIP is merged as Draft.
- It is your responsibility to drive its implementation and to present a clear plan on how the new feature will be adopted by the network.
- Once implementation is ready and testing yields satisfactory result, the TIP becomes Proposed.
- Proposed TIPs that are supported by majority of the network become Active.

You may find more information about the TIP Process in [TIP-1](./tips/TIP-0001/tip-0001.md).

## List of TIPs

| # | Title | Description | Type | Layer | Status |
| --- | --- | ----------- | ---- | ----- | ------ |
| 1 | [TIP Process](tips/TIP-0001/tip-0001.md)| Purpose and guidelines of the contribution framework | Process | - | Active |
| 2 | [White Flag Ordering](tips/TIP-0002/tip-0002.md)| Mitigate conflict spamming by ignoring conflicts | Standards | Core | Active |
| 3 | [Uniform Random Tip Selection](tips/TIP-0003/tip-0003.md)| Perform fast tip-selection to increase message throughput | Standards | Core | Active |
| 4 | [Milestone Merkle Validation](tips/TIP-0004/tip-0004.md)| Add Merkle tree hash to milestone for local ledger state verification | Standards | Core | Active |
| 5 | [Binary To Ternary Encoding](tips/TIP-0005/tip-0005.md)| Define the conversion between binary and ternary data | Standards | Core | Active |
| 6 | [Tangle Message](tips/TIP-0006/tip-0006.md)| Generalization of the Tangle transaction concept | Standards | Core | Active |
| 7 | [Transaction Payload](tips/TIP-0007/tip-0007.md)| UTXO-based transaction structure | Standards | Core | Active |
| 8 | [Milestone Payload](tips/TIP-0008/tip-0008.md)| Coordinator issued milestone structure with Ed25519 authentication | Standards | Core | Active |
| 9 | [Local Snapshot File Format](tips/TIP-0009/tip-0009.md)| File format to export/import ledger state | Standards | Interface | Active |
| 10 | [Mnemonic Ternary Seed](tips/TIP-0010/tip-0010.md)| Represent ternary seed as a mnemonic sentence | Standards | IRC | Obsolete |
| 11 | [Bech32 Address Format](tips/TIP-0011/tip-0011.md)| Extendable address format supporting various signature schemes and address types | Standards | Interface | Active |
| 12 | [Message PoW](tips/TIP-0012/tip-0012.md)| Define message proof-of-work as a means to rate-limit the network | Standards | Core | Active |
| 13 | [REST API](tips/TIP-0013/tip-0013.md)| Node REST API routes and objects in OpenAPI Specification | Standards | Interface | Active |
| 14 | [Ed25519 Validation](tips/TIP-0014/tip-0014.md)| Adopt [ZIP-215](https://zips.z.cash/zip-0215) to explicitly define Ed25519 validation criteria | Standards | Core | Draft |

## Need help?

If you want to get involved in the community, need help getting started, have any issues related to the repository or just want to discuss blockchain, distributed ledgers, and IoT with other people, feel free to join our [Discord](https://discord.iota.org/).