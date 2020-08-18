+ Feature name: `bech32-address-format`
+ Start date: 2020-07-28
+ RFC PR: [iotaledger/protocol-rfcs#0020](https://github.com/iotaledger/protocol-rfcs/pull/20)

# Summary

This document proposes an extendable address format for the IOTA protocol supporting various signature schemes and address types. It relies on the [Bech32](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki) format to provide a compact, human-readable encoding with strong error correction guarantees.

# Motivation

IOTA uses the [Winternitz one-time signature scheme](https://docs.iota.org/docs/getting-started/1.0/cryptography/signatures) (W-OTS) to generate digital signatures, in which addresses correspond to a [Kerl](https://github.com/iotaledger/kerl) hash. With the introduction of Ed25519 signatures as part of [Chrysalis](https://roadmap.iota.org/chrysalis), it is necessary to define a new universal and extendable address format capable of encoding these two types of addresses.

The current IOTA protocol relies on Base27 addresses with a truncated Kerl checksum. However, both the character set and the checksum algorithm have limitations: 
- Base27 is designed for ternary and is ill-suited for binary data.
- The Kerl hash function also requires ternary input. Further, it is slow and provides no error-detection guarantees.
- It does not support the addition of version or type information to distinguish between different kinds of addresses with the same length.

All of these points are addressed in the Bech32 format introduced in [BIP-0173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki): In addition to the usage of the human-friendly Base32 encoding with an optimized character set, it implements a [BCH code](https://en.wikipedia.org/wiki/BCH_code) that _guarantees detection_ of any error affecting at most 4 characters and has less than a 1 in 10<sup>9</sup> chance of failing to detect more errors.

This RFC proposes a simple and extendable binary serialization for the two address types that is then Bech32 encoded to provide a unique appearance for human-facing applications such as wallets. 

# Detailed design

## Binary serialization

The address format uses a simple serialization scheme which consists of two parts:

   - The first byte describes the type of the address.
   - The remaining bytes contain the type-specific raw address bytes.

Currently, two kinds of addresses are supported:
 - W-OTS, which is compatible to the existing legacy IOTA signature scheme and
 - Ed25519, where the address consists of the BLAKE2b-256 hash of the Ed25519 public key.

They are serialized as follows:

| Type    | First byte | Address bytes                                             |
| ------- | ---------- | --------------------------------------------------------- |
| W-OTS   | `0x00`     | 49 bytes: The t5b1 encoded Kerl hash of the W-OTS digest. |
| Ed25519 | `0x01`     | 32 bytes: The BLAKE2b-256 hash of the Ed25519 public key. |


## Bech32 for human-readable encoding

The human readable encoding of the address is Bech32 (as described in [BIP-0173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki)). A Bech32 string is at most 90 characters long and consists of: 

- The **human-readable part** (HRP), which conveys the IOTA protocol and distinguishes between Mainnet (the IOTA token) and Testnet (testing version):
   -  `iot` is the human-readable part for Mainnet addresses
   -  `tio` is the human-readable part for Testnet addresses
- The **separator**, which is always `1`.
- The **data part**, which consists of the Base32 encoded serialized address and the 6-character checksum.

For legacy W-OTS, the data part will consist of 86 characters (80 characters for the 50-byte address in Base32 and 6 characters for the checksum). Together with the HRP, separator and checksum, this leads to a Bech32 string of exactly 90 characters.
Ed25519-based addresses will result in a Bech32 string of 63 characters.

## Examples

- **Mainnet**
   - W-OTS address hash (81-tryte): `EQSAUZXULTTYZCLNJNTXQTQHOMOFZERHTCGTXOLTVAHKSA9OGAZDEKECURBRIXIJWNPFCQIOVFVVXJVD9`
      - serialized (50-byte): `00ea38caaeeec5c3fd6d0e89e32c9097bcc02ddcec40a8dcc516c7bc012d0b6bbe315493b0b86cdfbd11a7b8f0d5aa6f2200`
      - Bech32 string: `iot1qr4r3j4wamzu8ltdp6y7xtysj77vqtwua3q23hx9zmrmcqfdpd4muv25jwctsmxlh5g60w8s6k4x7gsq28c8da`
   - Ed25519 address hash (32-byte): `52fdfc072182654f163f5f0f9a621d729566c74d10037c4d7bbb0407d1e2c649`
      - serialized (33-byte): `0152fdfc072182654f163f5f0f9a621d729566c74d10037c4d7bbb0407d1e2c649`
      - Bech32 string: `iot1q9f0mlq8yxpx2nck8a0slxnzr4ef2ek8f5gqxlzd0wasgp73utryjtzcp98`
- **Testnet**
   - W-OTS address hash (81-tryte): `EQSAUZXULTTYZCLNJNTXQTQHOMOFZERHTCGTXOLTVAHKSA9OGAZDEKECURBRIXIJWNPFCQIOVFVVXJVD9`
      - serialized (50-byte): `00ea38caaeeec5c3fd6d0e89e32c9097bcc02ddcec40a8dcc516c7bc012d0b6bbe315493b0b86cdfbd11a7b8f0d5aa6f2200`
      - Bech32 string: `tio1qr4r3j4wamzu8ltdp6y7xtysj77vqtwua3q23hx9zmrmcqfdpd4muv25jwctsmxlh5g60w8s6k4x7gsqcmnkzh`
   - Ed25519 address hash (32-byte): `52fdfc072182654f163f5f0f9a621d729566c74d10037c4d7bbb0407d1e2c649`
      - serialized (33-byte): `0152fdfc072182654f163f5f0f9a621d729566c74d10037c4d7bbb0407d1e2c649`
      - Bech32 string: `tio1q9f0mlq8yxpx2nck8a0slxnzr4ef2ek8f5gqxlzd0wasgp73utryj3qemv4`

# Drawbacks

While it is absolutely possible to transform legacy W-OTS addresses from their 81-tryte representation into the proposed format and back, the new addresses will look fundamentally different from the established 81-tryte IOTA addresses. 

# Rationale and alternatives

There are several ways to convert the binary serialization into a human-readable format, e.g. Base58 or hexadecimal. The Bech32 format, however, offers the best compromise between compactness and error correction guarantees. A more detailed motivation can be found in [BIP-0173 Motivation](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki#motivation).

The binary serialization itself must be as compact as possible while still allowing you to distinguish between different address types of the same byte length. As such, the introduction of a version byte offers support for up to 256 different kinds of addresses at only the cost of one single byte.

# Unresolved questions

- The HRP of the Bech32 string offers a good opportunity to clearly distinguish IOTA addresses from other Bech32 encoded data. Here, any three or four character ASCII strings can be used. It should be part of the RFC process to evaluate whether `iot`/`tio` is indeed the preferred prefix or whether an alternative like `iota`/`tiot`, `io`/`tio` etc. is favorable.
A full list of registered human-readable parts for other cryptocurrencies can be found here: [SLIP-0173 : Registered human-readable parts for BIP-0173](https://github.com/satoshilabs/slips/blob/master/slip-0173.md)
- Additional signature schemes or multisig addresses will be described in separate new RFCs.
