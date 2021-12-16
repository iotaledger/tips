+ Feature name: `serialization-primitives`
+ Start date: 2021-11-22
+ RFC PR: [iotaledger/protocol-rfcs#0041](https://github.com/iotaledger/protocol-rfcs/pull/0041)

# Summary

This document introduces the primitives and concepts that are used throughout the IOTA protocol RFCs to describe the binary serialization of objects.

# Motivation

Prior to this document, each RFC contained its own section and version describing the serialization of its objects. This RFC introduces consistent serialization concepts and avoids duplication in other RFCs.

# Detailed design
## Schemas

Serializable objects are represented by a _schema_. Each schema consists of a list of _fields_, which each have a name and a type. The type of a field can either be a simple data type or another schema, then called subschema.

### Data types

All the supported data types are described in the following table:

| Name         | Description                                                                   |
| ------------ | ----------------------------------------------------------------------------- |
| uint8        | An unsigned 8-bit integer encoded in Little Endian.                           |
| uint16       | An unsigned 16-bit integer encoded in Little Endian.                          |
| uint32       | An unsigned 32-bit integer encoded in Little Endian.                          |
| uint64       | An unsigned 64-bit integer encoded in Little Endian.                          |
| uint256      | An unsigned 256 bits integer encoded in Little Endian.                        |
| ByteArray[N] | A static size byte array of N bytes.                                          |
| ByteArray    | A dynamically sized byte array. A leading uint32 denotes its length in bytes. |

### Subschemas

In order to create complex schemas, one or multiple subschemas can be included into an outer schema. The keywords that describe the allowed combinations of such subschemas is described in the following table:

| Name              | Description                                         |
| ----------------- | --------------------------------------------------- |
| `oneOf`           | One of the listed subschemas.                       |
| `optOneOf`        | One of the listed subschemas or none.               |
| `anyOf`           | Any (one or more) of the listed subschemas.         |
| `optAnyOf`        | Any (one or more) of the listed subschemas or none. |
| `atMostOneOfEach` | At most one of each of the listed subschemas.       |
