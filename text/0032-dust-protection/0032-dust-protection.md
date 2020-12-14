+ Feature name: dust-protection
+ Start date: 2020-12-07
+ RFC PR: [iotaledger/protocol-rfcs#0032](https://github.com/iotaledger/protocol-rfcs/pull/0032)


# Summary
In the UTXO model, each node in the network needs to keep track of all the currently unspent outputs. When the number of outputs gets too large, this can cause performance and memory issues.
This RFC defines a new protocol rule regarding processing outputs that transfer a small amount of Iotas, known as dust outputs. The rule states that each dust output should be backed up by a deposit of the receiving address. Thus making it expensive to proliferate dust. Since a receiver must make a deposit, the protocol makes receiving dust an opt-in feature.

# Motivation

The total supply of IOTA is approximately 2.78 peta IOTA. Considering that a single typical `SigLockedSingleOutput` takes 42 bytes (just the plain output bytes without the encompassing transaction), it is easy to see how the size of the UTXO set may pose a potential problem. An attacker splitting 1 GI to single iota outputs can blow up the set size so that it won't fit into 4GB of RAM. This is far from being a prohibitively expensive attack.

In order to protect nodes from such attacks, one possible solution is to make accumulating dust outputs expensive. Since IOTA does not have any fees that might limit the feasibility of issuing many dust transactions, deposits pose a valid alternative to achieve a similar effect.

When an address is supposed to receive micro transactions, it must have an unspent output of a special type as a deposit. This deposit cannot be consumed by any transaction as long as the dust outputs remain unspent.

An additional benefit of this rule is that it makes a mass of privacy violating [forced address reuse attacks](https://en.bitcoin.it/wiki/Privacy#Forced_address_reuse) more expensive to carry out.


# Detailed design

### Definitions

*Dust output*: A transaction output that has an amount smaller than 1 Mi

*SigLockedDustAllowanceOutput*: A new output type for deposits that enables an address to receive dust outputs. It can be consumed as an input like a regular `SigLockedSingleOutputs`.

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
    <td valign="top">Address</td>
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
    <td>The amount of tokens to deposit with this <i>SigLockedDustAllowanceOutput</i> output.</td>
  </tr>
</table>


### Validation

Let `A` be the address that should hold the dust outputs' balances. Let `M` be the sum of all SigLockedDustAllowanceOutputs' values on `A`.So the total allowed dust outputs on `A` is (`M`/1 MIOTA) * 100 rounded down to the nearest integer. So 100 outputs for 1 MIOTA deposited.

The SigLockedDustAllowanceOutput must be greater or equal to 1MI.

If while processing a milestone a new dust UTXO is created but there is not a sufficient amount already locked in SigLockedDustAllowanceOutputs then the encompassing message should be marked as `ignored`.

If while processing a milestone an unspent SigLockedDustAllowanceOutput is consumed and as a result we have a violation on the number of allowed dust outputs then the encompassing message should be marked as `ignored`.

The checks should happen after the entire message was processed. Messages that were previously applied by the current milestone are taken into account.


# Drawbacks

- There can no longer be addresses holding less than 1 Mi.
- A service receiving micropayments may fail receiving them, if it did not consolidate dust outputs or raised the deposit for the receiving address.

# Rationale and alternatives

There are potential alternatives to introducing dust deposits:

- *Burning dust*: Allow dust outputs to exists only for a limited amount of time in the ledger. After this, they are removed completely and the associated funds are invalidated.
- *Sweeping dust into Merkle trees*: Instead of burning dust outputs after some time, they are instead compressed into a Merkle tree and only the tree root is kept. In order to spend one of these compressed outputs, the corresponding Merkle audit path needs to be supplied in addition to a regular signature.

The first option can cause issues, when dust outputs were burned before users could consolidate them. Also, changing the supply can be controversial.

The second option is much more complicated as it introduces a completely new unlock mechanisms and requires the nodes to store the Merkle tree roots indefinitely.


# Unresolved questions

- An attacker can send microtransactions to an address with a `SigLockedDustAllowanceOutput` in order to fill the allowed threshold and block honest senders of microtransactions. The owner of the address can mitigate this by simply consolidating the attacker's dust and collecting it for profit. The problem is that the cost of doing PoW too often may exceed the profit made by collecting dust. Perhaps it is a good idea to limit "tiny" (1 i) dust outputs more than larger dust outputs? In the original discussion each dust class was supposed to be capped to a certain fixed amount. But perhaps we should give weights to different dust classes. So "tiny" dust will weigh more and fill the cap more quickly than larger dust?

- Total cap per address so db key won't be polluted... should this be part of the RFC? This also depends on how key-value dbs will behave at the implementation level. RocksDb for example can configured to handle this well.

- If we stay with the naive linear scheme, is 100 outputs per 1MI is really our choice?