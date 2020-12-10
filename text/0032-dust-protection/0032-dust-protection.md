+ Feature name: dust-protection
+ Start date: 2020-12-07
+ RFC PR: [iotaledger/protocol-rfcs#0032](https://github.com/iotaledger/protocol-rfcs/pull/0032)


# Summary

This RFC defines a new protocol rule regarding processing outputs that transfer a small amount of Iotas, known as dust outputs. The rule states that each dust output should be backed up by a deposit of the receiving address. Thus making it expensive to proliferate dust. Since a receiver must make a deposit, the protocol makes receiving dust an opt-in feature.

# Motivation

The total supply of IOTA is approximately 2.78 peta IOTA. Considering that a single typical `SigLockedSingleOutput` takes 42 bytes (just the plain output bytes without the encompassing transaction), it is easy to see how the size of the UTXO set may pose a potential problem. An attacker splitting 1 GI to single iota outputs can blow up the set size so that it won't fit into 4GB of RAM. This is far from being a prohibitively expensive attack.

Thus, in order to protect nodes from such memory attacks we should make accumulating small dust outputs expensive. Other DLTs have fees that provide protection, but IOTA is feeless. So instead of fees we can have deposits. 

When an address wants to receive micro transactions it must have a special output locked as a deposit. This deposit can't be consumed by any transaction as long as the dust outputs exist on the address. This also prevents attackers from sending dust to addresses that didn't opt into allowing dust outputs.

Additional benefit of this rule is that it makes a mass of privacy violating [forced address reuse attacks](https://en.bitcoin.it/wiki/Privacy#Forced_address_reuse) more expensive to carry out.


# Detailed design

### Definitions

*Dust*: a UTXO that spends an amount smaller than 1 MI.

*SigLockedDustAllowanceOutput* - A new output type for deposits that allow an address to recieve dust outputs. It can be consumed as an input like a regular SigLockedOutput.

<table>
                                    <tr>
                                        <td><b>Name</b></td>
                                        <td><b>Type</b></td>
                                        <td><b>Description</b></td>
                                    </tr>
                                    <tr>
                                        <td>Output Type</td>
                                        <td>uint8</td>
                                        <td>
                                            Set to <strong>value 1</strong> to denote a <i>SigLockedDustAllowanceOutput</i>.
                                        </td>
                                    </tr>
                                    <tr>
                                        <td valign="top">Address </td>
                                        <td colspan="2">
                                                                     <details>
                                                <summary>Ed25519 Address</summary>
                                                <table>
                                                    <tr>
                                                        <td><b>Name</b></td>
                                                        <td><b>Type</b></td>
                                                        <td><b>Description</b></td>
                                                    </tr>
                                                    <tr>
                                                        <td>Address Type</td>
                                                        <td>uint8</td>
                                                        <td>
                                                            Set to <strong>value 1</strong> to denote an <i>Ed25519 Address</i>.
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>Address</td>
                                                        <td>Array&lt;byte&gt;[32]</td>
                                                        <td>The raw bytes of the Ed25519 address which is a BLAKE2b-256 hash of the Ed25519 public key.</td>
                                                    </tr>
                                                </table>
                                            </details>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>Amount</td>
                                        <td>uint64</td>
                                        <td>The amount of tokens to deposit with this <i>SigLockedSingleOutput</i> output.</td>
                                    </tr>
                                </table>


### The new protocol dust rule

Let `A` be the address that should hold the dust outputs' balances. Let `M` be the sum of all SigLockedDustAllowanceOutputs' values on `A`.So the total allowed dust outputs on `A` is (`M`/1 MIOTA) * 100 rounded down to the nearest integer. So 100 outputs for 1 MIOTA deposited.

The SigLockedDustAllowanceOutput must be greater or equal to 1MI.

If while processing a milestone a new dust UTXO is created but there is not a sufficient amount already locked in SigLockedDustAllowanceOutputs then the encompassing message should be marked as `ignored`.

If while processing a milestone an unspent SigLockedDustAllowanceOutput is consumed and as a result we have a violation on the number of allowed dust outputs then the encompassing message should be marked as `ignored`.

The checks should happen after the entire message was processed. Messages that were previously applied by the current milestone are taken into account.


# Drawbacks

1. We can't have an address that will ever hold less than 1 MI. It will be a bit hard on testnet faucets but still workable.
2. A service receiving micropayments may fail receiving them if it didn't consolidate dust outputs or raised the deposit for the address.

# Rationale and alternatives

Other solutions that were discussed:

*Burning Dust* - allow dust to live for a limited amount of time on the ledger before removing it from total supply.

*Sweeping dust into merkle tree* - Instead of storing all of the dust in the UTXO set, some nodes can accumulate the dust outputs to a merkle tree root. When the dust is spent, those nodes will require a merkle proof of inclusion.

The first solution has some attack vectors that may burn dust that a user may have wanted to consolidate. Also solutions changing the supply can be quite controversial.

The second solution, besides being more complicated, will relief the problem from one class of nodes but not all nodes.


# Unresolved questions

- An attacker may try to fill an address with dust to fill the total cap allowed and block honest senders that want to pay the service. The service can protect by simply consolidating the attacker dust and collecting it for profit. The problem is that if the cost of doing PoW too often may exceed the bad dust profit. Perhaps it is a good idea to limit "tiny" (1 i) dust outputs more than larger dust outputs? In the original discussion each dust class was supposed to be capped to a certain fixed amount. Perhaps we should give weights to different dust classes? So "tiny" dust will weigh more and fill the cap more quickly than larger dust?

- Total cap per address so db key won't be polluted... should this be part of the RFC? This also depends on how key-value dbs will behave at the implementation level. RocksDb for example can configured to handle this well.

- If we stay with the naive linear scheme, is 100 outputs per 1MI is really our choice?