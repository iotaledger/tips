+ Feature name: `milestone-merkle-validation`
+ Start date: 2020-05-04
+ RFC PR: [iotaledger/protocol-rfcs#0012](https://github.com/iotaledger/protocol-rfcs/pull/12)

# Summary

In the IOTA protocol, nodes use the milestones issued by the Coordinator to reach a consensus on which transactions are confirmed. This RFC adds extra information to each milestone in the form of a Merkle tree hash, which allows nodes to explicitly validate their local view of the ledger state against the coordinator's. This mechanism further enables a simple cryptographic proof of inclusion for transactions confirmed by the particular milestone.

# Motivation

With the changes proposed in [RFC-0005 (white flag)](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0005-white-flag/0005-white-flag.md), milestones are allowed to reference conflicting transactions. These conflicts are then resolved by traversing the newly confirmed transactions in a global, deterministic order and applying the corresponding ledger state changes in that order. Conflicts or invalid transactions are ignored, but stay in the Tangle.
This approach has considerable advantages in terms of network security (e.g. protection against [conflict spamming attacks](https://iota.cafe/t/conflict-spamming-attack/232)) and network performance. However, a milestone no longer represents the inclusion state of all its referenced transactions, but only marks the order in which transactions are checked against the ledger state and then, if not violating, applied. This has two significant drawbacks:
 - Milestone validation: In the IOTA protocol, each node always compares the milestones issued by the Coordinator against its current ledger state. Discrepancies are reported and force an immediate halt of the node software. However, in the white flag proposal this detection is no longer possible as any milestone can lead to a valid ledger state by ignoring the corresponding violating ledger changes.
 - Proof of inclusion: In the pre-white-flag protocol, the inclusion of transaction t in the Tangle, and thus, the ledger, can be shown by providing an audit path of referencing transactions from t to its confirming milestone. In the white flag proposal this is no longer possible, as such an audit path does not provide any information on whether the transaction has been included or ignored. 

Where previously the structure of the Tangle alone was sufficient to address those issues, this RFC proposes to add the Merkle tree hash of all the valid (i.e. not ignored) newly confirmed bundles to the signed part of a milestone. This way, each IOTA node can check that the hash matches its local ledger state changes or provide a Merkle audit path for that milestone to prove the inclusion of a particular bundle.

# Detailed design

## Creating a Milestone

- Perform tip selection to choose a branch and a trunk for the new milestone.
- Determine the topological order according to [RFC-0005](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0005-white-flag/0005-white-flag.md) of the referenced bundles that are not yet confirmed by a previous milestone.
- Construct the list B<sup>tri</sup> consisting of the tail transaction hashes of all the not-ignored bundles in that particular order.
- Convert each element of B<sup>tri</sup> to binary by splitting it into groups of 5 trits and interpreting each group as a balanced ternary value in little-endian representation. Each value is then encoded as a signed (two's complement) 8-bit integer. (This exactly matches the conversion used for binary I/O of ternary data in the current protocol.) This leads to the ordered list B containing 49-byte strings.
- Compute the 64-byte Merkle tree hash H = MTH(B).
- Encode H into ternary by interpreting each octet of the string H as a signed 8-bit integer value v and then encoding v as a little-endian 6-trit string in balanced ternary representation. This leads to H<sup>tri</sup> with a length of 384 trits.
- Prepare the milestone bundle as usual. Its head transaction contains the information required to verify the Coordinator's signature in its `signatureMessageFragment` field. This information has a length of d·81 trytes, where d is the depth of the Coordinator's Merkle tree. 
- Append H<sup>tri</sup> to the `signatureMessageFragment` field. For any depth d < 26 the field provides sufficient space.
- Sign the head transaction and add its fragmented signature to the milestone bundle's zero value transactions.

## Milestone validation

- Verify the signature of the milestone m.
- Construct the ordered list B<sup>tri</sup> of the tail transaction hashes of the not-ignored bundles m confirms.
- Encode the hashes B<sup>tri</sup> into their binary representation B and compute H = MTH(B).
- Extract the first 192 trits after the Coordinator's Merkle tree information from the `signatureMessageFragment` field of the head transaction and verify that this matches the ternary encoded H.

## Proof of inclusion

- Identify the confirming milestone m of the input bundle b.
- Determine the ordered list of the not-ignored bundles m confirms.
- Compute the Merkle audit path of b with respect to the Merkle tree for this ordered list.
- Provide the audit path as well as m as proof of inclusion for b.

## Cryptographic components

### Merkle hash trees

This RFC uses a binary Merkle hash tree for efficient auditing. In general, any cryptographic hashing algorithm can be used for this. However, we propose to use [BLAKE2b-512](https://tools.ietf.org/html/rfc7693), as it provides a faster and more secure alternative to the widely used SHA-256/SHA-512. 
In the following we define the Merkle tree hash (MTH) function that returns the hash of the root node of a Merkle tree:
- The input is a list of binary data entries; these entries will be hashed to form the leaves of the tree.
- The output is a single 64-byte hash.

Given an ordered list of n input strings D<sub>n</sub> = {d<sub>1</sub>, d<sub>2</sub>, ..., d<sub>n</sub>}, the Merkle tree hash of D is defined as follows:
- If D is an empty list, MTH(D) is the hash of an empty string:<br>
  MTH({}) = BLAKE2().
- If D has the length 1, the hash (also known as a leaf hash) is:<br>
  MTH({d<sub>1</sub>}) = BLAKE2( 0x00 || d<sub>1</sub> ).
- Otherwise, for D<sub>n</sub> with n > 1:
  - Let k be the largest power of two less than n, i.e. k < n ≤ 2k.
  - The Merkle tree hash can be defined recursively:<br>
    MTH(D<sub>n</sub>) = BLAKE2( 0x01 || MTH({d<sub>1</sub>, ..., d<sub>k</sub>}) || MTH({d<sub>k+1</sub>, ..., d<sub>n</sub>}) ).

Note that the hash calculations for leaves and nodes differ. This allows the validator to distinguish between leaves and nodes, which is required to provide second preimage resistance.

Note that we do not require the length of the input to be a power of two. However, its shape is still uniquely determined by the number of leaves.

### Merkle audit paths

A Merkle audit path for a leaf in a Merkle hash tree is the shortest list of additional nodes in a Merkle tree required to compute the Merkle tree hash for that tree. At each step towards the root, a node from the audit path is combined with a node computed so far. If the root computed from the audit path matches the Merkle tree hash, then the audit path is proof that the leaf exists in the tree.

## Example

Merkle tree with 7 leaves:
- input B:
  1. NOBKDFGZMOWYUKDZITTWBRWA9YPSXCVFENCQFPC9GMJIAIPSSURYIOMYZLGNZXLUAQHHNBSRHNOIJDYZO
  1. IPATPTEZSBMFJRDCRPTCVUQWBAVCAXAVZIDEDL9TSILDFWDMIIFPZIYHKRFFZDYQNKBQBVGYSKMLCYBMR
  1. MXOIOFOGLIHCHMDRCWAIYCWIUCMGEZWXFJZFWBRCNSNBWIGFJXBCACPKMLLANYNXSGYKANYFTVGTLFXXX
  1. EXZTJAXJMZJBBIZGUTMBOEUQDNVHJPXCLFUXNLPLSBATDMKYUZOFMHCOBWUABYDMNGMKIXLIUFXNVY9PN
  1. SJXYVFUDCDPPAOALVXDQUKAWLLOQO99OSJQT9TUNILQ9VLFLCZMLZAKUTIZFHOLPMGPYHKMMUUSURIOCF
  1. Q9GHMAITEZCWKFIESJARYQYMF9XWFPQTTFRXULLHQDWEZLYBSFYHSLPXEHBORDDFYZRFYFGDCM9VJKEFR
  1. GMNECTSPSLSPPEITCHBXSN9KZD9OZPVPOET9TVQJDZMFGN9SGPRPMUQARNXUVKMWAFAKLKWBZLWZCTPCP
- Merkle tree hash H = MTH(B) (64-byte): d07161bdb535afb7dbb3f5b2fb198ecf715cbd9dfca133d2b48d67b1e11173c6f92bed2f4dca92c36e8d1ef279a0c19ca9e40a113e9f5526090342988f86e53a
- ternary encoding H<sup>tri</sup> (128-tryte): FYEDPDNYFXZB9XHXQZDXP9CXV9YAUWEYEDKCNYIWW9MWXBHYEXTWVDBXWZQAGDWYT9PBHZTBWC9YYWTYBDTWCAMZMDLWRYHWUXZZJ9QAHBKWDCKAI9C9LBDWVWMV9ZDB

```
root: d07161bdb535afb7dbb3f5b2fb198ecf715cbd9dfca133d2b48d67b1e11173c6f92bed2f4dca92c36e8d1ef279a0c19ca9e40a113e9f5526090342988f86e53a
 ├─ node: 1448659e74c870013900a3012842b1e5fb2cfecde299d7bbe272ce0968b95546f7bbce242ebd39cd7ea965bd25c51e007212ecd999af17530ef68843311ef403
 │  ├─ node: ea4f73b420757c426e5f166066d9207ca4a49f878a1ba6d420367c7f9b946b6dcb35121b619c374a0a8b647623b391c54087b29401d2a9bc864b9816a53cdf27
 │  │  │  ┌ tx hash: NOBKDFGZMOWYUKDZITTWBRWA9YPSXCVFENCQFPC9GMJIAIPSSURYIOMYZLGNZXLUAQHHNBSRHNOIJDYZO
 │  │  ├──┴ leaf: 470afd417b1b3cdd4d876f1e636cb41e5a0f2c38d2160348cf0b8971144e5d20b118c08c3f65956f8d98949bf89bea8da3b34fa2cab1fba299512a9e573c0854
 │  │  │  ┌ tx hash: IPATPTEZSBMFJRDCRPTCVUQWBAVCAXAVZIDEDL9TSILDFWDMIIFPZIYHKRFFZDYQNKBQBVGYSKMLCYBMR
 │  │  └──┴ leaf: efefcba97952a5cad857b53f015c3d95c6c38ef9cc97b4b622a9f9f56b396627a6c3fd6f737428ed9c1487e834abedf83561f58c356071279068bdd53b85ffa8
 │  └─ node: 183cc0b9a79965986a12003af8b0be0ee3c3980853a99fb571a39fa394f56cb071db6487029b4d7c6ecdb72ae65fafa9e446c0bdca0f18c7f1eeea5170f5aca4
 │     │  ┌ tx hash: MXOIOFOGLIHCHMDRCWAIYCWIUCMGEZWXFJZFWBRCNSNBWIGFJXBCACPKMLLANYNXSGYKANYFTVGTLFXXX
 │     ├──┴ leaf: 95200ea45cebbe7b582cf23caf53224be98be9a553d4801ed804715afeb9b4b0db4c6a4b3de9852d2cef0712144196c18a7290936fea48208fb417b8d6fe56d0
 │     │  ┌ tx hash: EXZTJAXJMZJBBIZGUTMBOEUQDNVHJPXCLFUXNLPLSBATDMKYUZOFMHCOBWUABYDMNGMKIXLIUFXNVY9PN
 │     └──┴ leaf: b162e61d41a83ec238871d2a3ed2fbcfea5001b04b363c704bd3a29923ccfc701850ed9911bad3cf9bcb11c510955f8a16ff06f6cbe8d8c887275a83e9232483
 └─ node: 7ee54d71bd7958241bfba8a7817fe8eff006d5d7a84edc7358d0ce5639fc9a6cbf38e77bb96656e37189be922fc04090a5a306988f4d1060c2e4f011ff0b7470
    ├─ node: f2a80742a2b9f03cbf54878c50c6d79df79fe53809de55f236e9ce45f82a2ed9d4bb3a41f6254e2a24955bd6ce7cde5ff6178836029902819de20d0fce3add87
    │  │  ┌ tx hash: SJXYVFUDCDPPAOALVXDQUKAWLLOQO99OSJQT9TUNILQ9VLFLCZMLZAKUTIZFHOLPMGPYHKMMUUSURIOCF
    │  ├──┴ leaf: a32b588ed56c6823ab9677c5c910b274886b8bd49db9e3a5af24bddbad83dd2b801c744c3b690c99dab3d33a156bb076b4c047163010064235b9268568121e78
    │  │  ┌ tx hash: Q9GHMAITEZCWKFIESJARYQYMF9XWFPQTTFRXULLHQDWEZLYBSFYHSLPXEHBORDDFYZRFYFGDCM9VJKEFR
    │  └──┴ leaf: 7405aa17eaec13f23b9dc2faf635bf2688bdb7582296880453a930b0716265c93a12b823d5b2ed0a62459f80df3f347b44e7a8d290ff6c1051f34afe63d3827d
    │  ┌ tx hash: GMNECTSPSLSPPEITCHBXSN9KZD9OZPVPOET9TVQJDZMFGN9SGPRPMUQARNXUVKMWAFAKLKWBZLWZCTPCP
    └──┴ leaf: 282f3dc49046480e118f697bc90d37f19efb633d6e92cb27e53c4a3c69735e6e66e698b810c20e8e7c4d5b5f0b04946fc779a0c817ee587c01f80e44d3e69f84
```

# Drawbacks

- With this proposal the `signatureMessageFragment` now consists of two parts: The audit path of the Coordinator's Merkle tree and the 128-tryte Merkle tree hash of the confirmed bundles. This approach limits the depth of the Coordinator's Merkle tree to at most 25 (instead of 27 without the hash). However, a depth of 25 still allows to issue a milestone every 30 seconds for over 30 years.
- The computation of the Merkle tree hash of D<sub>n</sub> requires 2n-1 evaluations of the underlying hashing algorithm. This makes the milestone creation and validation computationally slightly more expensive.

# Rationale and alternatives

It is a crucial security feature of the IOTA network that nodes are able to validate the issued milestones. As a result, if the Coordinator were to ever send an invalid milestone, such as one that references counterfeit transactions, the rest of the nodes would not accept it. In a pure implementation of [RFC-0005](https://github.com/iotaledger/protocol-rfcs/blob/master/text/0005-white-flag/0005-white-flag.md) this feature is lost and must be provided by external mechanisms.
A Merkle tree hash provides an efficient, secure and well-established method to compress the information about the confirmed transactions in such a way, that they fit in the milestone transaction.

In this context, it could also be possible to use an unsecured checksum (such as CRCs) of the bundles instead of a Merkle tree hash. However, the small benefit of faster computation times does no justify the potential security risks and attack vectors.

The described approach is even in some sense backward compatible: As long as only the first d·81 trytes of the `signatureMessageFragment` are considered, the milestone processing remains unchanged.

# Unresolved questions

The Merkle tree hash can be computed using any secure cryptographic hashing algorithm. Thus, the usage of BLAKE2 can easily be replaced in this proposal. Potential alternatives are, for example:
- SHA-256: to avoid the introduction of a new hash function and for better hardware support
- [Troika](https://www.cyber-crypt.com/troika/)/[Kerl](https://github.com/iotaledger/kerl/blob/master/IOTA-Kerl-spec.md): to keep the entire Merkle tree hash computation in ternary.
