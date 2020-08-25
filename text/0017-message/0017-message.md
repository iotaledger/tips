+ Feature name: `tangle-message`
+ Start date: 2020-07-28
+ RFC PR: [iotaledger/protocol-rfcs#0017](https://github.com/iotaledger/protocol-rfcs/pull/0017)

# Summary

A message is the object nodes gossip around in the network. It always references two other messages that are known as `parents`. It is stored as a vertex on the tangle data structure that the nodes maintain.

The messages will contain payloads. Some of them will be core payloads that will be processed by all nodes as part of the core protocol. Some of them will be community payloads that will enable to build new functionality on top of the tangle.

Some payloads may have other nested payloads embedded inside.
So upon parsing it is done layer by layer.



# Motivation

To better understand this layered design, consider the internet protocol for example. There is an Ethernet frame, that contains an IP payload. This in turn contains a TCP packet that encapsulates an HTTP payload. Each layer has a certain responsibility, once this responsibility is completed, we move on to the next layer.

The same goes with how we parse messages. The outer layer of the message enables us to map the message to a vertex in the Tangle and perform some basic validation. The next layer may be a transaction that mutates the ledger state. The next layer may provide some extra functionality on the transactions to be used by applications.

By making it possible to add and exchange payloads, we are creating an architecture that can be easily extended to accommodate future needs.


# Detailed design

### Data Types

The following are data types that we will use when we specify fields in the message and payloads.

| Name   | Description   |
| ------ | ------------- |
| varint | An unsigned numerical value using a dynamic amount of bytes encoded in Little Endian. Evaluate by inspecting the MSB of the first byte. If it is `0` stop. If it is `1` go to the next byte. Continue applying this rule until you reach a byte with MSB `0`. Transform each byte to a 7-bit bit sequence by stripping the MSBs from each byte. Reverse the order of the 7 bit groups (Little Endian). Concatenate all the bits and evaluate as an unsigned integer. [It is similar to how it is done in Protocol Buffers](https://developers.google.com/protocol-buffers/docs/encoding). We must add [validation rules](#Message-Validation) that ensure that the varint is not malleable, and it is limited in size. |
| uint64  | An unsigned 64 bit integer encoded in Little Endian.
| ByteArray    | A dynamic size byte array. It is a prefixed by a `varint` that indicates the number of bytes in the array. The following bytes are simply the content of the array.
| ByteArray[N] | A static size array of size N. Since the size is expected, no need to prefix with a varint   |


### Message ID
The message ID will be the `BLAKE2b-256` hash of the byte contents of the message. It should be used by the nodes to index the messages and by external APIs.


### Message Structure

<table>
    <tr>
        <th>Name</th>
        <th>Type</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Version</td>
        <td>varint</td>
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
        <td>The Message ID of the second <i>Message</i> we reference.</td>
    </tr>
    <tr>
        <td>Payload Length</td>
        <td>varint</td>
        <td> The length of the Payload. Since its type may be unknown to the node it must be declared in advanced.</td>
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
                        <td>varint</td>
                        <td>
                            The type of the payload. It will instruct the node how to parse the fields that follow. Types in the range of 0-127 are "core types" that all nodes are expected to know.
                        </td>
                    </tr>
                    <tr>
                        <td>Data Fields</td>
                        <td>ANY</td>
                        <td>A sequence of fields, where the structure depends on <code>payload type</code>.</td>
                    </tr>
                    <tr>
                        <td>Nested Payload (Optional)</td>
                        <td> Payload</td>
                        <td> Some payloads support nesting other payloads inside of them.</td>
                    </tr>
                </table>
            </details>
    <tr>
        <td>Nonce</td>
        <td>uint64</td>
        <td>The nonce which lets this message fulfill the Proof-of-Work requirement.</td>
    </tr>
</table>

### Message PoW Hash

This hash is computed by converting all the messages raw bytes into trytes with `b1t6`. Then hash the result with Curl-P-81. The result will be used to verify the proof-of-work done on the message. This will be used for spam protection.

Ideally, the Message ID would also be used for the PoW, but then the Hash function used for the Message ID must also be used for the PoW. Separating them gives us much more flexibility with the PoW method and we can even apply the current Curl based PoW mechanism.

### Message Validation

A message is considered valid, if the following syntactic rules are met:

1. The message length must not exceed X [tbd] bytes.
2. Varint fields must adhere to the following rules:
    * *Malleability protection:* No `0x80` or `0x00` trailing bytes. Take for example the following 3 byte varint: `0x8F8000`. 
    In order to parse it we look at its bits: 
    `1000 1111 1000 0000 0000 0000`.
    First we strip the msbs:
    `000 1111 000 0000 000 0000`
    Then we reverse the groups of 7 bits (Little Endian):
    `000 0000 000 0000 000 1111`
    Then we concatenate all the bits to finally get:
    `1111`
    So the varint `0x0F` equals to `0x8F8000`, but is encoded with different bytes.
    * *Size Protection*: The varint must not be more than 10 bytes long. A 10 byte varint can encompass all the range of `uint64`. In case of an overflow above the `uint64` range the message is invalid.
3. When we are done parsing the message there shouldn't be any trailing bytes left that were not parsed.
4. If the `payload type` is in the core payload range (0-127) and the node is familiar with it, or if it is in the range of 128-16383. The upper limit of 16383 is the maximal value of a 2 byte varint, and it should suffice for all the optional payload types we need.
5. If the Message PoW Hash will contain at least the number of trailing 0 trits the node defines as required.

### Payloads

Each message will contain a payload. The specification of the payloads is out of scope of this RFC. Below is a table of the currently specified core payloads with a link to their specifications. The `Unsigned Payload` will be specified here as an example.

| Payload Name                              |   Type Value |
| ---------------------------------------   | -----------  | 
|  Signed Transaction                       |     0        |
|  Milestone                                |     1        |
|  [Unsigned Data](#Unsigned-Data-Payload)  |     2        |
| Signed Data                               |     3        |
| Indexation                                |     4        |

### Unsigned Data Payload

To make the Payload concept clear we will define the `unsigned data payload`. As the name suggests it simply allows to add arbitrary data to a message. A message that has been attached to the tangle and approved by a milestone has useful properties: You can verify that the content of the data did not change, and you can ascertain the approximate time it was published by checking the approving milestone. For example, one can record a hash of a text document on the tangle with such a payload. When a third party requests a proof that the document was published at a certain time and was not changed, one can point them to them to the message containing the `unsigned data payload` with the hash.

The structure of the payload is simple:



| Name             | Type     | Description               |
| --------         | -------- | -----------               |
| Payload Type     | varint   | Must be set to **2**      |
| Data             | ByteArray| The data we are attaching |

There are no validation rules for the payload. Message validation rules suffice here.



# Rationale and alternatives

Instead of creating a layered approach, we could have simply created a flat `transaction message`, that is tailored for mutating the ledger state, and try to fit all the use cases there. For example with the unsigned data use-case, we could have filled some section of the transaction with the data. Then via a flag in the transaction we could have instructed to not pass this transaction to the service that attempts to mutate the ledger state.

This approach seems less extensible. It might have made sense if we wanted to build a protocol that is just for ledger mutating transactions, but we want to be able to extend the protocol to do more than that.

# Unresolved questions

- What should be the maximum length of the message?
- Better protection with PoW? how does the length of the message and type of payloads should affect difficulty?
- How should we pad the message to fit it into CURL for PoW?
- How should we pad the input for CURL? One proposal is to go with padding method 2 that is described here https://en.wikipedia.org/wiki/ISO/IEC_9797-1#Padding
- Do we want to move away from using CURL for PoW in the future?
