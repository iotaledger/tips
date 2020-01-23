+ Feature name: `ed25519-signature-scheme`
+ Start date: 2020-01-16
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

The authenticity of a bundle in the IOTA protocol is assured by a signature corresponding to the private key of the respected address. This RFC introduces a mechanism to combine Ed25519 as second signature scheme with the currently used Winternitz-OTS. It aims to be as less disruptive to the current protocol version as possible by completely preserving the transaction layout and the address format.

# Motivation

The current IOTA Protocol is based on the _Winternitz One-Time Signature_ (w-OTS) scheme, a hash-based signature scheme, that uses the ternary 243-trit hash function [Kerl](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md). This signature scheme is provably resistant to a sufficiently powerful quantum computer running [Shor’s algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm). However, in contrast to traditional ECDSA or EdDSA signatures, it also has significant disadvantages.
- Statefulness: W-OTS only allows for one secure signing process. Starting from the second signature so much information has been exposed, that the private key, and as such the funds on that address, are considered insecure. This poses serious security risks, as signing one invalid transaction has to be considered as dangerous as exposing the private key itself.
- Size: The created signatures are rather large. In IOTA, 2187 to 6561 trytes or 1300 to 3900 bytes (based on the chosen security level) are reserved for the signature.
- Speed: It is based on the [Keccak-384](https://keccak.team/keccak.html) hash function and has been designed to provide a trade-off between size and speed. As such, the hashing function needs to be executed 702 times to validate one signature in the default setting, which can lead to significant system overhead even on powerful hardware.

Ed25519 is a modern EdDSA signature scheme using [SHA-512](https://en.wikipedia.org/wiki/SHA-512) and [Curve25519](https://en.wikipedia.org/wiki/Curve25519). It aims to address all the points above with the drawback of being less quantum robust. However, this issue can be partially mitigated when combined with a commitment scheme: The address is chosen as the hash of the public key, which itself is only revealed during the actual signing process. This way, Shor's algorithm can only be applied after the signed bundle has been issued to the network and therefore effectively making this signature scheme immune against this attack when addresses are not reused.

In order to use the benefits from both approaches and in order to make the transition period as smooth as possible. This RFC proposes a hybrid approach where both signature schemes are used in parallel with only minimal changes to existing concepts and workflows: 
As a user, I want to see addresses in the familiar 81-tryte representation. 
As a developer of IOTA applications, I want to make the, so that I can make the application compatible with the new signature scheme without any groundbreaking changes.

# Detailed design

### Address generation

- Create an [Ed25519](https://ed25519.cr.yp.to/) key pair of a 32-byte public key K and a 64-byte private key k. Hash K using [Keccak-384](https://keccak.team/keccak.html). This results in a 48-byte hash that can then be converted into a regular 81-tryte address using [this algorithm](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md#trits---bytes-encoding). The exact conversion is also used as part of the current Kerl hash function.
- The address can then be publicly shared to receive funds, while the public and private key are kept secret.

### Signing a bundle

- Each input transaction in the bundle needs to be signed with the key pair corresponding to that address. The signature is stored in the `signatureMessageFragment` transaction field.
- Compute the bundle hash M by hashing the regular [bundle essence](https://docs.iota.org/docs/getting-started/0.1/transactions/bundles#bundle-essence) using [Kerl](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md). However, instead of producing a 81-tryte output, the final [bytes-trits conversion](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md#conversion-bytes-tofrom-biginteger) is skipped in order to get a 48-byte hash. Note that there is no need to normalize M.
- Compute the 64-byte signature S of the hash M as described for Ed25519.
- Encode the public key K into ternary by converting one byte value v into two trytes: (v mod 27) || (v div 27), where div denotes the integer division in which the fractional part is discarded. This leads to K<sub>tri</sub> with size of 64 trytes
- Apply the same encoding to S to get S<sub>tri</sub> of 128 trytes.
- `signatureMessageFragment` = K<sub>tri</sub> || S<sub>tri</sub> || `9`<sup>1995</sup>. This makes it exactly 2187 trytes long, as expected.

### Signature verification

- In order to verify the signature in `signatureMessageFragment` of an input transaction tx, first identify the used signature scheme: If the length of `signatureMessageFragment` excluding trailing `9`s is 192 trytes, validate using Ed25519, otherwiese use W-OTS.
- Convert the leading K<sub>tri</sub> || S<sub>tri</sub> of the`signatureMessageFragment` to the binary K, S by reversing the encoding. 
- Hash the key K as describe in "Address generation" and verify that those 81 trytes match the `address` field of tx.
- Compute the bundle hash M of the corresponding bundle and check that S is the correct Ed25519 signature for M.

### Key derivation

For Ed25519 every 256-bit number (even 0) is a valid private key and as such, any random number can be used to derive a valid key pair. However, as this would require frequent backups of all the private keys and pose a serious risk of loosing any one of them, it is desirable to derive key pairs deterministically from one master seed.
[BIP-0032](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) defines the de facto standard for [secp256k1](http://www.secg.org/sec2-v2.pdf) curves and it is implemented and used in all relevant hardware and software wallets. [SLIP-0010](https://github.com/satoshilabs/slips/blob/master/slip-0010.md) extends this and describes how to derive a master private/public key for Ed25519 and how a BIP-0032 like derivation is used.

# Drawbacks

Why should we *not* do this?

# Rationale and alternatives

- Why is this design the best in the space of possible designs?
- What other designs have been considered and what is the rationale for not
  choosing them?
- What is the impact of not doing this?

# Unresolved questions

- What parts of the design do you expect to resolve through the RFC process
  before this gets merged?
- What parts of the design do you expect to resolve through the implementation
  of this feature before stabilization?
- What related issues do you consider out of scope for this RFC that could be
  addressed in the future independently of the solution that comes out of this
  RFC?
