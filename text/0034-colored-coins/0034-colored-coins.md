+ Feature name: `colored-coins`
+ Start date: 2021-02-18
+ RFC PR: [iotaledger/protocol-rfcs#0034](https://github.com/iotaledger/protocol-rfcs/pull/0034)

# Summary

Colored coins are IOTA coins associated with a special color, that is a globally unique collection of bytes within the Tangle.

 - Regular IOTA coins are spent to mint colored coins. 1 IOTA corresponds to 1 newly minted Colored Coin. The amount of
   coins to mint is defined in the minting output(s) of a transaction. Once minted, the color can't be changed, and no
   more new coins can be minted with the same color.
 - Colored coins can be transferred just like IOTA coins, without transaction fees.
 - Colored coins can be destroyed  (uncolored), which essentially means that the coins lose their unique color
   attribute and become regular IOTA coins.

# Motivation

The possibility to mark a set of coins with certain information is a consequence of the UTXO model introduced in
Chrysalis Phase 2. In a UTXO output, next to the amount of coins, additional tagging information can be embedded, such
as color.

Tagging coins makes it possible to associate certain IOTA coins with real world assets, like bonds, stocks, property
rights or loyalty points. Allowing real world assets to be represented by digital tokens that are secure, transferable,
feeless and fast, opens up new use cases for the IOTA Protocol.

It will be shown how colored coins are also important to enable layer 2 smart contracts and security token frameworks.

## Use Cases

The sections below describe some, but far from all possible use cases of IOTA colored coins. It will be up to the
community and industry to find further innovative ways of utilizing the new features of the protocol.

### Utility Tokens
A utility token provides benefit to its owner by allowing them to access goods, services or products via the use of a
token. A paper based concert ticket, gift cards one collects at a coffee shop or a monthly public transportation pass
are all examples of tokens. They let one verify that they indeed have the right to claim their benefits.

Colored coins can provide the same functionality in a secure, digital world with added perks:
- Tokens can't be counterfeited.
- Tokens are held in the digital wallet of the user, the IOTA Tangle provides a decentralized administrative framework
  to distribute, transfer and manage tokens.
- Anyone can create, transfer or hold tokens in a permissionless way.
- Colored coins inherit the feeless nature of IOTA, transferring a colored coin has no costs.
- Issuers must bear the cost of acquiring the IOTA tokens to be colored. With current market price of $1.30 of MIOTA
  (17/02/2021), an issuer must spend $1.30 to buy IOTA coins for minting 1 million colored coins.
- Utility tokens can be converted to regular IOTA tokens. This is beneficial in 2 ways:
    - Once users exchange the utility tokens for a service, the service provider can easily convert the tokens to IOTA
      or re-color them to be used in another service.
    - Users holding the utility tokens can also convert them to IOTA at any point in time, although this is only
      rational behavior if the face value of the utility token in IOTA is more, than the service they are redeemable for.
- Utility tokens can be easily integrated into Firefly wallet.
- The issuer can easily monitor the distribution, usage and available supply of the utility token through examining the
  IOTA Tangle.

To summarize, utility tokens on IOTA provide a secure, convenient and cheap way to sell services, organize loyalty
programs and digitize paper based token systems.

### Security Tokens
Security tokens refer to digital tokens that represent financial assets that fall under the category of
[securities](https://en.wikipedia.org/wiki/Security_(finance)). These are tradable financial instruments that are
heavily regulated, under varying conditions based on the jurisdiction of the issuer's country.

There is a huge potential in the industry of security tokens, because they address the shortcomings of traditional securities:
- Regulatory compliance (KYC, AML, etc.) can be enforced through underlying protocol.
- Both regulators and issuers have real time data on how securities are allocated and traded in the market.
- Traditionally illiquid assets such as real estate or art can be tokenized, enabling better price discovery,
  fractional ownership and more liquidity.
- The cost of managing securities falls drastically, as the protocol can act as the managing entity.
- A security token can be traded on secondary markets 24/7.
- Security tokens can reduce the entry barriers for smaller or retail investors.

It is important to note, that a security token itself is just a claim to the underlying security, it is not the asset itself.

One of the biggest technological challenges of security token frameworks built on top of distributed ledgers is how to
enforce regulatory compliance. Smart contract platforms are well suited to solve this problem by employing autonomous
agents (smart contracts) on the base layer to manage the life cycle of security tokens.

IOTA has its smart contract solution (ISCP) on layer 2, because the base layer of the IOTA Protocol has to remain
lightweight enough to cater to the needs of the machine economy.
ISCP is suitable for advanced security tokenization, where all features of a security token can be programmed and
enforced by the smart contract itself. An issuer can control supply, regulate trading, or might even reverse transactions
if demanded by law. Of course, this is not possible on layer 1, as it would add too much complexity to the protocol.

Although, there is another way to carry out regulatory compliant security tokenization on layer 1, with the help of
colored coins. An issuer might mint and distribute security tokens as colored coins to multi-party signature addresses.
- To unlock funds, both the issuer and the user has to sign the transaction.
- Transfers to addresses that are not verified would fail to gather the signature of the issuer.
- The issuer can halt trading and enforce compliance rules since it knows the verified identities of users.
- The security tokens are still handled in a secure, decentralized and feeless infrastructure, the IOTA Tangle.

In conclusion, colored coins provide the opportunity for security tokenization on base layer with trusted issuer
platforms acting as guides, but also enable layer 2 solutions like ISCP that support full scale, customizable,
self-enforcing rules to be implemented as autonomous agents.

### Non-fungible Tokens

Digital tokens can be classified into two categories based on their nature of fungibility:
- **Fungible Tokens** are interchangeable with other tokens of the same type, as they represent the same amount of
  value. Cash or IOTA is fungible, because a $10 bill can be exchanged for two $5 bills, and 10 MIOTA is equivalent
  to 5 MIOTA + 5 MIOTA.
- **Non-fungible Tokens** on the other hand are not interchangeable, because each token has unique properties that give
  them their value.

A Non-fungible Token (NFT) can represent an artwork, a collectible or special edition item. It is essentially a digital
property right that can be traded. Some exciting use cases are:
- Crypto collectibles such as crypto kitties, fantasy football league cards, etc.
- In-game items that can be traded on secondary markets.
- Digital artwork recorded on the ledger.
- NFTs can also be used as collateral in decentralized finance.

Colored coins support on the IOTA Protocol would finally introduce the capability of creating NFTs on layer 1. A color
is a globally unique property of a minted token, therefore, if there is only one token ever minted with that particular
color, it becomes an NFT. Of course, it is fungible in the sense that it can be uncolored and used as a regular IOTA
token, but no other coin can be created with the same color, so it is a true NFT until the owner decides to destroy it.

An NFT can also be viewed as a "global identity token" that may have data associated with it.
A non-forkable (non-copyable) chain of data states can be built by attaching metadata to the transfers of the NFT on
layer 1. Therefore, it is perfectly suited for use cases such as Access, Streams or DID.

The non-fungible property of a single colored coin on layer 1 is essential for building ISCP on layer 2:
- A smart contract chain could be identified by the account holding the unique NFT of the contract chain.
  It is minted upon deployment of the chain, and can be destroyed if the chain dies.
- Smart contracts need a way of handling (user) requests atomically on layer 1. A smart contract chain has to have a
  way of administering the currently pending and completed requests. This is what we call the backlog of the smart
  contract chain. The idea is to mint a unique colored coin for each request and transfer it to the contract chain
  account. Upon completion of the request, its NFT can be destroyed with the state anchor transaction that settled the
  request.

It is important to note, that a colored coin used as an NFT has only one unique property: its color. Therefore,
advanced use cases, where a myriad of unique properties have to be associated to a single token are not supported on
layer 1, rather via ISCP on layer 2. However, if the NFT represents a property right, the original attributes of the
property could still be stored off-tangle, in a distributed registry, or in a registry smart contract.

# Detailed design

To represent colored coins in the IOTA Protocol, a new output type has to be introduced,  `SigLockedColoredOutput`.

   <summary>SigLockedColoredOutput</summary>
    <blockquote>
    Describes a colored operation to a single address which is unlocked via a signature.
    </blockquote>
    <table>
        <tr>
            <td><b>Name</b></td>
            <td><b>Type</b></td>
            <td><b>Description</b></td>
        </tr>
        <tr>
            <td>Output Type</td>
            <td>uint8</td>
            <td>
                Set to <strong>value 2</strong> to denote a <i>SigLockedColoredOutput</i>.
            </td>
			<tr>
            <td>Opcode</td>
            <td>uint8</td>
            <td>The operation performed by this <i>SigLockedColoredOutput</i> output.</td>
        </tr>
        <tr>
            <td valign="top">Address <code>oneOf</code></td>
            <td colspan="2">
				<details>
                    <summary>Ed25519 Address</summary>
                    <table>
                        <tr>
                            <td><b>Name</b></td>
                            <td><b>Type</b></td>
                            <td><b>Description</b></td>
                        </tr>
                        <tr>
                            <td>Address Type</td>
                            <td>uint8</td>
                            <td>
                                Set to <strong>value 0</strong> to denote an <i>Ed25519 Address</i>.
                            </td>
                        </tr>
                        <tr>
                            <td>Address</td>
                            <td>Array&lt;byte&gt;\[32\]</td>
                            <td>The raw bytes of the Ed25519 address which is a BLAKE2b-256 hash of the Ed25519 public key.</td>
                        </tr>
                    </table>
                </details>
            </td>
        </tr>
	        <tr>
            <td>Color</td>
            <td>Array&lt;byte&gt;[33] </td>
            <td>The color of tokens of this <i>SigLockedColoredOutput</i> output.
			</td>
        </tr>
        <tr>
            <td>Amount</td>
            <td>uint64</td>
            <td>The amount of tokens of this <i>SigLockedColoredOutput</i> output.</td>
        </tr>
    </table>

<p></p>

There are couple new concepts as compared to a `SigLockedSingleOutput`.

## Color

Colors are globally unique and are assigned to tokens upon minting. A color refers to an output in a transaction that
minted it, therefore colors are essentially `OutputIDs`. Since an `OutputID` is the combination of the `TransactionID`
and the `index of the output within the transaction`, it is possible to locate the genesis transaction of a color by
taking the first 32 bytes of it.

The zero value of a color (33 bytes that are all zero) has a distinct name, it is called `ColorIOTA`, and defines the
color of an IOTA token.

## Opcodes

Opcodes, or operation codes, define how the protocol treats the output during transaction validation and post processing.
In general, we can divide up the processing of a transaction into 3 phases:
- **Syntactical validation**: validating rules that govern the transaction layout and can be objectively decided just
  by looking at the raw transaction.
- **Semantic validation**: validation rules that are concerned with the content of the inputs, outputs and unlock blocks.
  Valid unlock blocks are a semantic check for example.
- **Post Processing**: Once both of the previous validations are passed, the created outputs need to be booked into the
  ledger. This step involves calculating the `OutputIDs`, and additionally can have other actions depending on the opcode.

In the previous version of the IOTA Protocol, opcodes did not exist, because the only operation the protocol allowed was
actually to `MOVE` tokens by unlocking them from an input and locking them into a new output.
With colored coins however, the ability to specify `MINT` operation for the creation of colors, and `UNCOLOR` operation
to destroy such colors is absolutely necessary.

Opcodes affect the 3 transaction processing stages:

### Syntactical Validation With Opcodes

The `Opcode` field of a `SigLockedColoredOutput` may only be:

- `0` to denote `MINT` operation,
- `1` to denote `MOVE` operation and
- `2` to denote `UNCOLOR` operation.

Any other value of `Opcode` is not valid, and the transaction is considered invalid.

The tuple of {`OutputType`, `Opcode`, `Address`, `Color` } has to be unique in the set of outputs, except for `MINT`.
Several `SigLockedColoredOutput`s with the `MINT` opcode and the same `Address` should be allowed, as this is the only
way to mint different colored coins to the same address in one transaction.

### Semantic Validation With Opcodes

Unlocking doesn't change, the new output type is also locked by a signature.
The same unlock rules apply to a `SigLockedColoredOutput` as to a `SigLockedSingleOutput`.

Before opcodes, a transaction was considered invalid if it spent more funds in the created outputs, than it consumed
from the unlocked inputs. With the introduction of colors and opcodes however, the amount of different colors and their
operation also has to be taken into account.

The two sides of the transaction (inputs and outputs) define a balance sheet with positive and negative sides for
different "colors". Consuming an input adds to the positive side, while creating a new output incurs a negative balance.
The sum of the two side of the balance sheet must be zero.

**Semantic Rules for consuming inputs (previously created outputs):**
- If the unlocked output is a `SigLockedSingleOutput`, it adds `amount`
  of `ColorIOTA` to the positive side.
- If the unlocked output is a `SigLockedColorOutput`, depending on the `opcode`:
    - `MINT` or `MOVE`: Adds `amount` `color` tokens to the positive side.
    - `UNCOLOR`: Adds `amount` `ColorIOTA` tokens to the positive side. Previously uncolored coins become regular IOTA
      tokens.

**Semantic Rules for creating new outputs:**
- If the created output is `SigLockedSingleOutput`, it adds `amount`
  of `ColorIOTA` to the negative side.
- If the created output is a `SigLockedColorOutput`, depending on the `opcode`:
    - `MINT`: Adds `amount` `ColorIOTA` tokens to the negative side. This is actually a demand for IOTA tokens because
      they will be colored.
    - `MOVE` or `UNCOLOR`: Adds `amount` `color` tokens to the negative side.

There can be any amount of `MINT`, `MOVE` or `UNCOLOR` `SigLockedColoredOutput`s in the transaction, as long as the
total number of outputs do not exceed `maxOutputsCount`.

### Post Processing

Previously, post processing only meant calculating the `OutputID` of the newly created outputs by taking the
`Transaction ID` + `index of the output in the transaction`, and booking them into the ledger.

With the opcodes however, there can be additional steps:
####  SigLockedSingleOutput:
- Calculate `OutputID`, the unique identifier of the output in the UTXO DAG. `OutputID` = `TransactionID` ||
  `index of the output in the transaction`.
- Book the output into the ledger.
#### SigLockedColoredOutput:
- **MINT** opcode:
    - Calculate `OutputID`, the unique identifier of the output in the UTXO DAG. `OutputID` = `TransactionID` ||
      `index of the output in the transaction`.
    - Mark the `color` of the output as `OutputID`.
    - Book the output into the ledger.
- **MOVE** opcode:
    - Calculate `OutputID`, the unique identifier of the output in the UTXO DAG. `OutputID` = `TransactionID` ||
      `index of the output in the transaction`.
    - Book the output into the ledger.
- **UNCOLOR** opcode:
    - Calculate `OutputID`, the unique identifier of the output in the UTXO DAG. `OutputID` = `TransactionID` ||
      `index of the output in the transaction`
    - Mark the `color` of the output as `ColorIOTA`. <i>This might not be necessary, as unlocking an `UNCOLOR` output
      adds `ColorIOTA` to the positive side of the balance sheet. With marking the booked output with `ColorIOTA`,
      we double enforce this rule, but also lose the information on which color it uncolored. For that, one has to
      load the transaction and observe the outputs in their original form. </i>
    - Book the output into the ledger.

### Notes
- Outputs in the serialized transaction must be in lexicographic order, therefore there can be no two transactions that
  define the same UTXO mutations while having different transaction IDs.
- Due to the ordering, any `SigLockedColoredOutput` comes after any `SigLockedSingleOutput` within the transaction.
- Due to the ordering, `MINT`, `MOVE` and `UNCOLOR` outputs are grouped together in the list of outputs, which helps to
  identify the purpose of the transaction by looking at its layout.
- One transaction might mint several coins with unique colors. The maximum amount of different colors that can be
  minted in a single transaction is exactly the maximum allowed number of outputs, that is `128`.
- One transaction might uncolor several colored coins. The maximum amount of different colors that can be uncolored in
  a single transaction is exactly the maximum allowed number of outputs, that is `128`.
- It is not possible to mint a color in a transaction and uncolor it in the same transaction, since uncoloring can only
  happen if coins with that particular color are present in list of unlocked inputs.
- The size of a `SigLockedColoredOutput` is exactly `76 bytes`, compared to the `42 bytes` size of a
  `SigLockedSingleOutput`.
- A `SigLockedColoredOutput` with `OPCODE=MOVE` and `Color=ColorIOTA` is functionally identical to a
  `SigLockedSingleOutput`, but the latter is preferable due to its smaller size.

### Dust protection

Dust protection refers to preventing the unnecessary increase of the ledger database by splitting up funds into several,
smaller outputs. Chrysalis Phase 2 introduced a new dust protection mechanism, that defines on a protocol level when
such small outputs can be accepted.
Dust protection doesn't change with the introduction of colored coins, a `SigLockedColoredOutput` is considered to be
dust if it has an `amount` that is less, than `1 Mi`.

# Drawbacks

- Increases the complexity of the transaction validating logic, however, it does not introduce additional signature
  validation overhead.
- Adds additional post processing steps for `MINT` operations.
- All client libraries have to be modified to handle colored coins, but since it is not a breaking change on client
  side, old wallets and libs would still be operational without support for colored coins.

# Rationale and alternatives

#### What other designs have been considered and what is the rationale for not choosing them?
The alternative ways of supporting colored coins is to build a scripting framework into the protocol, like bitcoin does,
or try to design an [Extended UTXO](https://iohk.io/en/research/library/papers/the-extended-utxo-model/) model. Both of
them can support a lot more functionality on protocol level, but also further increase the transaction validation logic.
The IOTA protocol has to remain lightweight enough to be the backbone of the machine economy.
### Why is this design the best in the space of possible designs?
The instruction set for programming outputs consists of 3 opcodes only, which limits the complexity of the transaction
validating logic.
The NFT capabilities of single supply colored coins makes it possible to register non-forkable data states on protocol
level.
### What is the impact of not doing this?
Without colored coins, layer 2 smart contracts would not be possible to implement.

# Unresolved questions

- Should the balance of an output actually composed of a list of colored balances? That would make it easier to
  uncolor several tokens to the same address at once, or to move several tokens to the same address.
  For minting it doesn't change anything because the color depends on the output index in the transaction, so it is not
  possible to mint several colors with one output.
