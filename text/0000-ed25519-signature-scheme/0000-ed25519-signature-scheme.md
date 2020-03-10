+ RFC Author: [Wollac](https://github.com/Wollac)
+ Feature name: `ed25519-signature-scheme`
+ Start date: 2020-01-16
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

The authenticity of a transaction bundle in the IOTA protocol is assured by a signature corresponding to the private key of the respected address. This RFC introduces a mechanism to combine Ed25519 (see [RFC 8032](https://tools.ietf.org/html/rfc8032)) as a second signature scheme with the currently used Winternitz-OTS. It aims to be as less disruptive to the current protocol version as possible by completely preserving the transaction layout and the address format.

# Motivation

The current IOTA Protocol is based on the _Winternitz One-Time Signature_ (W-OTS) scheme, a hash-based signature scheme, that uses the ternary 243-trit hash function [Kerl](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md). Such signature schemes are provably resistant to a sufficiently powerful quantum computer running [Shor’s algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm). However, in contrast to traditional ECDSA or EdDSA signatures, it also has significant disadvantages:
- Statefulness: W-OTS only allows for one secure signing process. Starting from the second signature so much information has been exposed, that the private key, and as such the funds on that address, are considered insecure. This poses serious security risks, as, e.g., signing one invalid transaction has to be considered almost as dangerous as exposing the private key itself.
- Size: The created signatures are rather large. In IOTA, 2187 to 6561 trytes or 1300 to 3900 bytes (based on the chosen security level) are reserved for the signature. For comparison, traditional ECDSA signatures require about 64 bytes.
- Speed: It is based on the [Keccak-384](https://keccak.team/keccak.html) hash function and has been designed to provide a trade-off between size and speed. As such, the hashing function needs to be executed 702 times to validate one signature in the default setting. This can lead to significant system overhead even on powerful hardware.

Ed25519 is a modern EdDSA signature scheme using [SHA-512](https://en.wikipedia.org/wiki/SHA-512) and [Curve25519](https://en.wikipedia.org/wiki/Curve25519). It aims to address all the points above with the drawback of being less quantum robust. However, this issue can be partially mitigated when combined with a commitment scheme: The address is chosen as the hash of the public key, which itself is only revealed during the actual signing process. This way, Shor's algorithm can only be applied after the signed bundle has been issued to the network and therefore effectively making this signature scheme immune against this attack when addresses are not reused.

In order to use the benefits from both approaches and in order to make the transition period as smooth as possible. This RFC proposes a hybrid approach where both signature schemes are used in parallel with only minimal changes to existing concepts and workflows.

# Detailed design

### Address generation

- Create an [Ed25519](https://ed25519.cr.yp.to/) key pair of a 256-bit public key K and a 256-bit private key k. Hash K using [Keccak-384](https://keccak.team/keccak.html) resulting in a 384-bit hash.
- Interpret the resulting bit string as a signed integer in big-endian two's complement representation and encode it as a little-endian 243-trit string in balanced ternary representation where the last (the most significant) trit is set to 0. [This exact conversion](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md#trits---bytes-encoding) is also used as part of the current Kerl hash function.
- The trit string is then used as an IOTA address in its usual 81-tryte encoding. It can be shared publicly to receive funds, while the public and private key are kept secret.

### Signing a bundle

- Each input transaction in the bundle needs to be signed with the private key corresponding to that address and the signature is stored in the `signatureMessageFragment` transaction field.
- Compute the bundle hash M by hashing the regular [bundle essence](https://docs.iota.org/docs/getting-started/0.1/transactions/bundles#bundle-essence) using [Kerl](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md). However, instead of producing a 243-trit string, the final [bytes-trits conversion](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md#conversion-bytes-tofrom-biginteger) is skipped in order to get a 384-bit hash. Note that there is no need to normalize M.
- Compute the 512-bit signature S of the hash M as described for the Ed25519 signature algorithm.
- Encode the public key K into ternary by interpreting each octet of the string K as a signed (two's complement) 8-bit integer value v and then encoding v as a little-endian 6-trit string in balanced ternary representation. This leads to K<sub>tri</sub> with a length of 192 trits.
- Apply the same encoding to S to get the 384-trit string S<sub>tri</sub>.
- Finally, set the `signatureMessageFragment` field in the transaction to be signed in the following way:
  `signatureMessageFragment` = K<sub>tri</sub> || S<sub>tri</sub> || `0`<sup>5985</sup>. This makes it a 6561-trit string, as expected.

### Signature verification

- In order to verify the signature in `signatureMessageFragment` of an input transaction tx, first identify the used signature scheme: If the length of `signatureMessageFragment` excluding trailing `0`s is less or equal 576 trits, validate using Ed25519, otherwise use W-OTS.
- Convert the leading K<sub>tri</sub> || S<sub>tri</sub> of the`signatureMessageFragment` to the binary K, S by reversing the encoding used during signing. 
- Hash the key K as described in "Address generation" and verify that ternary encoded hash matches the `address` field of tx.
- Compute the bundle hash M of the corresponding bundle and check that S is the correct Ed25519 signature for M.

## Example

Private key (hex): 9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60

### Address generation

- public key (32-byte): d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
- public key hash (48-byte): c184d23ed1c0f304d39b58c0ff5e66382609d44dd99844a0a33fd2bf24dcc156c5fc4066e3e9d0b5d4960b9d29b6a0c5
- address (81-tryte): VP9UQNWTKYOBACDWDVCKLSSAELQMDTOJDBQMIGQCWAEPXUJNNJGKXMCFPZYWEZJWUOTLOEGBKVCPVAPAX

### Signature

Sign transfer of 1 GI to address "999999999999999999999999999999999999999999999999999999999999999999999999999999999" with the following bundle essence:
```json
[
 {
  "address": "999999999999999999999999999999999999999999999999999999999999999999999999999999999",
  "value": 1000000000,
  "obsoleteTag": "EDTWOFIVEFIVEONENINE9999999",
  "currentIndex": 0,
  "lastIndex": 1,
  "timestamp": 0,
 },
 {
  "address": "VP9UQNWTKYOBACDWDVCKLSSAELQMDTOJDBQMIGQCWAEPXUJNNJGKXMCFPZYWEZJWUOTLOEGBKVCPVAPAX",
  "value": -1000000000,
  "obsoleteTag": "999999999999999999999999999",
  "currentIndex": 1,
  "lastIndex": 1,
  "timestamp": 0,
 }
]
```
- bundle hash (81-tryte): RXDECZI9MWEVGUWYELFSPASJQPRKFDEY9ZYKIXFYUBKZYIKOHNMHZJKVBLLNJSRFIRQRIHQZBBVVZRXUX
- bundle hash (48-byte): bc4c9241451b90473bfd9cb00ddeada30392e43f280a4aa72dee27ab54e9994b297fed74963a2cab33869c1a031af68d
- public key (32-byte): d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
- signature (64-byte): 515acc3127aa7bb1075981048c4cbd2fcef8bcefee3e3b0b0d586bddc99da98ef0bf87480eaed229388a5ddb543b9b8c49a61bc7d85668ded4dd94d03309a204
- signatureMessageFragment (K<sub>tri</sub> || S<sub>tri</sub> 192-tryte): MYICDWA9IVBXJ9HXKYUCY9IYZYSDG9DBNAWZFDN9PZRXHAJA9XB9ZAWDR9G99CZA9CICBYVBLAVXOEBXG9HCHVD9SWVCNYTBDYS9MXJZIZHBEBK9M9GCZDSZZYIWUXUWKZPYNWRCNAZXHYNBBBQWLCQZCCEBGWSWSCRX9AXYNZECWDTZJYSZ9WFYXBI9NXD

# Drawbacks

While the Ed25519 signature algorithm offers a very fast and robust signature scheme, it suffers, like any traditional ECDSA or EdDSA signatures, from susceptibility to Shor's polynomial-time quantum computer algorithm. Although this attack vector is addressed by only publishing the EdDSA public key when signing, it is still inherently less secure than hash-based signature schemes:
- During the time window, when the signature has been issued to the network but before the transaction has been confirmed and sufficiently finalized, Shor's algorithm could be used to break the private key from the published public key.
- After the first time an Ed25519 address has been spent from, the public key is also known. As such, this signature scheme offers no stronger quantum robustness for multiple spends from the same address. This is the case, when addresses are either spent from more than once or when the same address is also used in a different fork or testnet of the network.

The signature scheme as a drop-in replacement for the current W-OTS does not offer any replay protection in the current account model: After a transaction has moved funds from A to B, an attacker can simply re-attach this transaction again to transfer the same amount of funds to B a second time, providing a sufficient balance on address A. Although exactly the same attack vector is also present in the current protocol, its effects are considerably worsened as the Ed25519 signature algorithm by design encourages address reuse.

# Rationale and alternatives

- The Ed25519 public-key signature system is a standard for modern signature schemes, as it offers high-speed high-security signatures.
- This RFC aims for a seamless integration of Ed25519 signatures in the existing protocol. As such, the transaction structure as well as the resulting address format remain unchanged. While this offers the least possible development overhead to adapt existing W-OTS-only implementations, it also comes with a few drawbacks:
  - W-OTS and Ed25519 addresses look exactly the same. This makes it impossible for the user or the system to apply any special considerations for the different signature schemes based on the addresses alone.
  - The decision which signature verification is to be used, only depends on the length of the signature. This may lead to ambiguities when further signature schemes are introduced.
  - Signing the bundle hash with Ed25519 leads to unnecessary double hashing of the bundle essence. The performance of the signature scheme could be improved further by signing the bundle essence directly with Ed25519.
  - One of the compelling features of Ed25519 is that it provides very small binary key and signature sizes. By representing these as fixed length ternary strings, a lot of this potential is lost with respect to the transaction size. However, it is important to note that even simple compression algorithms, like run-length encoding, mostly circumvent this issue. 
- Even though W-OTS offers strong quantum robustness, it comes with huge drawbacks for a payment system. Most notably here is the fact that signing more than once with the same key endangers the funds. A malicious wallet, a single malicious node or even network issues inducing wrongly reported balances, can force an honest user to sign one or more invalid transactions. Although these transactions will never be accepted by the network, they still expose valid signatures which can be used to break the private key even on conventional today's hardware.
As such, offering an alternative "multi-time" signature scheme, is an important requirement for everyday use.

# Unresolved questions

This RFC only considers the actual signature scheme and needs to be combined with other aspects which will be presented in different RFCs:
- _Replay protection_ must be assured by additional methods, such as:
  -  UTXO offers protection as unspent outputs are referenced instead of transactions.
  -  Adding a transaction nonce and disallowing successive transactions with the same nonce.
  -  Signing the entire bundle (instead of only the bundle essence) and disallowing successive instances of the same transaction.
- _Deterministic private key derivation_ used for hierarchical deterministic wallets: Most notably here is [SLIP-0010](https://github.com/satoshilabs/slips/blob/master/slip-0010.md) aiming to bring [BIP-0032](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) like derivation for Ed25519.
- _New address format_ to encode additional information like the used signature scheme. 
