---
tip: ?
title: IOTA DID Method Specification v2.0
description: Specifies how DID are stored in the IOTA ledger
author:
  Eike Haß (@eike-hass) <eike.hass@iota.org>, Abdulrahim Al Methiab (@abdulmth) <abdulrahim.almethiab@iota.org>, Enrico Marconi (@UMR1352) <enrico.marconi@iota.org>
status: Draft
type: Informational
created: 2024-02-27
---

# IOTA DID Method Specification v2.0

## Abstract

The IOTA DID Method Specification describes a method of implementing the [Decentralized Identifiers](https://www.w3.org/TR/did-core/) (DID) standard on [IOTA](https://iota.org), a Distributed Ledger Technology (DLT). It conforms to the [DID specification v1.0](https://www.w3.org/TR/did-core/) and describes how to perform Create, Read, Update and Delete (CRUD) operations for IOTA DID Documents using unspent transaction outputs (_UTXO_) on IOTA **2.0** networks using the Nova _( :warning: todo: link)_ VM.

## Data Types & Subschema Notation

Data types and subschemas used throughout this TIP are defined in [TIP-21](../TIP-0021/tip-0021.md).

## Introduction

### UTXO Ledger

The unspent transaction output ([UTXO](../TIP-0020/tip-0020.md)) model defines a ledger state which is comprised of unspent outputs. Outputs are created by a transaction consuming outputs of previous transactions as inputs. The Nova version of the protocol defines several output types, the relevant ones for the IOTA DID Method are: Basic Outputs for _value transactions_, and Account Outputs for storage of DID Documents.

All outputs must hold a minimum amount of tokens to be stored on the ledger. For output types that can hold arbitrary data, for instance the Account Output, the amount of tokens held by the output must cover the byte cost of the data stored. This prevents the ledger size from growing uncontrollably while guaranteeing that the data is not pruned from the nodes, which is important for resolving DID Documents. This deposit is fully refundable and can be reclaimed when the output is destroyed.

Data stored in an output and covered by the storage deposit will be stored in _all_ nodes on the network and can be retrieved from any node. This provides strong guarantees for any data stored in the ledger.

### IOTA 2.0

At the heart of IOTA 2.0 is the Tangle, our Directed Acyclic Graph (DAG) architecture where blocks are interconnected in a non-linear manner and confirm each other, unlike conventional blockchains that rely on miners and transaction fees. By combining unique value propositions, IOTA 2.0 is a decentralized, egalitarian, and sustainable DLT. Read me more about IOTA 2.0 [here](https://wiki.iota.org/learn/protocols/iota2.0/introduction-to-digital-autonomy/).

### Account Output

[Accounts](https://github.com/iotaledger/tips/blob/tip42/tips/TIP-0042/tip-0042.md) are the central component of the Nova ledger that allows block issuance, staking, delegation and data storage.
Some of its relevant properties are:

- **Amount**: the amount of IOTA coins held by the output.
- **Mana**: the amount of Stored Mana held by the output.
- **Account ID**: unique identifier of the account, which is the BLAKE2b-256 hash of the Output ID that created it.
- **Unlock Conditions**: defines the addresses that can unlock and spend the output.
  - Ed25519 Address
  - Account Address
  - NFT Address
  - Anchor Address
  - :warning: Multi Address
  - :warning: Restricted Address
- **Features**
  - Metadata Feature: defines a map of key-value pairs that is stored in the output. Defined in [TIP-38](https://github.com/iotaledger/tips/blob/tip38/tips/TIP-0038/tip-0038.md#metadata-feature).

#### Chain Constraint in UTXO

Consuming an Account Output in a transaction may transition it into the next state. The current state is defined as the consumed Account Output, while the next state is defined as the Account Output with the same explicit AccountID on the output side.

### Mana

Mana is the resource required to access the IOTA ledger and update its state by creating blocks. As a spendable resource that is tracked in the ledger state, mana can be obtained in several ways, like generated by holding IOTA coins, or purchased from other Mana holders. Mana will be burned each time a block is issued. Lean more about Mana [here](https://github.com/iotaledger/tips/blob/tip39/tips/TIP-0039/tip-0039.md).

### Ledger and DID

Storing DID Documents in the ledger state means they inherently benefit from the guarantees the ledger provides.

1. Conflicts among nodes are resolved and dealt with by the ledger.
1. Replay attacks are mitigated since transactions need to be confirmed by the ledger.

## DID Method Name

The `method-name` to identify this DID method is `iota`.

A DID that uses this method MUST begin with the following prefix: `did:iota`. Following the generic DID specification, this string MUST be lowercase.

## DID Format

The DIDs that follow this method have the following ABNF syntax. It uses the syntax in [RFC5234](https://www.rfc-editor.org/rfc/rfc5234) and the corresponding definition for `digit`.

```
iota-did = "did:iota:" iota-specific-idstring
iota-specific-idstring = [ iota-network ":" ] iota-tag
iota-network = 1*6network-char
iota-tag = "0x" 64lowercase-hex
lowercase-hex = digit / "a" / "b" / "c" / "d" / "e" / "f"
network-char = %x61-7A / digit ; corresponds to the character range from "a" to "z" and "0" to "9".
```

It starts with the string "did:iota:", followed by an optional network name (1 to 6 lowercase alpha characters) and a colon, then the tag.
The tag starts with "0x" followed by a hex-encoded `Account ID` with lower case a-f.

### IOTA-Network

The iota-network is an identifier of the network where the DID is stored. This network must be an IOTA Ledger, but can either be a public or private network, permissionless or permissioned.

The following values are reserved and cannot reference other networks:

1. `iota` references the main network which refers to the ledger known to host the IOTA cryptocurrency.
1. `atoi` references the development network of IOTA.
1. `smr` references the shimmer network.
1. `rms` references the development network of Shimmer.

When no IOTA network is specified, it is assumed that the DID is located on the `iota` network. This means that the following DIDs will resolve to the same DID Document:

```
did:iota:iota:0xe4edef97da1257e83cbeb49159cfdd2da6ac971ac447f233f8439cf29376ebfe
did:iota:0xe4edef97da1257e83cbeb49159cfdd2da6ac971ac447f233f8439cf29376ebfe
```

### IOTA-Tag

An IOTA-tag is a hex-encoded `Account ID`. The `Account ID` itself is a unique identifier of the account, which is the BLAKE2b-256 hash of the Output ID that created it.
This tag identifies the Account Output where the DID Document is stored, and it will not be known before the generation of the DID since it will be assigned when the Account Output is created.

### Anatomy of the Metadata Feature

The DID Document is stored within a Metadata Entry of the Metadata Feature in the Account Output. The Key of the Metadata Entry MUST be `did:iota` and the Value of the Metadata Entry MUST be a byte packed payload with header fields as follows:

| Name          | Type              | Description                                                                                                                                              |
| ------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Version       | uint8             | Set value **1** to denote the version number of this method                                                                                              |
| Encoding      | uint8             | Set value to **0** to denote JSON encoding without compression.                                                                                       |
| Payload       | (uint16)ByteArray | A DID Document and its metadata, where every occurrence of the DID in the document is replaced by `did:0:0`. It must be encoded according to `Encoding`. |

The types are defined in [TIP-21](../TIP-0021/tip-0021.md#data-types).

#### Payload

The payload must contain the following fields:

- `meta`: contains metadata about the DID Document. For example, `created` to indicate the time of creation, and `updated` to indicate the time of the last update to the document. It may also include other properties.
- `doc`: contains the DID Document. In the example below, the document only contains one verification method. The `id` and `controller` is specified by `did:0:0` which references the DID of the document itself, since the DID is unknown at the time of publishing. It also deduplicates the DID of the document to reduce the size of the state metadata, in turn reducing the required storage deposit.

Example State Metadata Document:

```json
{
  "doc": {
    "id": "did:0:0",
    "verificationMethod": [
      {
        "id": "did:0:0#jkGOGVO3Te7ADpvlplr47eP9ucLt41zm",
        "controller": "did:0:0",
        "type": "JsonWebKey",
        "publicKeyJwk": {
          "kty": "OKP",
          "alg": "EdDSA",
          "kid": "jkGOGVO3Te7ADpvlplr47eP9ucLt41zm",
          "crv": "Ed25519",
          "x": "D5w8vG6tKEnpBAia5J4vNgLID8k0BspHz-cVMBCC3RQ"
        }
      }
    ],
    "authentication": ["did:0:0#jkGOGVO3Te7ADpvlplr47eP9ucLt41zm"]
  },
  "meta": {
    "created": "2023-08-28T14:49:37Z",
    "updated": "2023-08-28T14:50:27Z"
  }
}
```
Notes: 
- Can we derive the metadata (created and/or updated) from the ledger metadata? Created only with the help archival nodes I assume?

## Controllers

The address set as the unlock condition has control over the Account Output and consequently the DID. For the Account Output, only one address can be set, hence the DID can have only one controller. [Multi Address](https://github.com/iotaledger/tips/blob/tip52/tips/TIP-0052/tip-0052.md) can be set to allow multiple controllers.

## CRUD Operations

Create, Read, Update and Delete (CRUD) operations that change the DID Documents are done through transactions on the tangle.

**These operations require fund transfer to cover byte cost. Transactions must be carefully done in order to avoid fund loss.** For example, the amount of funds in the inputs should equal these in the outputs. Additionally, private keys of controllers must be stored securely.

Writing transactions additionally require [Mana](#Mana).

### Create

In order to create a simple DID two things are required:

1. An Ed25519 Address for which the private key is available, or control over a Basic, NFT or Account Output.

1. A Basic, Account, NFT or Anchor Output with enough coins to cover the byte cost.

Creation steps:

1. Create the content of the DID Document like verification methods, services, etc.
1. Create the payload and the headers as described in the [Anatomy of the Metadata Feature](#anatomy-of-the-metadata-feature).
1. Create a new Account Output with the payload and the headers stored in its `Metadata Feature` under the `did:iota` key.
1. Set the unlock conditions to the address that should control the DID.
1. Set enough tokens in the output to cover the byte cost.
1. Publish a new transaction with an existing output that contains at least the required storage deposit as input, and the newly created Account Output as output.

Once the transaction is confirmed, the DID is published and can be formatted by using the `Account ID` as the tag in [DID Format](#did-format).

### Read

The following steps can be used to read the latest DID Document associated with a DID.

1. Obtain the `Account ID` from the DID by extracting the `iota-tag` from the DID, see [DID Format](#did-format).
1. Obtain the network of the DID by extracting the `iota-network` from the DID, see [DID Format](#did-format).
1. Query the Account Output corresponding to the `Account ID` using a node running the [inx indexer](https://github.com/iotaledger/inx-indexer). Nodes usually include this indexer by default.
1. Assert that the extracted network matches the one returned from the node. Return an error otherwise.
1. Assert that the `Account ID` of the returned output matches the `Account ID` extracted from the DID. Return an error otherwise.
1. Assert that the output includes a `Metadata Feature`. Return an error otherwise.
1. Retrieve the value of the `Metadata Feature` field from the returned output.
1. Validate that the `Key` `did:iota` exists in one of the metadata `Entries`. Return an error otherwise.
1. Retrieve the `Value` that corresponds to the `Key` `did:iota`.
1. Validate that the contents of the retrieved `Value` match the structure described in [Anatomy of the Metadata Feature](#anatomy-of-the-metadata-feature). Return an error otherwise.
1. Decode the DID Document from the retrieved `Entry` value.
1. Replace the placeholder `did:0:0` with the DID given as input.
1. If the Account is controlled by one or more Accounts, construct a IOTA DID from their `Account ID`s and and add them to [controller field](https://www.w3.org/TR/did-core/#did-controller) in the DID document.

### Update

Updating a DID Document can be achieved by a transaction of the Account Output with the updated content:

1. Create a copy of the Account Output with the same `Account ID` set explicitly.
1. Pack the updated DID Document, as described in the [Anatomy of the Metadata Feature](#anatomy-of-the-metadata-feature), into the `Metadata Feature` of the output under the key `did:iota`.
1. Set the `amount` of coins sufficient to cover the byte cost.
1. Publish a new transaction that includes the current Account Output as input (along with any required Outputs to consume to cover the `amount`, if increased) and the updated one as output.

### Delete

#### Deactivate

Temporarily deactivating a DID can be done by deleting the `Metadata Entry` corresponding to the key `did:iota` in the Account Output, and publishing an [update](#update).

Another option is to [update](#update) the DID Document and set the `deactivated` property in its `metadata` to true. In both cases, the deactivated DID Document will be marked as `deactivated` when resolved.

Since retrieving the history of an Account to detect if an Account ever was a DID is unpractical, any Account Output lacking a `Metadata Entry` with a `did:iota` Key is considered a deactivated DID. The same applies for Account Outputs lacking the Metadata Feature.

#### Destroy

In order to permanently destroy a DID, a new transaction can be published that consumes the Account Output without having a corresponding Account Output on the output side with the same explicit `Account ID`. This results in destroying the Alias Output and the DID.

Note that this operation irreversibly and irrecoverably deletes the DID. This is because the `Account ID` from which an IOTA DID is derived (see [IOTA-Tag](#iota-tag)) is generated from the hash of the input transaction that created it, which cannot practically be replicated.

## IOTA Identity standards

The `did:iota` method is implemented in the [IOTA Identity framework](https://github.com/iotaledger/identity.rs). This framework supports a number of operations that are standardized, some are standardized across the SSI community, and some are the invention of the IOTA Foundation.

### Revocation

Revocation of verifiable credentials and signatures can be achieved using the Revocation Bitmap 2022 where issuers store a bitmap of indices in the DID Document. These indices correspond to verifiable credentials they have issued. If the binary value of the index in the bitmap is 1 (one), the verifiable credential is revoked, if it is 0 (zero) it is not revoked.

### Standardized Services

The IOTA Identity framework also standardized certain services that are embedded in the DID Document. It is RECOMMENDED to implement these when implementing the did:iota method.

Currently standardized services:

    Revocation Bitmap Service

## Migration

Instructions to migrate DIDs stored on the Stardust version of the network to Nova:

1. Detect all Alias Outputs containing a leading "DID" magic bytes in the ByteArray of their State Metadata.
1. For each of those Alias Output in Stardust, create an Account Output in Nova where `Alias ID` = `Account ID`.
1. Set a Metadata Feature in the created Account Output with an Entry where:
   - `Key` = `did:iota`
   - `Value` = a copy of Alias Output's State Metadata ByteArray without the leading "DID" magic bytes.

If migrated Alias Output is self-governed:

1. Set Account Unlock to migrated Alias Unlock

Else:

1. Set Account Unlock condition to MultiAddress where:
    - migrated Alias Output state controller address is set with weight=1
    - migrated Alias Output governor controller address is set with weight=1
    - Threshold=1

Notes: 
- Alternatively only migrate the governor controller and discard the state controller. We should probably align that with the default behavior for non-DID Alias Outputs.


## Security Considerations

The `did:iota` method is implemented on the [IOTA](https://iota.org), a public permissionless Distributed Ledger Technology (DLT), making it resistant against almost all censorship attack vectors.

### Private Key Management

All private keys or seeds used for the `did:iota` method should be equally well protected by the users. Private keys for the unlock condition of the Account are especially important as they control how keys are added or removed, providing full control over the identity. The IOTA Identity framework utilizes the [Stronghold project](https://github.com/iotaledger/stronghold.rs), a secure software implementation isolating digital secrets from exposure to hacks or leaks. Developers may choose to add other ways to manage the private keys in a different manner.

## Privacy Considerations

### Personal Identifiable Information

The public IOTA and Shimmer networks are immutable. This means that once something is included, it can never be completely removed. For example, destroying an Account Output will remove it from the ledger state, but it can still be stored in permanodes or by any party that records historical ledger states.

That directly conflicts with certain privacy laws such as GDPR, which have a 'right-to-be-forgotten' for Personal Identifiable Information (PII). As such, users should NEVER upload any PII, including inside DID Documents. While verifiable credentials can be made public, this should only be utilized by Identity for Organisations and Identity for Things.

### Correlation Risks

As with any DID method, identities can be linked if they are used too often and their usage somehow becomes public. See [DID Correlation Risks](https://www.w3.org/TR/did-core/#did-correlation-risks). Additionally, a DID can be correlated with funds if the Account Output used to store the DID Document or any of its controllers is used for holding, transferring or controlling coins or NFTs.

## Document History

**v2.0**

The major different between v1.0 and v2.0 of this document is using the Account Output instead of the Alias Output to adapt the Nova update of the network.

1. The DID is derived from the `Account ID` instead of the `Alias ID`.
1. DID Document is stored in Metadata Feature instead of State Metadata.
1. Use Metadata Feature Entry Key `did:iota` instead of the magic byte "DID".
1. State Index and State controllers are removed.
1. Governor controller are replaced with Address Unlock Condition.