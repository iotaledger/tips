+ Feature name: `Milestone Payload`
+ Start date: 2020-07-28
+ RFC PR: [iotaledger/protocol-rfcs#0015](https://github.com/iotaledger/protocol-rfcs/pull/19)
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
- The Ed25519 signature function takes a Ed25519 private key, a sequnce of bytes of arbitrary size and produces an Ed25519 signature of length 64 bytes. The given sequence of bytes should then be internally hashed (using sha512) by the same function.
- The Ed25519 verification function takes a public key, a sequnce of bytes of arbitrary size, a Ed25519 signature, and returns true/false based on the signature validity.

To generate a valid milestone, the Coordinator *MUST*: 
1. Generate a *Message* as defined in [RFC-0017 (draft)](https://github.com/GalRogozinski/protocol-rfcs/blob/message/text/0017-message/0017-message.md).
2. Generate a new [milestone payload](#Milestone-payload) without filling the signature field.
3. Sign the serialized bytes given by the concatenation of the following fields:
    - Version, Parent1, Parent2, Payload Length of the Message;
    - Payload Type, Index Number, Timestamp, Inclusion Merkle Proof of the Milestone Payload.
4. Fill the signature field of the milestone payload with the generated signature.
5. Perform the PoW over the Message to compute the value for the Nonce field.

To verify a given milestone, a node *MUST*:
- Verify the validity of the Message containing the Milestone Payload as in [RFC-0017 (draft)](https://github.com/GalRogozinski/protocol-rfcs/blob/message/text/0017-message/0017-message.md).
- The payload type *MUST* be 1.
- The milestone payload must consume the entire byte array the Payload Length field in the Message defines.
- Verify the milestone signature against the Coordinator public key by using the exact same ByteArray used to sign the milestone.
- Validate Inclusion Merkle Proof as described in [RFC-0012](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0012-milestone-merkle-validation/0012-milestone-merkle-validation.md).

# Milestone payload

| Field Name             | Type            | Description                                                                                                                                                                                                                                                                                             |
| ---------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Payload Type           | varint          | Must be set to **1**.                                                                                                                                                                                                                                                                                   |
| Index Number           | varint          | The index number of the milestone.                                                                                                                                                                                                                                                                      |
| Timestamp              | uint64          | The Unix timestamp at which the milestone was issued. The unix timestamp is specified in seconds.                                                                                                                                                                                                       |
| Inclusion Merkle Proof | Array<byte>[64] | Specifies the merkle proof which is computed out of all the tail transaction hashes of transactions which the mutated ledger state with this milestone. ([RFC-0012](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0012-milestone-merkle-validation/0012-milestone-merkle-validation.md)) |
| Signature              | Array<byte>[64] | The signature signing the entire message excluding the nonce and the signature itself.                                                                                                                                                                                                                  |

# Rationale and alternatives

Instead of going with EdDSA we could have choosen ECDSA. Both algorithms are well supported and widespread. However, signing with ECDSA requires fresh randomness while EdDSA does not. Morevoer, we could have used a commit-reveal mechanism to update and commit the Coordinator public key at each next milestone. This method would make a quantum-based attack aimed at braking the "current" Coordinator private-key more difficult. On the other hand, key management as well as verification of the milestone chain would become more complex.

# Unresolved questions

- Should we add support for multi-signature or multi-stage signature? Could that be a desired feature from a devOps perspective?
- Are we sure we want to lose quantum-robustness? We could have used a hash-based signature scheme, such as [XMSS](https://tools.ietf.org/html/rfc8391) or [LMS](https://tools.ietf.org/html/rfc8554) that provide quantum robustness at the price of increasing both communication and computation overhead. For more detail, please refer to this [document](https://docs.google.com/document/d/15_FkOhHFR4arxBBl07H_ETUGjPbf5jlJOiyYwZ7zKOg/edit?usp=sharing).
- Do we want to pick Ed25519 or Ed448? They provide a security level of 128-bit and 224-bit respectively. Size of both private and public keys are of 32 or 57 bytes depending on the curve used. Similarly, the signature size is of 64 or 114 bytes. Ed25519 has a better library-wise support with respect to Ed448.
- Should we add a Network ID field to the payload? If yes, is the ID a string or a uint64?
