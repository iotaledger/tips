+ Feature name: `local_snapshot_file_format`
+ Start date: 2020-08-25
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

This RFC defines a file format for local snapshots which is compatible with Chrysalis Phase 2.

# Motivation

Nodes create local snapshots to produce ledger representations at a point in time of a given milestone to be able to:

* Start up from a recent milestone instead of having to synchronize from the genesis transaction.
* Delete old transaction data below a given milestone.

Current node implementations use
a [local snapshot file format](https://github.com/iotaledger/iri-ls-sa-merger/tree/351020d3b5e342b6e9a41f2868575ab7ff8c251c#generating-an-export-file-from-a-localsnapshots-db)
which only works with account based ledgers. For Chrysalis Phase 2, this file format has to be assimilated to support a
UTXO based ledger.

# Detailed design

Since a UTXO based ledger is much larger in size, this RFC proposes two formats for snapshot files:

* A `full` format which represents a complete ledger state.
* A `delta` format which only contains diffs (consumed and spent outputs) of milestones from a given milestone index
  onwards.

This separation allows nodes to swiftly create new delta snapshot files, which then can be distributed with a companion
full snapshot file to reconstruct a recent state.

Unlike the current format, these new formats do not include spent addresses since this information is no longer held by
nodes.

### Formats

> All types are serialized in little-endian

#### Full Ledger State

A full ledger snapshot file contains the UTXOs (`outputs` section) of a node's latest solid
milestone (`ledger_milestone_index`). The `diffs` contain the diffs to rollback the `outputs` state to regain the ledger
state of the snapshot milestone at (`seps_milestone_index`).

![](https://i.imgur.com/e6WuufK.png)

While the node producing such a full ledger state snapshot could theoretically pre-compute the actual snapshot milestone
state, this is deferred to the consumer of the data to speed up local snapshot creation.

A full ledger state local snapshot is denoted by the type byte `0`:

```
version<byte>
type<byte> = 0
timestamp<uint64>
network_id<uint64>
seps_milestone_index<uint64>
ledger_milestone_index<uint64>
seps_count<uint64>
outputs_count<uint64>
diffs_count<uint64>
treasury_output:
  milestone_hash<array[32]>
  amount<uint64>
seps<array[seps_count]>:
	sep<array[32]>
outputs<array[outputs_count]>:
    message_hash<array[32]>
    transaction_hash<array[32]>
    output_index<uint16>
    output:
        output_type<byte> = 0 // sig_locked_single_output
        address:
            address_type<byte> = 1
            ed25519_address<array[32]>
            ||
            ...
        value<uint64>
        ||
        output_type<byte> = 1 // sig_locked_dust_allowance_output
        address:
            address_type<byte> = 1
            ed25519_address<array[32]>
            ||
            ...
        value<uint64>
diffs<array[diffs_count]>:
    milestone_payload_length<uint32>
    milestone_payload<array[milestone_payload_length]>
    treasury_input (if milestone contains receipt):
            milestone_hash<array[32]>
            amount<uint64>
    created_outputs_count<uint64>
    created_outputs<array>:
        message_hash<array[32]>
        transaction_hash<array[32]>
        output_index<uint16>
        output:
            output_type<byte> = 0 // sig_locked_single_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
            ||
            output_type<byte> = 1 // sig_locked_dust_allowance_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
    consumed_outputs_count<uint64>
    consumed_outputs<array>:
        message_hash<array[32]>
        transaction_hash<array[32]>
        output_index<uint16>
        output:
            output_type<byte> = 0 // sig_locked_single_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
            ||
            output_type<byte> = 1 // sig_locked_dust_allowance_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
```

#### Delta Ledger State

A delta ledger state local snapshot only contains the `diffs` of milestones starting from a
given `ledger_milestone_index`. A node consuming such data must know the state of the ledger at `ledger_milestone_index`
.

![](https://i.imgur.com/bt5BUpe.png)

A delta ledger state local snapshot is denoted by the type byte `1`:

```
version<byte>
type<byte> = 1
timestamp<uint64>
network_id<uint64>
seps_milestone_index<uint64>
ledger_milestone_index<uint64>
seps_count<uint64>
diffs_count<uint64>
seps<array[seps_count]>:
	sep<array[32]>
diffs<array[diffs_count]>:
    milestone_payload_length<uint32>
    milestone_payload<array[milestone_payload_length]>
    treasury_input (if milestone contains receipt):
            milestone_hash<array[32]>
            amount<uint64>
    created_outputs_count<uint64>
    created_outputs<array>:
        message_hash<array[32]>
        transaction_hash<array[32]>
        output_index<uint16>
        output:
            output_type<byte> = 0 // sig_locked_single_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
            ||
            output_type<byte> = 1 // sig_locked_dust_allowance_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
    consumed_outputs_count<uint64>
    consumed_outputs<array>:
        message_hash<array[32]>
        transaction_hash<array[32]>
        output_index<uint16>
        output:
            output_type<byte> = 0 // sig_locked_single_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>
            ||
            output_type<byte> = 1 // sig_locked_dust_allowance_output
            address:
                address_type<byte> = 1
                ed25519_address<array[32]>
                ||
                ...
            value<uint64>          
```

# Drawbacks

Nodes need to support this new format.

# Rationale and alternatives

* In conjunction with a companion full snapshot, a tool or node can "truncate" the data from a delta snapshot back to a
  single full snapshot. In that case, the `ledger_milestone_index` and `seps_milestone_index` would be the same. In the
  example above, given the full and delta snapshots, one could produce a new full snapshot for milestone 1350.
* Since snapshots may include millions of UTXOs, code generating such files needs to stream data directly onto disk
  instead of keeping the entire representation in memory. In order to facilitate this, the count denotations for SEPs,
  UTXOs and diffs are at the beginning of the file. This allows code generating snapshot files to only have to seek back
  once after the actual count of elements is known.

# Unresolved questions

* Is all the information to startup a node from the local snapshot available with the described format?
* Can we get rid of the spent addresses or do we still need to keep them?
* Do we need to account for different types of outputs already? (we currently only have them deposit to addresses)