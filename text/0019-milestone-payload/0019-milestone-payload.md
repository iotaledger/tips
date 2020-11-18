+ Feature name: `milestone-payload`
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

In addition, a key rotation policy can also be enforced by limiting key validity to certain milestone intervals. Accordingly, nodes need to know which public keys are applicable for which milestone index. This can be provided by configuring a list of entries consisting of the following fields:
- _Index Range_ providing the interval of milestone indices for which this entry is valid. The interval must not overlap with any other entry.
- _Applicable Public Keys_ defining the set of valid public keys.
- _Signature Threshold_ specifying the minimum number of valid signatures. Must be at least one and not greater than the number of _Applicable Public Keys_.

## Structure

All values are serialized in little-endian encoding. The serialized form of the milestone is deterministic, meaning the same logical milestone always results in the same serialized byte sequence.

The following table structure describes the entirety of a _Milestone Payload_ in its serialized form ([Data Type Notation](https://github.com/GalRogozinski/protocol-rfcs/blob/message/text/0017-message/0017-message.md#data-types)):

<table>
  <tr>
    <th>Name</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Payload Type</td>
    <td>uint32</td>
    <td>Set to <strong>value 1</strong> to denote a <i>Milestone Payload</i>.</td>
  </tr>
  <tr>
    <td valign="top">Essence <code>oneOf</code></td>
    <td colspan="2">
      <details open="true">
        <summary>Milestone Essence</summary>
        <blockquote>Describes the signed part of a <i>Milestone Payload</i>.</blockquote>
        <table>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
          </tr>
          <tr>
            <td>Index Number</td>
            <td>uint32</td>
            <td>The index number of the milestone.</td>
          </tr>
          <tr>
            <td>Timestamp</td>
            <td>uint64</td>
            <td>The Unix timestamp at which the milestone was issued. The unix timestamp is specified in seconds.</td>
          </tr>
          <tr>
            <td>Parent1</td>
            <td>ByteArray[32]</td>
            <td>The Message ID of the first <i>Message</i> referenced by the milestone.</td>
          </tr>
          <tr>
            <td>Parent2</td>
            <td>ByteArray[32]</td>
            <td>The Message ID of the second <i>Message</i> referenced by the milestone.</td>
          </tr>
          <tr>
            <td>Inclusion Merkle Root</td>
            <td>ByteArray[64]</td>
            <td>512-bit hash based on all of the not-ignored state-mutating transactions referenced by the milestone. (<a href="https://github.com/iotaledger/protocol-rfcs/blob/master/text/0012-milestone-merkle-validation/0012-milestone-merkle-validation.md">RFC-0012</a>)</td>
          </tr>
          <tr>
            <td>Keys Count</td>
            <td>uint8</td>
            <td>Number of public keys entries.</td>
          </tr>
          <tr>
            <td>Public Keys</td>
            <td>Array&lt;ByteArray[32]&gt;</td>
            <td>An array of public keys to validate the signatures. The keys must be in lexicographical order.</td>
          </tr>
        </table>
      </details>
    </td>
  </tr>
  <tr>
    <td>Signatures Count</td>
    <td>uint8</td>
    <td>Number of signature entries. The number must match the field <code>Keys Count</code>.</td>
  </tr>
  <tr>
    <td>Signatures</td>
    <td>Array&lt;ByteArray[64]&gt;</td>
    <td>An array of signatures signing the serialized <i>Milestone Essence</i>. The signatures must be in the same order as the specified public keys.</td>
  </tr>
</table>

## Generation

- Generate a new _Milestone Essence_ corresponding to the Coordinator milestone.
- Transmit the serialized _Milestone Essence_ to the corresponding number of signature service providers.
  - The signature provider service will sign the received serialized bytes as-is.
  - The signature provider will serialize the signature bytes and return them to the Coordinator.
- Fill the `Signatures` field of the milestone payload with the received signature bytes.
- Generate a *Message* as defined in [RFC-0017 (draft)](https://github.com/GalRogozinski/protocol-rfcs/blob/message/text/0017-message/0017-message.md) using the same `Parent1` and `Parent2` for the created _Milestone Payload_.

## Syntactical validation

- `Parent1` and `Parent2` of the payload must match `Parent1` and `Parent2` of the encapsulating _Message_.
- `Keys Count` must be at least the _Signature Threshold_ and at most the number of _Applicable Public Keys_ for the current milestone index.
- `Public keys`:
  - The provided keys must form a subset of the _Applicable Public Keys_ for the current milestone index.
  - The keys must be unique.
  - The keys must be in lexicographical order.
- `Signatures Count` must match the amount of public keys. 
- All `Signatures` must be valid.
- Given the type and length information, the _Milestone Payload_ must consume the entire byte array of the `Payload` field of the _Message_.

# Rationale and alternatives

Instead of going with EdDSA we could have chosen ECDSA. Both algorithms are well supported and widespread. However, signing with ECDSA requires fresh randomness while EdDSA does not. Moreover, we could have used a commit-reveal mechanism to update and commit the Coordinator public key at each next milestone. This method would make a quantum-based attack aimed at breaking the "current" Coordinator private-key more difficult. On the other hand, key management as well as verification of the milestone chain would become more complex.

# Unresolved questions

- Forcing matching `Parent1`, `Parent2` in the _Milestone Payload_ and its _Message_ makes it impossible to reattach the same payload at different positions in the Tangle. While this does not prevent reattachments in general (a different, valid `Nonce`, for example would lead to a new Message ID), this still simplifies milestone processing. However, it violates a clean separation of payload and message. As such, it might still be desirable to slightly complicate the milestone processing in order to allow any reattachments of _Milestone Payloads_ by not validating the parents.
