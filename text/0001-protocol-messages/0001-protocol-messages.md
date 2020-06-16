+ Feature name:`New Protocol Messages`
+ Start date: 2019-12-19
+ RFC PR: [iotaledger/protocol-rfcs#0001](https://github.com/iotaledger/protocol-rfcs/pull/0001)
+ Node software implementation issues: 
  - [iotaledger/iri#1072](https://github.com/iotaledger/iri/issues/1072)


# Summary
Defines the changes that were introduced during the network rewrite. [iotaledger/iri#1072](https://github.com/iotaledger/iri/issues/1072). This is mainly the introduction of new TLV (type-length-value) messages. A header was added to each message, allowing us to create different message types and support different versions of the protocol. A handshake message was also introduced to help establish manageable connections with neighbors.

Will also define the STING protocol introduced by the Hornet team. It separates between transaction requests and the transactions, allows to request milestones by index, and introduces the concept of heartbeats.

Here is a table summarizing all the new message types. The 3-6 types are part of STING:

| Type # | Message Type |
| ------ | ------------ |
|  1     | Handshake    |
|  2     | Legacy Transaction Gossip |
|  3     | Milestone Request|
|  4     | Transaction |
|  5     | Transaction Request   |
|  6     | Heartbeats            |

# Motivation

***The network rewrite change***
- Ability to kick-out a compromised/malfunctioning neighbor while preserving overall architecture performance. This means that a malfunctioning neighbor will only affect its own relationship with the node and will not affect how then node  treats other neighbors.

- Drop support for UDP which is in practice slow (due to lack of congestion control) and not so reliable. Only utilize TCP.

- Enabling possibility to enforce global and per neighbor rate limits in both ingress and egress directions. 

- Enabling prioritization of message types.

- Enabling the addition of new message types and versioning the protocol. Thus paving the way for STING.


***STING***

- Allow for faster syncing by
  - Separating between requests and transaction data.
  - Allowing to request specific milestones by index.
  - Sharing between nodes information on the milestones in their databases via heartbeats.
- Eliminates fragmentation of request messages. In the legacy gossip messages exceeded TCP's MTU of 1,500 bytes, meaning all gossip transmissions were fragmented by TCP to two packets. Now, at least the transaction requests will not be fragmented. Transaction messages are still fragmented unfortunately.




# Detailed design

## **TLV Messages - Protocol Version 1**
The network rewrite introduces a new breaking protocol between nodes which works with type-length-value (TLV) denoted messages. Meaning that each sent message is composed of a header followed by the message itself.

| Order | Name   | Length (byte) | Desc             |
| ----- | ----   | ------------- | ----                         |
|   1   | Header |   3           | Metadata of message          |
|   2   |Message |   Var         | Message itself               |

#### Header
Each message in the protocol is denoted by a 3 byte header:

| Order | Name | Length (byte) | Type              | Desc             |
| ----- | ---- | ------------- | ----------------- | ----                         |
|   1   | Type |   1           | byte              | Type of message              |
|   2   |Length|   2           |uint16 (Big Endian)| Length of message (65 KB max)|

#### Handshake
The handshake message is the first message which must be sent and received to/from a neighbor. It is used to construct the identity of the neighbor. If the advertised server socket port, coordinator address or mwm does not correspond to the receiving node’s configuration, the connection is dropped. It also sends its support for gossip protocol versions as a little-endian byte array. The nodes can use that information to know what message types can be transmitted to the peers.
Each index of a bit in the byte array corresponds to a supported gossip protocol version. If the bit on that index is turned on, then the corresponding protocol version is supported by the node. The LSB of the first byte has index 1, the LSB of the second byte has index 9, the LSB of the third byte has index 17, and so on.
For example, `[01101110, 01010001]` denotes that this node supports protocol versions 2, 3, 4, 6, 7, 9, 13 and 15. Thus, the length of the byte array depends on the number of protocol versions supported. Thanks to the `length` field given in the header, the peer can parse the array correctly.

| Order | Description                                                                                                                 | Type                       | Length (bytes)   |
| ----- | ----------------------------------------------------------------------                                                      | ----                       | ---------------  |
|  1    | Neighbor's server socket port number, range 1024-65535                                                                      | uint16 (Big Endian)        | 2                |
| 2     | Timestamp in milliseconds since Unix epoch - when the handshake packet was constructed. The node uses it to calculate the latency to/from the neighbor | uint64 (Big Endian)        | 8                |
| 3     | Neighbor's used coordinator address. Encoded with 5 trits in a byte.                                                        | byte array (`t5b1`)        | 49               |
| 4     | Own used minimum weight magnitude                                                                                           | byte                       | 1                |
| 5     | Supported protocol versions                                                                                       | byte array (Little Endian) | 1 - 32           |

#### Transaction Gossip
Contains the transaction data and a hash of a requested transaction. The data is encoded with 5 trits in a byte (`t5b1`). If the requested hash corresponds to the hash of the transaction data, the receiving node is instructed to send back a random tip.
The total size of this message varies between 341-1653 bytes due to signature message fragment compaction.

##### Signature Message Fragment Compaction
The byte encoded transaction data is truncated by removing all suffix 0 bytes (9 trytes) from the signature message fragment before transmission. This can reduce the size up to 81.7%. Spam transactions, however, can prevent this reduction easily by adding data at the end of the signature message fragment.


 
| Order | Description      | Type                    |Length (bytes)   |
| ----- | -----------      | --------------------    |---------------- |
|  1    | Transaction Data | byte array (`t5b1`)     |292 - 1604       |
|  2    | Requested Hash   | byte array (`t5b1`)     | 49              |


## STING - Protocol Version 2

STING is an extension to the IOTA protocol. It breaks the transaction gossip into Transaction and Transaction Request messages. Besides that it adds the Milestone Request and Heartbeat messages.

#### Milestone Request

Requests a milestones by the index. Expects to receive in response the milestone bundle for the specified index.

| Order | Description                            | Type                    | Length (bytes)   |
| ----- | -----------                            | ---------------------   |----------------  |
|  1    | Milestone Index                        | uint32 (Big Endian)     |     4            |

#### Transaction 

Broadcasts the transaction trytes with a 5 trits to a byte encoding. Does not expect any message in return. The size remains dynamic to due to signature message compaction.


| Order | Description      | Type                | Length (bytes)   |
| ----- | -----------      | ------------------- | ---------------- |
|  1    | Transaction Data | byte array (`t5b1`) |292 - 1604       |

#### Heartbeat

Relays the node's last and first solid milestone indexes. The first one is the milestone where the node pruned at. If no pruning was done on the node it will start on the global snapshot milestone.  This is used to help a syncing node know what data their neighbor has.
The heartbeat message will be sent to the peers every time the node solidifies on a new milestone or when pruning is done.

|Order | Description                 | Type                   | Length (bytes) |
| ---- | ------------------          | -------------------    | -------------  | 
|  1   | Last solid milestone index  | uint32 (Big Endian)    | 4 |
|  2   | First solid milestone index | unit32 (Big Endian)    | 4 |
