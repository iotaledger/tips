+ Feature name: `transaction-payload`
+ Start date: 2020-07-10
+ RFC PR: [iotaledger/protocol-rfcs#18](https://github.com/iotaledger/protocol-rfcs/pull/18)
+ Recent updates:
    + [iotaledger/protocol-rfcs#0040](https://github.com/iotaledger/protocol-rfcs/pull/40) Update Payload Layout and Validation for [New Output Types](https://github.com/iotaledger/protocol-rfcs/pull/38)

# Summary

In the current IOTA protocol, transactions are grouped into so-called bundles to assure that they can only be confirmed as one unit. This RFC proposes a new UTXO-based transaction structure containing all the inputs and outputs of a transfer. Specifically, this RFC defines a transaction payload for the _messages_ described in the IOTA protocol [RFC-0017](https://iotaledger.github.io/protocol-rfcs/0017-tangle-message/0017-tangle-message.html).

# Motivation

Currently, the vertices of the Tangle are represented by transactions, where each transaction defines either an input or output. A grouping of those input/output transaction vertices makes up a bundle which transfers the given values as an atomic unit (the entire bundle is applied or none of it). An applied bundle consumes the input transactions' funds and creates the corresponding deposits into the output transactions' target addresses. Furthermore, additional meta transactions can be part of the bundle to carry parts of the signature which do not fit into a single input transaction.

The bundle concept has proven to be very challenging in practice because of the following issues:
* Since the data making up the bundle is split across multiple vertices, it complicates the validation of the entire transfer. Instead of being able to immediately tell whether a bundle is valid or not, a node implementation must first collect all parts of the bundle before any actual validation can happen. This increases the complexity of the node implementation.
* Reattaching the tail transaction of a bundle causes the entire transfer to be reapplied.
* Due to the split across multiple transaction vertices and having to do PoW for each of them, a bundle might already be lazy in terms of where it attaches, reducing its chances to be confirmed.

To fix the problems mentioned above and to create a more flexible transaction structure, the goal is to achieve a self-contained transaction structure defining the data of the entire transfer as a payload to be embedded into a message.

The new transaction structure should fulfil the following criteria:
* Support for Ed25519 (and thus reusable addresses).
* Support for adding new types of signature schemes, addresses, inputs, and outputs as part of protocol upgrades.
* Self-contained, as in being able to validate the transaction immediately after receiving it.
* Enable unspent transaction outputs (UTXO) as inputs instead of an account based model.

# Detailed design

## UTXO

The *unspent transaction output* (UTXO) model defines a ledger state where balances are not directly associated to addresses but to the outputs of transactions. In this model, transactions reference outputs of previous transactions as inputs, which are consumed (removed) to create new outputs. A transaction must consume all the funds of the referenced inputs.

Using a UTXO based model provides several benefits:
* Parallel validation of transactions.
* Easier double-spend detection, since conflicting transactions would reference the same UTXO.
* Replay-protection which is important when having reusable addresses. Replaying the same transaction would manifest itself as already being applied or existent and thus not have any impact.
* Technically seen, balances are no longer associated to addresses which raises the level of abstraction and thus enables other types of outputs with particular unlock criteria.

Within a transaction using UTXOs, inputs and outputs make up the to-be-signed data of the transaction. The section unlocking the inputs is called the *unlock block*. An unlock block may contain a signature proving ownership of a given input's address and/or other unlock criteria.

The following image depicts the flow of funds using UTXO:

![UTXO flow](img/utxo.png)

## Structure

### Serialized Layout

A <i>Transaction Payload</i> is made up of two parts:
1. The <i>Transaction Essence</i> part which contains the inputs, outputs and an optional embedded payload.
2. The <i>Unlock Blocks</i> which unlock the <i>Transaction Essence</i>'s inputs. In case the unlock block contains a
   signature, it signs the Blake2b-256 hash of the serialized <i>Transaction Essence</i> part.

All values are serialized in little-endian encoding. In contrast to the [current IOTA protocol](https://github.com/iotaledger/protocol-rfcs/pull/18)
inputs and outputs are encoded as lists, which means that they can contain duplicates and may not be sorted.

A [Blake2b-256](https://tools.ietf.org/html/rfc7693) hash of the entire serialized data makes up
<i>Transaction Payload</i>'s ID.

Following table structure describes the entirety of a <i>Transaction Payload</i>'s serialized form.
* Data Type Notation, see [RFC-0017](https://iotaledger.github.io/protocol-rfcs/0017-tangle-message/0017-tangle-message.html#data-types)
* <details>
    <summary>Subschema Notation</summary>
    <table>
        <tr>
            <th>Name</th>
            <th>Description</th>
        </tr>
        <tr>
            <td><code>oneOf</code></td>
            <td>One of the listed subschemas.</td>
        </tr>
        <tr>
            <td><code>optOneOf</code></td>
            <td>Optionally one of the listed subschemas.</td>
        </tr>
        <tr>
            <td><code>anyOf</code></td>
            <td>Any (one or more) of the listed subschemas.</td>
        </tr>
    </table>
  </details>
* New output types and unlock blocks are discussed in detail in [RFC-38](https://github.com/iotaledger/protocol-rfcs/pull/38),
  but they are mentioned in the payload structure to help the reader understand their context.

<p></p>

<table>
  <tr>
    <th>Name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Payload Type</td>
    <td>uint32</td>
    <td>
      Set to <strong>value 0</strong> to denote a <i>Transaction Payload</i>.
    </td>
  </tr>
  <tr>
    <td valign="top">Essence <code>oneOf</code></td>
    <td colspan="2">
      <details open="true">
        <summary>Transaction Essence</summary>
        <blockquote>
          Describes the essence data making up a transaction by defining its inputs, outputs and an optional payload.
        </blockquote>
        <table>
          <tr>
            <td><b>Name</b></td>
            <td><b>Type</b></td>
            <td><b>Description</b></td>
          </tr>
          <tr>
            <td>Transaction Type</td>
            <td>uint8</td>
            <td>
              Set to <strong>value 0</strong> to denote a <i>Transaction Essence</i>.
            </td>
          </tr>
          <tr>
            <td>Inputs Count</td>
            <td>uint16</td>
            <td>The number of input entries.</td>
          </tr>
          <tr>
            <td valign="top">Inputs <code>anyOf</code></td>
            <td colspan="2">
              <details>
                <summary>UTXO Input</summary>
                <blockquote>
                  Describes an input which references an unspent transaction output to consume.
                </blockquote>
                <table>
                  <tr>
                    <td><b>Name</b></td>
                    <td><b>Type</b></td>
                    <td><b>Description</b></td>
                  </tr>
                  <tr>
                    <td>Input Type</td>
                    <td>uint8</td>
                    <td>
                      Set to <strong>value 0</strong> to denote an <i>UTXO Input</i>.
                    </td>
                  </tr>
                  <tr>
                    <td>Transaction ID</td>
                    <td>ByteArray[32]</td>
                    <td>The BLAKE2b-256 hash of the transaction payload containing the referenced output.</td>
                  </tr>
                  <tr>
                    <td>Transaction Output Index</td>
                    <td>uint16</td>
                    <td>The output index of the referenced output.</td>
                  </tr>
                </table>
              </details>
            </td>
          </tr>
          <tr>
            <td>Outputs Count</td>
            <td>uint16</td>
            <td>The number of output entries.</td>
          </tr>
          <tr>
            <td valign="top">Outputs <code>anyOf</code></td>
            <td colspan="2">
              <details>
                <summary>SimpleOutput</summary>
                <blockquote>
                  Describes a deposit to a single address which is unlocked via a signature.
                </blockquote>
              </details>
              <details>
                <summary>ExtendedOutput</summary>
                <blockquote>
                  Describes a deposit to a single address. The output might contain optional feature
                  blocks and native tokens.
                </blockquote>
              </details>
              <details>
                <summary>AliasOutput</summary>
                <blockquote>
                  Describes an alias account in the ledger.
                </blockquote>
              </details>
              <details>
                <summary>FoundryOutput</summary>
                <blockquote>
                  Describes a foundry that controls supply of native tokens.
                </blockquote>
              </details>
              <details>
                <summary>NFTOutput</summary>
                <blockquote>
                  Describes a unique, non-fungible token deposit to a single address.
                </blockquote>
              </details>
            </td>
          </tr>
          <tr>
            <td>Payload Length</td>
            <td>uint32</td>
            <td>The length in bytes of the optional payload.</td>
          </tr>
          <tr>
            <td valign="top">Payload <code>optOneOf</code></td>
            <td colspan="2">
              <details>
                <summary>Generic Payload</summary>
                <blockquote>
                  An outline of a generic payload.
                </blockquote>
                <table>
                  <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Description</th>
                  </tr>
                  <tr>
                    <td>Payload Type</td>
                    <td>uint32</td>
                    <td>
                      The type of the payload. It will instruct the node how to parse the fields that follow.
                    </td>
                  </tr>
                  <tr>
                    <td>Data Fields</td>
                    <td>ANY</td>
                    <td>A sequence of fields, where the structure depends on <code>Payload Type</code>.</td>
                  </tr>
                </table>
              </details>
          <tr>
        </table>
      </details>
    </td>
  </tr>
  <tr>
    <td>Unlock Blocks Count</td>
    <td>uint16</td>
    <td>The number of unlock block entries. It must match the field <code>Inputs Count</code>.</td>
  </tr>
  <tr>
    <td valign="top">Unlock Blocks <code>anyOf</code></td>
    <td colspan="2">
      <details>
        <summary>Signature Unlock Block</summary>
        <blockquote>
          Defines an unlock block containing a signature unlocking input(s).
        </blockquote>
        <table>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
          <tr>
            <td>Unlock Type</td>
            <td>uint8</td>
            <td>
              Set to <strong>value 0</strong> to denote a <i>Signature Unlock Block</i>.
            </td>
          </tr>
          <tr>
            <td valign="top">Signature <code>oneOf</code></td>
            <td colspan="2">
              <details>
                <summary>Ed25519 Signature</summary>
                <table>
                  <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Description</th>
                  </tr>
                  <tr>
                    <td>Signature Type</td>
                    <td>uint8</td>
                    <td>
                      Set to <strong>value 0</strong> to denote an <i>Ed25519 Signature</i>.
                    </td>
                  </tr>
                  <tr>
                    <td>Public key</td>
                    <td>ByteArray[32]</td>
                    <td>The Ed25519 public key of the signature.</td>
                  </tr>
                  <tr>
                    <td>Signature</td>
                    <td>ByteArray[64]</td>
                    <td>The Ed25519 signature signing the Blake2b-256 hash of the serialized <i>Transaction Essence</i>.</td>
                  </tr>
                </table>
              </details>
            </td>
          </tr>
        </table>
      </details>
      <details>
        <summary>Reference Unlock Block</summary>
        <blockquote>
          References a previous unlock block, where the same unlock block can be used for multiple inputs.
        </blockquote>
        <table>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
          <tr>
            <td>Unlock Type</td>
            <td>uint8</td>
            <td>
              Set to <strong>value 1</strong> to denote a <i>Reference Unlock Block</i>.
            </td>
          </tr>
          <tr>
            <td>Reference</td>
            <td>uint16</td>
            <td>Represents the index of a previous unlock block.</td>
          </tr>
        </table>
      </details>
      <details>
        <summary>Alias Unlock Block</summary>
        <blockquote>
          Points to the unlock block of a consumed alias output.
        </blockquote>
        <table>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
          <tr>
            <td>Unlock Type</td>
            <td>uint8</td>
            <td>
              Set to <strong>value 2</strong> to denote an <i>Alias Unlock Block</i>.
            </td>
          </tr>
          <tr>
            <td>Alias Reference Unlock Index</td>
            <td>uint16</td>
            <td>Index of input and unlock block corresponding to an alias output.</td>
          </tr>
        </table>
      </details>
      <details>
        <summary>NFT Unlock Block</summary>
        <blockquote>
          Points to the unlock block of a consumed NFT output.
        </blockquote>
        <table>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
          <tr>
            <td>Unlock Type</td>
            <td>uint8</td>
            <td>
              Set to <strong>value 3</strong> to denote a <i>NFT Unlock Block</i>.
            </td>
          </tr>
          <tr>
            <td>NFT Reference Unlock Index</td>
            <td>uint16</td>
            <td>Index of input and unlock block corresponding to an NFT output.</td>
          </tr>
        </table>
      </details>
    </td>
  </tr>
</table>

### Transaction Parts

In general, all parts of a <i>Transaction Payload</i> begin with a byte describing the type of the given part to keep
the flexibility to introduce new types/versions of the given part in the future.

#### Transaction Essence Data

The <i>Transaction Essence</i> of a <i>Transaction Payload</i> carries the inputs, outputs, and an optional payload.
The <i>Transaction Essence</i> is an explicit type and therefore starts with its own <i>Transaction Essence Type</i>
byte which is of value 0.

##### Inputs

The <i>Inputs</i> part holds the inputs to consume, respectively, to fund the outputs of the
<i>Transaction Essence</i>. There is only one type of input as of now, the <i>UTXO Input</i>. In the future, more types
of inputs may be specified as part of protocol upgrades.

Each input must be accompanied by a corresponding <i>Unlock Block</i> at the same index in the <i>Unlock Blocks</i>
part of the <i>Transaction Payload</i>.

If multiple inputs can be unlocked through the same <i>Unlock Block</i>, then the given <i>Unlock Block</i> only needs
to be specified at the index of the first input which gets unlocked by it.

Subsequent inputs which are unlocked through the same data must have a <i>Reference Unlock Block</i>,
<i>Alias Unlock Block</i> or <i>NFT Unlock Block</i> depending on the unlock mechanism, pointing to the index of a
previous <i>Unlock Block</i>. This ensures that no duplicate data needs to occur in the same transaction.

###### UTXO Input

A <i>UTXO Input</i> is an input which references an unspent output of a previous transaction. This UTXO is uniquely
defined by the _Transaction ID_ of that transaction together with corresponding output index. Each <i>UTXO Input</i>
must be accompanied by an <i>Unlock Block</i> that is allowed to unlock the output the <i>UTXO Input</i> is referencing.

Example:
If the input references an output to an Ed25519 address, then the corresponding unlock block must be of type
<i>Signature Unlock Block</i> holding an Ed25519 signature.

##### Outputs

The <i>Outputs</i> part holds the outputs that are created by this <i>Transaction Payload</i>. The following output
types are supported:

###### SimpleOutput

Formerly known as <i>SigLockedSingleOutput</i>, the <i>SimpleOutput</i> defines an output (with a certain amount) to a
single target address which is unlocked via a signature proving ownership over the given address. This output supports
addresses of different types.

###### ExtendedOutput

An output to a single target address that may carry native tokens and optional feature blocks. Defined in
[RFC-0038](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#extended-output).

###### AliasOutput

An output that represents an alias account in the ledger. Defined in
[RFC-0038](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#alias-output).

###### FoundryOutput

An output that represents a token foundry in the ledger. Defined in
[RFC-0038](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#foundry-output).

###### NFTOutput

An output that represents a non-fungible token in the ledger. Defined in
[RFC-0038](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#nft-output).

##### Payload

The  _Transaction Essence_ itself can contain another payload as described in general in [RFC-0017](https://iotaledger.github.io/protocol-rfcs/0017-tangle-message/0017-tangle-message.html).
The [semantic validity](#semantic-validation) of the encapsulating _Transaction Payload_ does not have any impact on
the payload.

The following table lists all the payload types that can be nested inside a _Transaction Essence_ as well as links to
the corresponding specification:

| Name       | Type Value | RFC                                                                                                                    |
| ---------- | ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| Indexation | 2          | [RFC-0017](https://iotaledger.github.io/protocol-rfcs/0017-tangle-message/0017-tangle-message.html#indexation-payload) |

#### Unlock Blocks

The <i>Unlock Blocks</i> part holds the unlock blocks unlocking inputs within a <i>Transaction Essence</i>. The
following types of unlock blocks are supported:

<table>
    <tr>
        <td><b>Name</b></td>
        <td><b>Type</b></td>
        <td><b>Description</b></td>
    </tr>
    <tr>
        <td>Signature Unlock Block</td>
        <td>0</td>
        <td>An unlock block holding a signature unlocking one or more inputs.</td>
    </tr>
    <tr>
        <td>Reference Unlock Block</td>
        <td>1</td>
        <td>An unlock block which must reference a previous unlock block which unlocks also the input at the same index as this <i>Reference Unlock Block</i>.</td>
    </tr>
    <tr>
        <td>Alias Unlock Block</td>
        <td>2</td>
        <td>An unlock block which must reference a previous unlock block which unlocks the alias that the input is locked to.</td>
    </tr>
    <tr>
        <td>NFT Unlock Block</td>
        <td>3</td>
        <td>An unlock block which must reference a previous unlock block which unlocks the NFT that the input is locked to.</td>
    </tr>
</table>

##### Signature Unlock Block

A <i>Signature Unlock Block</i> defines an <i>Unlock Block</i> which holds a signature signing the BLAKE2b-256 hash of
the <i>Transaction Essence</i> (including the optional payload).

##### Reference Unlock Block

A <i>Reference Unlock Block</i> defines an <i>Unlock Block</i> which references a previous <i>Unlock Block</i> (which
must not be another <i>Reference Unlock Block</i>). It **must** be used if multiple inputs can be unlocked via the same
<i>Unlock Block</i>.

Example:
Consider a <i>Transaction Essence</i> containing the <i>UTXO Inputs</i> 0, 1 and 2, where 0 and 2 are both spending
outputs belonging to the same Ed25519 address A and 1 is spending from a different address B. This results in the
following structure of the <i>Unlock Blocks</i> part:

| Index | Unlock Block                                                                             |
| ----- | ---------------------------------------------------------------------------------------- |
| 0     | A _Signature Unlock Block_ holding the Ed25519 signature for address A.                  |
| 1     | A _Signature Unlock Block_ holding the Ed25519 signature for address B.                  |
| 2     | A _Reference Unlock Block_ which references 0, as both require the same signature for A. |

##### Alias Unlock Block

An <i>Alias Unlock Block</i> defines an <i>Unlock Block</i> which references a previous <i>Unlock Block</i>
corresponding to the alias that the input is locked to. Defined in
[RFC-0038](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#alias-locking--unlocking).

##### NFT Unlock Block

An <i>NFT Unlock Block</i> defines an <i>Unlock Block</i> which references a previous <i>Unlock Block</i> corresponding
to the NFT that the input is locked to. Defined in
[RFC-0038](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#nft-locking--unlocking).

### Validation

A <i>Transaction Payload</i> has different validation stages, since some validation steps can only be executed at the
point when certain information has (or has not) been received. We therefore distinguish between syntactic and semantic
validation.

The different output types and optional output feature blocks introduced by [RFC-0038](https://github.com/iotaledger/protocol-rfcs/pull/38)
add extra constraints to transaction validation rules, but since these are specific to the given outputs and features,
they are discussed for each [output types](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#output-design)
and [feature block types](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#optional-output-features)
separately.

#### Syntactic Validation

Syntactic validation is checked as soon as the transaction data has been received in its entirety. It validates the
structure but not the signatures of the transaction. If the transaction does not pass this stage, it must not be
broadcast further and can be discarded right away.

The following criteria defines whether the transaction passes the syntactic validation:
* `Transaction Essence Type` value must be 0, denoting an `Transaction Essence`.
* Inputs:
    * `Inputs Count` must be 0 < x ≤ `Max Inputs Count`.
    * At least one input must be specified.
    * `Input Type` value must be 0, denoting an `UTXO Input`.
    * `UTXO Input`:
        * `Transaction Output Index` must be 0 ≤ x < `Max Outputs Count`.
        * Every combination of `Transaction ID` + `Transaction Output Index` must be unique in the list of inputs.
* Outputs:
    * `Outputs Count` must be 0 < x ≤ `Max Outputs Count`.
    * At least one output must be specified.
    * `Output Type` must denote a `SimpleOutput`, `ExtendedOutput`, `AliasOutput`, `FoundryOutput` or `NFTOutput`.
    * Output must fulfill the [dust protection requirements.](https://github.com/iotaledger/protocol-rfcs/pull/39)
    * Output is syntactically valid based on its type.
    * Accumulated output balance must not exceed the total supply of tokens `2'779'530'283'277'761`.
* `Payload Length` must be 0 (to indicate that there's no payload) or be valid for the specified payload type.
* `Payload Type` must be one of the supported payload types if `Payload Length` is not 0.
* `Unlock Blocks Count` must match the amount of inputs. Must be 0 < x ≤ `Max Inputs Count`.
* `Unlock Block Type` must either be 0, 1, 2 or 3, denoting a `Signature Unlock Block`, a `Reference Unlock block`, an
  `Alias Unlock Block` or an `NFT Unlock Block`.
* `Signature Unlock Blocks` must define a `Ed25519 Signature`.
* A `Signature Unlock Block` unlocking multiple inputs must only appear once (be unique) and be positioned at the same
  index of the first input it unlocks. All other inputs unlocked by the same `Signature Unlock Block` must have a
  companion `Reference Unlock Block` at the same index as the corresponding input which points to the origin
  `Signature Unlock Block`.
* `Reference Unlock Blocks` must specify a previous `Unlock Block` which is not of type `Reference Unlock Block`. The
  referenced index must therefore be < the index of the `Reference Unlock Block`.
* `Alias Unlock Blocks` must specify a previous `Unlock Block` which unlocks the alias the input is locked to. The
  referenced index must be < the index of the `Alias Unlock Block`.
* `NFT Unlock Blocks` must specify a previous `Unlock Block` which unlocks the NFT the input is locked to. The
  reference index must be < the index of the `NFT Unlock Block`.
* Given the type and length of the information, the <i>Transaction Payload</i> must consume the entire byte array for
  the `Payload Length` field in the <i>Message</i> it defines.

#### Semantic Validation

The Semantic validation of a _Transaction Payload_ is performed when its encapsulating message is confirmed by a
milestone. The semantic validity of transactions depends on the order in which they are processed. Thus, it is necessary
that all the nodes in the network perform the checks in the same order, no matter the order in which the transactions
are received. This is assured by using the White-Flag ordering as described in [RFC-005](https://iotaledger.github.io/protocol-rfcs/0005-white-flag/0005-white-flag.html#deterministically-ordering-the-tangle).

Processing transactions according to the White-Flag ordering enables users to spend UTXOs which are created in the same
milestone confirmation cone, as long as the spending transaction comes after the funding transaction in the
aforementioned White-Flag order. In this case, it is recommended that users include the _Message ID_ of the funding
transaction as a parent of the message containing the spending transaction.

The following criteria defines whether the transaction passes the semantic validation:
1. Each input must reference a valid UTXO, i.e. the output referenced by the input's `Transaction ID` and
   `Transaction Output Index` is known (booked) and unspent.
2. The transaction must spend the entire balance, i.e. the sum of the `Amount` fields of all the UTXOs referenced by
   inputs must match the sum of the `Amount` fields of all outputs.
3. The transaction is balanced in terms of native tokens, meaning the amount of native tokens present in inputs equals
   to that of outputs. Otherwise, the foundry outputs controlling outstanding native token balances must be present in
   the transaction. The validation of the foundry output(s) determines if the outstanding balances are valid.
4. The UTXOs the transaction references must be unlocked based on the transaction context, that is the
   <i>Transaction Payload</i> plus the list of consumed UTXOs. (output syntactic unlock validation in transaction
   context)
5. The UTXOs the transaction references must be unlocked with respect to the
   [milestone index and Unix timestamp of the confirming milestone](https://github.com/jakubcech/protocol-rfcs/blob/jakubcech-milestonepayload/text/0019-milestone-payload/0019-milestone-payload.md#structure). (output semantic unlock validation in transaction context)
6. The outputs of the transaction must pass additional validation rules defined by the present
   [output feature blocks](https://github.com/lzpap/protocol-rfcs/blob/master/text/0038-output-types-for-tokenization-and-sc/0038-output-types-for-tokenization-and-sc.md#optional-output-features).
7. The sum of all `Native Token Counts` in the transaction plus `Outputs Count` is ≤
   `Max Native Token Count Per Output`.
8. Each unlock block must be valid with respect to the UTXO referenced by the input of the same index:
    * If it is a _Signature Unlock Block_:
      * The `Signature Type` must match the `Address Type` of the address unlocking the UTXO,
      * the BLAKE2b-256 hash of `Public Key` must match the unlocking `Address` of the UTXO and
      * the `Signature` field must contain a valid signature for `Public Key`.
    * If it is a _Reference Unlock Block_, the referenced _Signature Unlock Block_ must be valid with respect to the UTXO.
    * If it is an _Alias Unlock Block_:
      * The address unlocking the UTXO must be an _Alias Address_.
      * The referenced _Unlock Block_ unlocks the alias defined by the unlocking address of the UTXO.
   * If it is an _NFT Unlock Block_:
     * The address unlocking the UTXO must be a _NFT Address_.
     * The referenced _Unlock Block_ unlocks the NFT defined by the unlocking address of the UTXO.

If a _Transaction Payload_ passes the semantic validation, its referenced UTXOs must be marked as spent and its new
outputs must be created/booked in the ledger. The _Message ID_ of the message encapsulating the processed payload then
also becomes part of the input for the White-Flag Merkle tree hash of the confirming milestone ([RFC-0012](https://iotaledger.github.io/protocol-rfcs/0012-milestone-merkle-validation/0012-milestone-merkle-validation.html)).

Transactions that do not pass semantic validation are ignored. Their UTXOs are not marked as spent and their outputs
are not booked in the ledger.

## Miscellaneous

### Transaction timestamps

Since transaction timestamps – whether they are signed or not – do not provide any guarantee of correctness, they have been left out of the _Transaction Payload_. Applications relying on some notion of time for transactions can use the local solidification time or the global timestamp of the confirming milestone ([RFC-0019](https://iotaledger.github.io/protocol-rfcs/0019-milestone-payload/0019-milestone-payload.html)).

### Address reuse

While, in contrast to Winternitz one-time signatures (W-OTS), producing multiple Ed25519 signatures for the same private key and address does not decrease its security, it still drastically reduces the privacy of users. It is thus considered best practice that applications and services create a new address per deposit to circumvent these privacy issues.

In essence, Ed25519 support allows for smaller transaction sizes and to safely spend funds which were sent to an already used deposit address. Ed25519 addresses are not meant to be used like email addresses. See this [Bitcoin wiki article](https://en.bitcoin.it/wiki/Address_reuse) for further information.

# Drawbacks

* The new transaction format is the core data type within the IOTA ecosystem. Changing it means that all projects need to accommodate it, including wallets, web services, client libraries and applications using IOTA in general. It is not possible to keep these changes backwards compatible, meaning that all nodes must upgrade to further participate in the network.
* Additionally, local snapshots can no longer be represented by a list of addresses and their balances, since the ledger is now made up of the UTXOs on which the actual funds reside. Therefore, local snapshot file schemes have to be adjusted to incorporate the transaction hashes, output indices, and then the destination addresses including the balances.

# Rationale and alternatives

* Introducing this new transaction structure allows for extensions in the future, to accommodate new requirements. With the support for Ed25519 addresses/signatures, transaction size is drastically reduced and allows for safe re-signing in case of address reuse. Due to the switch to a complete binary transaction, the transaction size is reduced even further, saving network bandwidth and processing time.
* Other transaction structures have been considered but they would have misused existing transaction fields to accommodate for new features, instead of putting them into a proper descriptive structure. Additionally, those ideas would not have been safe against replay attacks, which deems reusing the old transaction structure, for example for Ed25519 addresses/signatures, as infeasible.
* Not switching to the new transaction structure described in this RFC would have led to more people losing funds because of W-OTS address reuse and it would prevent extending the IOTA protocol further down the line.
