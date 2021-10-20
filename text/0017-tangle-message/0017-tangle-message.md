+ Feature name: `tangle-message`
+ Start date: 2020-07-28
+ RFC PR: [iotaledger/protocol-rfcs#0017](https://github.com/iotaledger/protocol-rfcs/pull/0017)

# Summary

The Tangle is the graph data structure behind IOTA. In the current IOTA protocol, the vertices of the Tangle are represented by transactions. This document proposes an abstraction of this idea where the vertices are generalized *messages*, which then contain the transactions or other structures that are processed by the IOTA protocol. Just as before, each message directly approves other messages, which are known as _parents_.

The messages can contain payloads. These are core payloads that will be processed by all nodes as part of the IOTA protocol. Some payloads may have other nested payloads embedded inside. Hence, parsing is done layer by layer.

# Motivation

To better understand this layered design, consider the Internet Protocol (IP), for example: There is an Ethernet frame that contains an IP payload. This in turn contains a TCP packet that encapsulates an HTTP payload. Each layer has a certain responsibility and once this responsibility is completed, we move on to the next layer.

The same is true with how messages are parsed. The outer layer of the message enables the mapping of the message to a vertex in the Tangle and allow us to perform some basic validation. The next layer may be a transaction that mutates the ledger state, and one layer further may provide some extra functionality on the transactions to be used by applications.

By making it possible to add and exchange payloads, an architecture is being created that can easily be extended to accommodate future needs.

# Detailed design

## Data types

The following are data types that will be used when we specify fields in the message and payloads.

| Name         | Description                                                                   |
| ------------ | ----------------------------------------------------------------------------- |
| uint8        | An unsigned 8-bit integer encoded in Little Endian.                           |
| uint16       | An unsigned 16-bit integer encoded in Little Endian.                          |
| uint32       | An unsigned 32-bit integer encoded in Little Endian.                          |
| uint64       | An unsigned 64-bit integer encoded in Little Endian.                          |
| ByteArray[N] | A static size byte array of length N.                                         |
| ByteArray    | A dynamically sized byte array. A leading uint32 denotes its length in bytes. |

## Structure

### Message ID

The *Message ID* is the [BLAKE2b-256](https://tools.ietf.org/html/rfc7693) hash of the entire serialized message.

### Serialized Layout

<table>
  <tr>
    <th>Name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Network ID</td>
    <td>uint64</td>
    <td>Network identifier. This field denotes whether the message was meant for mainnet, testnet, or a private net. It also marks what protocol rules apply to the message. Usually, it will be set to the first 8 bytes of the BLAKE2b-256 hash of the concatenation of the network type and the protocol version string.</td>
  </tr>
  <tr>
    <td>Parents Count</td>
    <td>uint8</td>
    <td>The number of messages that are directly approved.</td>
  </tr>
  <tr>
    <td valign="top">Parents <code>anyOf</code></td>
    <td colspan="2">
      <details>
        <summary>Parent</summary>
        <blockquote>
          References another directly approved message.
        </blockquote>
        <table>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
          <tr>
            <td>Message ID</td>
            <td>ByteArray[32]</td>
            <td>The Message ID of the parent.</td>
          </tr>
        </table>
      </details>
    </td>
  </tr>
  <tr>
    <td>Payload Length</td>
    <td>uint32</td>
    <td>The length of the following payload in bytes. A length of 0 means no payload will be attached.</td>
  </tr>
  <tr>
    <td valign="top">Payload <code>oneOf</code></td>
    <td colspan="2">
      <details open="true">
        <summary>Generic Payload</summary>
        <blockquote>
          An outline of a generic payload
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
    <td>Nonce</td>
    <td>uint64</td>
    <td>The nonce which lets this message fulfill the PoW requirement.</td>
  </tr>
</table>


## Message validation

The following criteria defines whether the message passes the syntactical validation:

- The total message size must not exceed 32 KiB (32 * 1024 bytes).
- Parents:
  - `Parents Count` must be at least 1 and not larger than 8.
  - `Parents` must be sorted in lexicographical order.
  - Each `Message ID` must be unique.
- Payload (if present):
  - `Payload Type` must match one of the values described under [Payloads](#Payloads).
  - `Data fields` must be correctly parsable in the context of the `Payload Type`.
  - The payload itself must pass syntactic validation.
- `Nonce` must be a valid solution of the message PoW as described in [RFC-0024](https://iotaledger.github.io/protocol-rfcs/0024-message-pow/0024-message-pow.html).
- There must be no trailing bytes after all message fields have been parsed.

## Payloads

While messages without a payload, i.e. `Payload Length` set to zero, are valid, such messages do not contain any information. As such, messages usually contain a payload. The detailed specification of each payload type is out of scope of this RFC. The following table lists all currently specified payloads that can be part of a message and links to their specification. The _indexation payload_ will be specified here as an example:

| Payload Name | Type Value | RFC                                                                                                                                                            |
| ------------ | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Transaction  | 0          | [RFC-0018 (draft)](https://github.com/luca-moser/protocol-rfcs/blob/signed-tx-payload/text/0000-signed-transaction-payload/0000-signed-transaction-payload.md) |
| Milestone    | 1          | [RFC-0019 (draft)](https://github.com/jakubcech/protocol-rfcs/blob/jakubcech-milestonepayload/text/0019-milestone-payload/0019-milestone-payload.md)           |
| Indexation   | 2          | [RFC-0017](#Indexation-payload)                                                                                                                                |

### Indexation payload

This payload allows the addition of an index to the encapsulating message, as well as some arbitrary data. Nodes will expose an API that allows to query messages by index.

The structure of the indexation payload is as follows:

| Name         | Type                    | Description                                                   |
| ------------ | ----------------------- | ------------------------------------------------------------- |
| Payload Type | uint32                  | Set to <b>value 2</b> to denote an <i>Indexation Payload</i>. |
| Index Length | uint16                  | The length of the following index field in bytes.             |
| Index        | ByteArray[Index Length] | The index key of the message                                  |
| Data         | ByteArray               | Binary data.                                                  |

Note that `Index` field must be at least 1 byte and not longer than 64 bytes for the payload to be valid. The `Data` may have a length of 0.

## Example

Below is the full serialization of a valid message with an indexation payload. The index is the "IOTA" ASCII string and the data is the "hello world" ASCII string. Bytes are expressed as hexadecimal numbers.

- Network ID (8-byte): `0000000000000000` (0)
- Parents Count (1-byte): `02` (2)
- Parents (64-byte):
  - `210fc7bb818639ac48a4c6afa2f1581a8b9525e20fda68927f2b2ff836f73578`
  - `db0fa54c29f7fd928d92ca43f193dee47f591549f597a811c8fa67ab031ebd9c`
- Payload Length (4-byte): `19000000` (25)
- Payload (25-byte):
  - Payload Type (4-byte): `02000000` (2)
  - Index Length (2-byte): `0400` (4)
  - Index (4-byte): `494f5441` ("IOTA")
  - Data (15-byte):
    - Length (4-byte): `0b000000`
    - Data (11-byte): `68656c6c6f20776f726c64` ("hello world")
- Nonce (8-byte): `ce6d000000000000` (28110)

# Rationale and alternatives

Instead of creating a layered approach, we could have simply created a flat transaction message that is tailored to mutate the ledger state, and try to fit all the use cases there. For example, with the indexed data use case, we could have filled some section of the transaction with that particular data. Then, this transaction would not correspond to a ledger mutation but instead only carry data.

This approach seems less extensible. It might have made sense if we had wanted to build a protocol that is just for ledger mutating transactions, but we want to be able to extend the protocol to do more than that.
