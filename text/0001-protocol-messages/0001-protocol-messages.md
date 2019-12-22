+ Feature name:`New Protocol Messages`
+ Start date: 2019-12-19
+ RFC PR: [iotaledger/protocol-rfcs#0001](https://github.com/iotaledger/protocol-rfcs/pull/0001)
+ Node software implementation issues: 
  - [iotaledger/iri#1072](https://github.com/iotaledger/iri/issues/1072)


# Summary
Defines the changes that were introduced during the network rewrite. [iotaledger/iri#1072](https://github.com/iotaledger/iri/issues/1072). This is mainly the introduction of new TLV (type-length-value) messages. A header was added to each message, allowing us to create different message types and support different versiond of the protocol. A handshake message was also inroduced to help establish manageable connections with neighbors.

Will also define the STING protocol introduced by the Hornet team. It seperates between transaction requests and broadcasts, allows to request milestones by index, and introduced the concept of heartbeats.

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
    
2. Eliminates fragmentation of request messages.

3. Allows for heartbeats [?]



# Detailed design

## **TLV Messages - Protocol Version 1**
The network rewrite introduces a new breaking protocol between nodes which works with type-length-value (TLV) denoted messages. Meaning that each sent message is composed of a header follwed by the message itself.

| Order | Name   | Length (byte) | Desc             |
| ----- | ----   | ------------- | ----                         |
|   1   | Header |   3           | Type of message              |
|   2   |Message |   2           | Length of message (65 KB max)|

#### Header
Each message in the protocol is denoted by a 3 byte header:

| Order | Name | Length (byte) | Desc             |
| ----- | ---- | ------------- | ----                         |
|   1   | Type |   1           | Type of message              |
|   2   |Length|   2           | Length of message (65 KB max)|

#### Handshake
The handshake message is the first message which must be sent and received to/from a neighbor. It is used to construct the identity of the neighbor. If the advertised server socket port, coordinator address or mwm does not correspond to the receiving node’s configuration, the connection is dropped.


| Order | Description            | Length (bytes) |
| ----- | -----------            | -------------- |
|  1   | Neighbor's server socket port number, range 1024-65535| 2 |
| 2     | Timestamp in milliseconds - when the handshake packet was constructed, in order to display the latency to/from the neighbor | 8|
| 3     | Neighbor's used coordinator address  | 49
| 4     | Own used minimum weight magnitude    | 1


#### Transaction Gossip
Contains the tx data and a hash of a requested tx. Encodes 5 trits in a byte. If the requested hash corresponds to the hash of the tx data, the receiving node is instructed to send back a random tip.
The total size of this message varies between 341-1653 bytes due to signature message fragment compaction.

##### Signature Message Fragment Compaction
The byte encoded tx data is truncated by removing all suffix 0 bytes (9 trytes) from the signature message fragment before transmission. This can reduce the size up to 81.7%. Spam transactions, however, can prevent this reduction easily by adding data at the end of the signature message fragment).


 
| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  1    | Transaction Data | 292 - 1604       |
|  2    | Requested Hash   |  49              |


## STING (Still TrInary Network Gossip) - Protocol Version 2

STING is an extension to the IOTA protocol. It breaks the transaction gossip into Transaction Broadcast and Transaction Request. Besides that it adds the Milestone Request and Heartbeat messages.

#### Milestone Request

Requests a milestone by index. Expects to receive in response the milestone bundle for the specified index. [Or maybe it is just the tail tx?]

| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  1    | Milestone Index  | 4                |

#### Transaction Broadcast

Broadcasts the transaction trytes with a 5 trits to a byte encoding. Doesn't expect any message in return. The size remains dynamic to due to signature message compaction.


| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  1    | Transaction Data | 292 - 1604       |

####  Transaction Request

Request a transaction by its 81 trytes hash encoded in bytes.

| Order | Description      | Length (bytes)   |
| ----- | -----------      | ---------------- |
|  2    | Transaction Data | 292 - 1604       |


#### Heartbeat

[Used for DNS Resolution and measuring the neighbor's latency?]



# Unresolved questions

- Versioning, how should we version STING changes. Should we have a version number for each new message type? This will allow future node implementations to only support STING partly. For example, I am not sure that every node implementation wants to implement heartbeat.
- Heartbeats messages - I assume it was designed as described in https://docs.google.com/document/d/1aTHukFFEFTDAwjOX25Zt0tA2EmgdnKQtJ8Nx1fWMnO4/edit#heading=h.44l5znw27eob. But frankly, I don't really know (apologies for not digging in the code). I am also not sure that they are neccessary, even though I acknowledge they can be useful. Still I want some feedback from the Hornet team to how they are structured and how often they are sent.

- For milestone request I am assuming that Hornet sends all the transactions of the milestone bundle? However, it is also possible to send the tail.. So what is the current behavior? I think the correct behavior would be to send the entire bundle.
