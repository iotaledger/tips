+ Feature name: `tangle-message`
+ Start date: 2020-07-28
+ RFC PR: [iotaledger/protocol-rfcs#0017](https://github.com/iotaledger/protocol-rfcs/pull/0017)

# Summary

A message is the object nodes gossip around in the network. It always references two other messages that are known as `parents`. It is stored as a vertex on the tangle data structure that the nodes maintain.

The messages will contain payloads. Some of them will be core payloads that will be processed by all nodes as part of the core protocol. Some of them will be community payloads that will enable to build new functionality on top of the tangle. Some payloads may have other nested payloads embedded inside.
So upon parsing it is done layer by layer.

# Motivation

To better understand this layered design, consider the internet protocol for example. There is an Ethernet frame, that contains an IP payload. This in turn contains a TCP packet that encapsulates an HTTP payload. Each layer has a certain responsibility, once this responsibility is completed, we move on to the next layer.

The same goes with how we parse messages. The outer layer of the message enables us to map the message to a vertex in the Tangle and perform some basic validation. The next layer may be a transaction that mutates the ledger state. The next layer may provide some extra functionality on the transactions to be used by applications.

By making it possible to add and exchange payloads, we are creating an architecture that can be easily extended to accommodate future needs.

# Detailed design

### Data types

The following are data types that we will use when we specify fields in the message and payloads.

| Name   | Description   |
| ------ | ------------- |
| uint8  | An unsigned 8 bit integer encoded in Little Endian. |
| uint16  | An unsigned 16 bit integer encoded in Little Endian. |
| uint32  | An unsigned 32 bit integer encoded in Little Endian. |
| uint64  | An unsigned 64 bit integer encoded in Little Endian. |
| ByteArray[N] | A static size array of size N.   |
| ByteArray | A dynamically sized array. A uint32 denotes its length.   |
| string | A dynamically sized array of an UTF-8 encoded string. A uint16 denotes its length.   |


### Message ID
The message ID will be the `BLAKE2b-256` hash of the byte contents of the message. It should be used by the nodes to index the messages and by external APIs.


### Message structure

<table>
    <tr>
        <th>Name</th>
        <th>Type</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Version</td>
        <td>uint8</td>
        <td>The message version. The schema specified in this RFC is for version <strong>1</strong> only. </td>
    </tr>
    <tr>
        <td>Parent1 (<code>trunk</code>)</td>
        <td>ByteArray[32]</td>
        <td>The Message ID of the first <i>Message</i> it references.</td>
    </tr>
    <tr>
        <td>Parent2 (<code>branch</code>)</td>
        <td>ByteArray[32]</td>
        <td>The Message ID of the second <i>Message</i> it references.</td>
    </tr>
    <tr>
        <td>Payload Length</td>
        <td>uint32</td>
        <td> The length of the Payload. Since its type may be unknown to the node it must be declared in advanced. 0 length means no payload will be attached.</td>
    </tr>
    <tr>
        <td colspan="1">
            Payload
        </td>
        <td colspan="2">
            <details open="true">
                <summary>Generic Payload</summary>
                <blockquote>
                An outline of a general payload
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
                            The type of the payload. It will instruct the node how to parse the fields that follow. Types in the range of 0-127 are "core types" that all nodes are expected to know.
                        </td>
                    </tr>
                    <tr>
                        <td>Data Fields</td>
                        <td>ANY</td>
                        <td>A sequence of fields, where the structure depends on <code>payload type</code>.</td>
                    </tr>
                </table>
            </details>
    <tr>
        <td>Nonce</td>
        <td>uint64</td>
        <td>The nonce which lets this message fulfill the Proof-of-Work requirement.</td>
    </tr>
</table>

### Message validation

A message is considered valid, if the following syntactic rules are met:

1. The message length must not exceed X [tbd] bytes.
2. When we are done parsing the message there shouldn't be any trailing bytes left that were not parsed.
3. If the `payload type` is in the core payload range (0-127) and the node is familiar with it, or if it is above this range.
4. If the [Message PoW Hash](https://github.com/Wollac/protocol-rfcs/blob/message-pow/text/0024-message-pow/0024-message-pow.md) will contain at least the number of trailing 0 trits the node defines as required.

### Payloads

A message may contain a payload. The specification of the payloads is out of scope of this RFC. Below is a table of the currently specified core payloads with a link to their specifications. The `indexation payload` will be specified here as an example.

| Payload Name                              |   Type Value |
| ---------------------------------------   | -----------  | 
|  [Signed Transaction](https://github.com/luca-moser/protocol-rfcs/blob/signed-tx-payload/text/0000-signed-transaction-payload/0000-signed-transaction-payload.md)                       |     0        |
|  [Milestone Draft](https://github.com/jakubcech/protocol-rfcs/blob/jakubcech-milestonepayload/text/0019-milestone-payload/0019-milestone-payload.md)                                |     1        |
|  [Indexation Payload](#indexation-payload)  |     2        |

### Indexation payload

To make the Payload concept clear we will define the `indexation payload`. As the name suggests it allows to add an index to the encapsulating message, as well as some arbitrary data. Nodes will expose an API, that will enable to query messages by the index.
Adding those capabilities may open nodes to DOS attack vectors:
1. Proliferation of index keys that may blow up the node's DB
2. Proliferation of messages associated with the same index

Node implementations may provide weak guarantees regarding the completion of indexes to address the above scenarios. 

Besides the index, the payload will also have a data field.
  A message that has been attached to the tangle and approved by a milestone has useful properties: You can verify that the content of the data did not change, and you can ascertain the approximate time it was published by checking the approving milestone. If the payload will be incorporated under
  the `signed transaction payload`, the content will be signed as well.


The structure of the payload is simple:

| Name             | Type          | Description               |
| --------         | -----------   | -----------               |
| Payload Type     | uint32        | Must be set to **2**      |
| Index            | string     | The index key of the message |
| Data             | ByteArray     | Data we are attaching    |

Note that `index` and `data` may both have a length of 0.
There are no validation rules for the payload. Message validation rules suffice here.

### Serialization Example

Below is a serialized valid message with the indexation payload. The index is the "SPAM" ASCII string and the message is the "Hello Iota"
ASCII string. The [Message PoW Hash](https://github.com/Wollac/protocol-rfcs/blob/message-pow/text/0024-message-pow/0024-message-pow.md) should have
  14 trailing zeroes. Bytes are expressed as hexadecimal numbers. 

[Version] **`01`** [Parent 1] `F532A53545103276B46876C473846D98648EE418468BCE76DF4868648DD73E5D` [Parent 2] `78D546B46AEC4557872139A48F66BC567687E8413578A14323548732358914A2` [Payload Length]
*`0C`*[Payload Type]**`02`**[Index] *`04`*`9A52` [Data]*`0A`*`48656c6c6f20496f7461`[Nonce]`dc293f3333333333`

# Rationale and alternatives

Instead of creating a layered approach, we could have simply created a flat `transaction message`, that is tailored for mutating the ledger state, and try to fit all the use cases there. For example with the unsigned data use-case, we could have filled some section of the transaction with the data. Then via a flag in the transaction we could have instructed to not pass this transaction to the service that attempts to mutate the ledger state.

This approach seems less extensible. It might have made sense if we wanted to build a protocol that is just for ledger mutating transactions, but we want to be able to extend the protocol to do more than that.

# Unresolved questions

- What should be the maximum length of the message?
