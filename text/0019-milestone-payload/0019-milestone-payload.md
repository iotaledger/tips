+ Feature name: `Milestone Payload`
+ Start date: 2020-07-28
+ RFC PR: [iotaledger/protocol-rfcs#0019](https://github.com/iotaledger/protocol-rfcs/pull/19)
+ Author: Angelo Capossele

# Summary

In the IOTA protocol, nodes use the milestones issued by the Coordinator to reach a consensus on which transactions are confirmed. 
This RFC proposes a new milestone payload as well as the EdDSA signature algorithm as a replacement to the current Coordinator digital signature scheme to authenticate the issued milestones.

# Motivation
The current signature scheme used to authenticate milestones issued by the Coordinator has been designed with ternary and quantum robustness in mind. Due to the switch to binary, the new message layout as well as the upcoming Coordicide (i.e., Coordinator removal), we now have the opportunity to revisit such a mechanism and replace it with a more simple, well-vetted and standardized one. Although the proposed digital signature scheme, EdDSA, does not provide quantum robustness, its simplicity and easier key-managment make it a good candidate for the time being.

# Detailed design

The EdDSA signature algorithm in its variants **Ed25519** and **Ed448** (providing a security level of 128-bit and 224-bit respectively) are technically described in the IRTF [RFC 8032](https://tools.ietf.org/html/rfc8032).
Size of both private and public keys are of 32 or 57 bytes depending on the curve used. Similarly, the signature size is of 64 or 114 bytes.

- The Ed25519 key generation can be fed with a given random sequence of bytes (i.e., seed) of length 32 bytes. Output of the key generation is the pair of private and public keys. Note that the generation of the seed is out of the scope of this RFC, but in general, any cryptographic pseudo-random function (PRF) would suffice.
- The Ed25519 signature function takes a Ed25519 private key, a sequence of bytes of arbitrary size and produces an Ed25519 signature of length 64 bytes. The given sequence of bytes should then be internally hashed (using sha512) by the same function.
- The Ed25519 verification function takes a public key, a sequence of bytes of arbitrary size, a Ed25519 signature, and returns true/false based on the signature validity.

In order to increase the security of the design, a milestone can optionally be independently signed by multiple keys at once. These keys should be operated by detached signature provider services, running on independent infrastructure elements, thus mitigating the risk of an attacker having access to all the key material necessary for forging milestones. While the Coordinator takes responsibility of forming Milestone Payload Messages, it delegates signing to these providers through an ad-hoc RPC connector. Mutual authentication should be enforced between the Coordinator and the signature providers: a [client-authenticated TLS handshake](https://en.wikipedia.org/wiki/Transport_Layer_Security#Client-authenticated_TLS_handshake) scheme is advisable. To increase the flexibility of the mechanism, nodes can be configured to require a quorum of valid signatures to consider a milestone as genuine.

In addition, a key rotation policy can also be enforced, using milestone indexes as ranges for a key to be applicable to a specific milestone. Accordingly, nodes need to maintain a list of public keys mapped to specific milestone index ranges. Keys should be rotated with a maximum frequency of 6 months. In order to guarantee a smooth rotation, the rotated key's expiration can be set for several indexes in the future at the time of publishing the new public key.

To generate a valid milestone, the Coordinator *MUST*: 
1. Generate a *Message* as defined in [RFC-0017 (draft)](https://github.com/GalRogozinski/protocol-rfcs/blob/message/text/0017-message/0017-message.md).
2. Generate a new [milestone payload](#Milestone-payload), specify the number of provided signatures in the signatures count field but without filling the signatures array field.
3. Serialize the bytes given by the concatenation of the following fields:
    - Version, Parent1, Parent2, Payload Length of the Message;
    - Payload Type, Index Number, Timestamp, Inclusion Merkle Proof, Signatures Count of the Milestone Payload.
4. Transmit the serialized bytes to the corresponding number of signature service providers.
    1. The signature provider service will sign the received serialized bytes as-is.
    2. The signature provider will serialize the signature bytes and return them to the Coordinator.
5. Fill the signatures array field of the milestone payload with the received signatures' bytes.
6. Perform the PoW over the Message to compute the value for the Nonce field.

To verify a given milestone, a node *MUST*:
1. Verify the validity of the Message containing the Milestone Payload as in [RFC-0017 (draft)](https://github.com/GalRogozinski/protocol-rfcs/blob/message/text/0017-message/0017-message.md).
2. The payload type *MUST* be 1.
3. The milestone payload must consume the entire byte array the Payload Length field in the Message defines.
4. Select the applicable public keys according to the milestone index, and validate the milestone signatures array by using the exact same field concatenation used to sign the milestone.
5. The amount of valid signatures in the array must be equal or greater than the required minimum configured in the node.
6. Validate Inclusion Merkle Proof as described in [RFC-0012](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0012-milestone-merkle-validation/0012-milestone-merkle-validation.md).

# Milestone payload

| Field Name             | Type            | Description                                                                                                                                                                                                                                                                                             |
| ---------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Payload Type           | uint32          | Must be set to **1**.                                                                                                                                                                                                                                                                                   |
| Index Number           | uint64          | The index number of the milestone.                                                                                                                                                                                                                                                                      |
| Timestamp              | uint64          | The Unix timestamp at which the milestone was issued. The unix timestamp is specified in seconds.                                                                                                                                                                                                       |
| Inclusion Merkle Proof | Array\<uint8\>[64] | Specifies the Merkle Proof which is computed out of all the tail transaction hashes of all the newly confirmed state-mutating bundles. ([RFC-0012](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0012-milestone-merkle-validation/0012-milestone-merkle-validation.md)) |
| Signatures Count       | uint8           | Number of signatures provided in the milestone. |
| Signatures             | Array\<Array\<uint8\>[64]\> | An array of signatures signing the entire message excluding the nonce and the signatures array itself. There are `Signatures Count` Signatures in this array. |

# Rationale and alternatives

Instead of going with EdDSA we could have chosen ECDSA. Both algorithms are well supported and widespread. However, signing with ECDSA requires fresh randomness while EdDSA does not. Moreover, we could have used a commit-reveal mechanism to update and commit the Coordinator public key at each next milestone. This method would make a quantum-based attack aimed at breaking the "current" Coordinator private-key more difficult. On the other hand, key management as well as verification of the milestone chain would become more complex.

# Unresolved questions

- Are we sure we want to lose quantum-robustness? We could have used a hash-based signature scheme, such as [XMSS](https://tools.ietf.org/html/rfc8391) or [LMS](https://tools.ietf.org/html/rfc8554) that provide quantum robustness at the price of increasing both communication and computation overhead. For more detail, please refer to this [document](https://docs.google.com/document/d/15_FkOhHFR4arxBBl07H_ETUGjPbf5jlJOiyYwZ7zKOg/edit?usp=sharing).
- Should we add a Network ID field to the payload? If yes, is the ID a string or a uint64?
