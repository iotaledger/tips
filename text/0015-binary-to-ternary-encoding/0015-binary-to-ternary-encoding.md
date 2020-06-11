+ Feature name: `binary-to-ternary-encoding`
+ Start date: 2020-06-08
+ RFC PR: [iotaledger/protocol-rfcs#0015](https://github.com/iotaledger/protocol-rfcs/pull/15)

# Summary

In the IOTA protocol, a transaction is represented as ternary data. However, sometimes it is necessary to store binary data (e.g. the digest of a binary hash function) inside of a transaction. This requires the conversion of binary into ternary strings.
The IOTA client libraries support the opposite conversion that encodes 5 trits as 1 byte (sometimes also referred to as `t5b1`), which is used for network communication and in storage layers. This RFC describes the corresponding counterpart to encode 1 byte as 6 trits.

# Motivation

A byte is composed of 8 bits that can represent 2<sup>8</sup> = 256 different values. On the other hand, 6 trits can hold 3<sup>6</sup> = 729 values while 5 trits can hold 3<sup>5</sup> = 243 values. Therefore, the most memory-efficient way to encode one byte requires the use of 6 trits. Although there exist many potential encoding schemes to convert binary data into ternary, the proposed version has been designed to directly match the widely used `t5b1` encoding.

# Detailed design

### Bytes to trits
In order to encode a binary string S into ternary, each byte of S is interpreted as a signed (two's complement) 8-bit integer value v. Then, v is encoded as a little-endian 6-trit string in balanced ternary representation. Finally, the resulting groups of trits are concatenated.

This algorithm can also be described using the following pseudocode:
```
T ← []
foreach byte b in S:
  v ← int8(b)
  g ← IntToTrits(v, 6)
  T ← T || g
```

Here, the function `IntToTrits` converts a signed integer value into its corresponding balanced ternary representation in little-endian order of the given length. The functionality of `IntToTrits` exactly matches the one used to e.g. encode the transaction values as trits in the current IOTA protocol.

### Trits to bytes

Given a trit string T as the result of the previous encoding, T is converted back to its original byte string S by simply reversing the conversion:
```
S ← []
foreach 6-trit group g in T:
  v ← TritsToInt(g)
  b ← byte(v)
  S ← S || b
```

## Examples

- I
  - binary (hex): `00`
  - ternary (trytes): `99`
- II
  - binary (hex): `0001027e7f8081fdfeff`
  - ternary (trytes):
`99A9B9RESEGVHVX9Y9Z9`
- III
  - binary (hex): `9ba06c78552776a596dfe360cc2b5bf644c0f9d343a10e2e71debecd30730d03`
  - ternary (trytes): `GWLW9DLDDCLAJDQXBWUZYZODBYPBJCQ9NCQYT9IYMBMWNASBEDTZOYCYUBGDM9C9`

# Drawbacks

- Conceptually, one byte can be encoded using log<sub>3</sub>(256) ≈ 5.0474 trits. Thus, encoding 1 byte as 6 trits consumes considerably more memory than the mathematical minimum.
- Depending on the actual implementation the conversion might be malleable: E.g. both `Z9` (-1) and `LI`(255) could be decoded as `ff`. However, `LI` can never be the result of a valid encoding. As such, the implementation must reject such invalid inputs.

# Rationale and alternatives

There are several ways to convert binary data into ternaray, e.g.
 - the conversion used as part of the [Kerl](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md) hash function encoding chunks of 48 bytes as 242 trits,
 - or by encoding each bit as one trit with the corresponding value.

Each conversion method has different advantages and disadvantages. However, since the `t5b1` encoding is well-defined and has been used in [IRI](https://github.com/iotaledger/iri) for both network communications and storage layers for a long time, choosing the direct counterpart for the opposite conversion represents the most logical solution providing a nice balance between performance and memory-efficiency.

# Open questions

The current client libraries do not offer any functionality to convert bytes into trits. The closest offered functionality is the ASCII to trit conversion, which is used for human-readable messages in transactions:
```
T ← []
foreach char c in S:
  first ← uint8(c) mod 27
  second ← (uint8(c)-first) / 27
  T ← T || IntToTrits(first, 3) || IntToTrits(second, 3)
```
This function can be adapted to encode any general byte string. However, the conversion seems rather arbitrary and the algorithm is computationally more intense than the proposed solution.

On the other hand, using the algorithm from this RFC also for the conversion of ASCII messages would break backward compatibility.
