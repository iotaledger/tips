+ Feature name:`New Protocol Messages`
+ Start date: 2019-12-19
+ RFC PR: [iotaledger/protocol-rfcs#0001](https://github.com/iotaledger/protocol-rfcs/pull/0001)
+ Node software implementation issues: 
  - [iotaledger/iri#1072](https://github.com/iotaledger/iri/issues/1072)


# Summary
Defines the changes that were introduced during the network rewrite. [iotaledger/iri#1072](https://github.com/iotaledger/iri/issues/1072). This is mainly the introduction of new TLV (type-length-value) messages. A header was added to each message, allowing us to create different message types and support different versiond of the protocol. A handshake message was also inroduced to help establish manageable connections with neighbors.

Will also define the STING protocol introduced by the Hornet team. It seperates between transaction requests and broadcasts, allows to request milestones by index, and introduces the concept of heartbeats.

Here is a table summarizing all the new message types. The 3-6 types are part of STING:

| Type # | Message Type |
| ------ | ------------ |
|  1     | Handshake    |
|  2     | Legacy Tx Gossip |
|  3     | Milestone Request|
|  4     | Transaction Broadcast |
|  5     | Transaction Request   |
|  6     | Heartbeats            |

# Motivation

***The network rewrite change***
1. Ability to kick-out a compromised/malfunctioning neighbor while preserving overall architecture performance. This means that a malfunctioning neighbor will only affect its own relationship with the node and will not affect how then node  treats other neighbors

2. Drop support for UDP which is in practice slow (due to lack of congestion control) and not so reliable. Only utilize TCP.

3. Enabling possibility to enforce global and per neighbor rate limits in both ingress and egress direction. 

5. Enabling prioritization of message types.

6. Enabling the addition of new message types and versioning the protocol. Thus paving the way for STING.


***STING (Still TrInary Network Gossip)***

1. Allow for faster syncing by
    a. Seperating between requests and broadcasts of transactions.
    b. Allowing to request specific milestones by index.
    c. Sharing between nodes information on the milestones in their databases via Heartbeats
    
2. Eliminates fragmentation of request messages.




# Detailed design

## **TLV Messages - Protocol Version 1**
The network rewrite introduces a new breaking protocol between nodes which works with type-length-value (TLV) denoted messages. Meaning that each sent message is composed of a header follwed by the message itself.

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
The handshake message is the first message which must be sent and received to/from a neighbor. It is used to construct the identity of the neighbor. If the advertised server socket port, coordinator address or mwm does not correspond to the receiving node’s configuration, the connection is dropped. It also sends its support for gossip protocol versions as a little-endian byte array. The nodes can use that information to know what message types can be relayed to the peers.
Each index of a bit in the byte array corresponds to a supported gossip protocol version. If the bit on that index is turned on, then the corresponding protocol version is supported by the node. The LSB of the first byte has index 1, the LSB of the second byte has index 9, the LSB of the third byte has index 17, and so on.
For example, `[01101110, 01010001]` denotes that this node supports protocol versions 2, 3, 4, 6, 7, 9, 13 and 15. Thus, the length of the byte array depends on the number of protocol versions supported. Thanks to the `length` field given in the header, the peer can parse the array correctly.

| Order | Description                                                                                                                 | Type                       | Length (bytes)   |
| ----- | ----------------------------------------------------------------------                                                      | ----                       | ---------------  |
|  1    | Neighbor's server socket port number, range 1024-65535                                                                      | uint16 (Big Endian)        | 2                |
| 2     | Timestamp in milliseconds - when the handshake packet was constructed, in order to display the latency to/from the neighbor | uint64 (Big Endian)        | 8                |
| 3     | Neighbor's used coordinator address. Encoded in bytes with `t5b1`.                                                          | byte array                 | 49               |
| 4     | Own used minimum weight magnitude                                                                                           | byte                       | 1                |
| 5     | Supported supported protocol versions                                                                                       | byte array (Little Endian) | var, max size:32 |

#### Transaction Gossip
Contains the tx data and a hash of a requested tx. Encodes 5 trits in a byte. If the requested hash corresponds to the hash of the tx data, the receiving node is instructed to send back a random tip.
The total size of this message varies between 341-1653 bytes due to signature message fragment compaction.

##### Signature Message Fragment Compaction
The byte encoded tx data is truncated by removing all suffix 0 bytes (9 trytes) from the signature message fragment before transmission. This can reduce the size up to 81.7%. Spam transactions, however, can prevent this reduction easily by adding data at the end of the signature message fragment.


 
| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  1    | Transaction Data | 292 - 1604       |
|  2    | Requested Hash   |  49              |


## STING (Still TrInary Network Gossip) - Protocol Version 2

STING is an extension to the IOTA protocol. It breaks the transaction gossip into Transaction Broadcast and Transaction Request. Besides that it adds the Milestone Request and Heartbeat messages.

#### Milestone Request

Requests a range of milestones by index. Expects to receive in response the milestone bundle for the specified index.

| Order | Description                            | Length (bytes)   |
| ----- | -----------                            | ---------------- |
|  1    | Milestone Index encoded in Big Endian  | 4                |

#### Transaction Broadcast

Broadcasts the transaction trytes with a 5 trits to a byte encoding. Doesn't expect any message in return. The size remains dynamic to due to signature message compaction.


| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  1    | Transaction Data | 292 - 1604       |

####  Transaction Request

Request a transaction by its 81 trytes hash encoded in bytes.

| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  1    | Transaction Hash | 49               |


#### Heartbeat

Relays the neighbor last and first solid milestone indexes. The first one depends on what the pruning. This is used to help a syncing node know what data their neighbor has.

|Order | Description                       | Length (bytes) |
| ---- | -------------                     | -------------  | 
|  1   | First solid milestone index       | 4  (Big Endian)|
|  2   | Last solid milestone index        | 4 (Big Endian) |
