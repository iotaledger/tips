---
title: Local Snapshot File Format
tags: RFC, draft
---

+ Feature name: `local_snapshot_file_format`
+ Start date: 2020-08-25
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

This RFC defines a file format for local snapshots which is compatible with Chrysalis Phase 2.

# Motivation

Nodes create local snapshots to produce ledger representations at a point in time of a given milestone in order to be able to:
* start up from a recent milestone instead of having to synchronize from genesis
* delete transaction data below the given milestone

Current node implementations use a [local snapshot file format](https://github.com/iotaledger/iri-ls-sa-merger/tree/351020d3b5e342b6e9a41f2868575ab7ff8c251c#generating-an-export-file-from-a-localsnapshots-db) which only works with account based ledgers. For Chrysalis Phase 2 this file format has to be assimilated to support a UTXO based ledger.

# Detailed design

All types are serialized in little-endian and occur in the sequence of the rows defined below.

This format describes version 1:
<table>
    <tr>
        <th>Name</th>
        <th>Type</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Version</td>
        <td>byte</td>
        <td>
        The version of the local snapshot file format.
        </td>
    </tr> 
    <tr>
        <td>Timestamp</td>
        <td>uint64</td>
        <td>
        The UNIX epoch timestamp in seconds of when this snapshot was created.
        </td>
    </tr>
    <tr>
        <td>Milestone Index</td>
        <td>uint64</td>
        <td>
        The index of the milestone of the local snapshot.
        </td>
    </tr>
    <tr>
        <td>Milestone Hash</td>
        <td>ByteArray[32]</td>
        <td>
        The BLAKE2b-256 hash of the milestone payload.
        </td>
    </tr>
    <tr>
        <td>SEPs Count</td>
        <td>uint64</td>
        <td>
        The amount of solid entry points contained within the file.
        </td>
    </tr> 
    <tr>
        <td>UTXOs Count</td>
        <td>uint64</td>
        <td>
        The amount of transactions and their outputs contained within the file.
        </td>
    </tr>
    <tr>
        <td>SEPs</td>
        <td>Array[ByteArray[32]]</td>
        <td>
        The BLAKE2b-256 hashes of the SEP messages at the cut off point of the given milestone. There are <code>SEPs Count</code> SEPs in this array.
        </td>
    </tr>
    <tr>
        <td>UTXOs</td>
        <td colspan="2">
            <details open="true">
                <summary>Array[UTXO]</summary>
                <p>
                Describes the unspent transaction outputs per transaction. There are <code>UTXOs Count</code> transactions in this array.
                </p>
                <table>
                    <tr>
                        <td><b>Name<b></td>
                        <td><b>Type</b></td>
                        <td><b>Description</b></td>
                    </tr>
                    <tr>
                        <td>Transaction Hash</td>
                        <td>ByteArray[32]</td>
                        <td>The BLAKE2b-256 hash of the transaction.</td>
                    </tr>
                    <tr>
                        <td>
                        Unspent Outputs
                        </td>
                        <td colspan="2">
                            <details open="true">
                                <summary>Array[Outputs]</summary>
                                <p>
                                This array is prefixed with an uint16 denoting the amount of outputs.
                                </p>
                                <table>
                                    <tr>
                                        <td>Index</td>
                                        <td>byte</td>
                                        <td>The index of the output on the transaction.</td>
                                    </tr>
                                    <tr>
                                        <td valign="top">Address <code>oneOf</code></td>
                                        <td colspan="2">
                                            <details>
                                                <summary>WOTS Address</summary>
                                                <table>
                                                    <tr>
                                                        <td><b>Name<b></td>
                                                        <td><b>Type</b></td>
                                                        <td><b>Description</b></td>
                                                    </tr>
                                                    <tr>
                                                        <td>Address Type</td>
                                                        <td>byte/varint</td>
                                                        <td>
                                                            Set to <strong>value 0</strong> to denote a <i>WOTS Address</i>.
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>Address</td>
                                                        <td>ByteArray[49]</td>
                                                        <td>The T5B1 encoded WOTS address.</td>
                                                    </tr>
                                                </table>
                                            </details>
                                            <details>
                                                <summary>Ed25519 Address</summary>
                                                <table>
                                                    <tr>
                                                        <td><b>Name<b></td>
                                                        <td><b>Type</b></td>
                                                        <td><b>Description</b></td>
                                                    </tr>
                                                    <tr>
                                                        <td>Address Type</td>
                                                        <td>byte/varint</td>
                                                        <td>
                                                            Set to <strong>value 1</strong> to denote an <i>Ed25519 Address</i>.
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>Address</td>
                                                        <td>ByteArray[32]</td>
                                                        <td>The raw bytes of the Ed25519 address which is a BLAKE2b-256 hash of the Ed25519 public key.</td>
                                                    </tr>
                                                </table>
                                            </details>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>Value</td>
                                        <td>uint64</td>
                                        <td>The output value.</td>
                                    </tr>
                                </table>
                            </details>
                        </td>
                    </tr>
                </table>
            </details>
        </td>
    </tr>
</table>

# Drawbacks

Nodes need to support this new format.

# Rationale and alternatives

* Since local snapshots may include millions of UTXOs, code generating such files needs to stream data directly onto disk instead of keeping the entire representation in memory. In order to facilitate this, the count denotations for SEPs and UTXOs are at the beginning of the file. This allows code generating local snapshot files to only have to seek back once after the actual count of elements is known.
* If a design were to be used where the corresponding SEPs and UTXOs arrays are directly prefixed with their count, the generating code would have to seek multiples to override the counts with the count only known after having generated all elements.
* Grouping the UTXOs per transaction reduces the file size.
* No compression is used since for example only a 13% reduction (~134 MB -> ~120 MB) on a local snapshot with ~2 million outputs (on Ed25519 addresses) from ~1 million transactions and 150 SEPs is achieved.

Unlike the current format, this new format does no longer include:
* Spent addresses: since this information is no longer held by nodes.
* Seen milestones: as they can be requested via protocol messages.

# Unresolved questions

* Is all the information to startup a node from the local snapshot available with the described format?
* Can we get rid of the spent addresses or do we still need to keep them?
* Are the sizes of the count denotations for the arrays sensible?
* Do we need to account for different types of outputs already? (we currently only have them deposit to addresses)