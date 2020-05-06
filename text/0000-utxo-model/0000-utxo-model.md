+ Feature name: `utxo-model`
+ Start date: 2020-05-04
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

The IOTA protocol uses an account model to keep track of the balances in the ledger state. This RFC describes and
discusses an alternative model - the UTXO model (Unspent Transaction Output) - that has several benefits over the
current model. 

# Motivation

Switching to a voting-based consensus requires a fast and easy way to determine a node's initial opinion for every
received transaction. This includes the ability to detect double spends and transactions that try to spend non-existing
funds.

The current way of calculating the ledger state - by summing up all the balance changes in a transactions past cone -
does not scale very well because it requires loading and analyzing a large amount of transactions. Furthermore, it lacks
a reliable way of detecting double spends: We would have to constantly perform tip selections and "hope" that we happen
to combine two eventually conflicting sub-tangles. 

The UTXO model uses a different form of record keeping which enables the validation of transactions in constant time
`O(1)` and vastly improves the "expressiveness" of the ledger state by enabling things like:

+ **Colored Coins:** IOTA tokens can be marked with a certain "color". This color is retained throughout transfers and
gives the tokens a certain "meaning" (i.e. tokenized assets, resource- and access-tokens ...).
  
+ **Scalable Layer1 Smart Contracts:** Balances can be extended by a sequence of dynamic unlock conditions that will
enable the use of a non-touring complete scripting language for smart contracts on layer1, which would not just be run
by a small committee of validators but by everybody. This will enable things like:

    + decentralized gambling
    
    + decentralized exchanges
    
    + hashed time lock contracts (enabling i.e. "lightning network"-like scaling)
    
    + regulatory compliant tokenized assets
    
    + ...

# Detailed design

Instead of keeping track of aggregated balances per address, the **Unspent Transaction (TX) Output** model stores
balances associated to **outputs** that are the result of individual transactions moving funds and that can be addressed
and spent individually. This allows to exactly specify which funds are getting moved even if multiple parties are
funding an address in parallel.

A transaction moving funds consists out of three building blocks:

- the ``Inputs`` which defines a list of ``OutputIDs`` that reference the *consumed* ``Outputs`` from previous
  transactions (or the genesis).
- the ``Outputs`` which defines where and how many of the consumed tokens are moved.
- the ``Unlock Section`` that contains data used to *unlock* the consumed inputs and *authorize* spends (usually just
the address signatures - more on that later).

The following diagram shows how transactions consume outputs as inputs to create new outputs for future transactions:

![sdf](images/utxo_flow_of_funds.png)

### Output IDs

The transaction ID that creates the output together with some _additional identifier_ that distinguishes different
outputs from the same transaction uniquely identifies every output.

Bitcoin (who introduced the UTXO model) uses the numerical index of the output inside a transaction as this
*additional identifier*. It does not actually have a concept of balances belonging to addresses, and providing a
signature for a certain address is simply a special type of *unlocking condition* for this particular output. This is a
very generic way of keeping track of balances that is to a certain degree even agnostic to the use of addresses as the
main way of interacting with such a system.

Even though Bitcoin has this kind of inherent agnosticism towards using addresses, it has proven to be extremely
beneficial to at least have some form of *logical identifier* that groups related outputs together and that can also be
used to *authorize* payments in the form of address signatures. It is for that very reason that the predominant part of
transaction executed on today's DLTs make use of addresses.

To build a bridge between the worlds of *UTXO-* and *account-based* ledgers, we define our UTXO variant to use
addresses instead of output indexes as this additional identifier:

``OutputID = Pair<Address, TransactionID>``

All **colored balances** sent to the same address (by the same transaction) become part of the same output.

### Colored Balances

To be able to support tokenized assets on layer1 without the need for touring-complete smart contracts, we do not just
use a numeric value to represent a balance, but instead allow balances to have an additional **color** which can be
used to give coins a *meaning*.

A **color** is simply a random sequence of bytes that can be set by the user and which is retained when being
transferred:

``Color = Array<byte>``

Next to *user defined* colors, there are two *builtin color* values that carry a special meaning:

- ``COLOR_IOTA = Array<byte>(0, 0, 0, ..., 0)`` represents the *base color* of uncolored coins.

- ``COLOR_MINT = Array<byte>(255, 255, 255, ..., 255)`` represents a color which is being replaced by the
  ``Transaction ID`` before being booked as an output. It is consequently used to "mint" new colored coins.

A **colored balance** is accordingly a combination of a numeric balance with its corresponding color:

``ColoredBalance = {Balance: uint64, Color: Color}``

### Outputs

An Output is a container for the colored balances that were spent by a particular transaction to a certain address. In
addition to the list of colored balances and its ID, we store an ``OPCode`` and a corresponding ``OPCodeMetadata``.

``Output = {ID: OutputID, Balances: Array<ColoredBalance>, OpCode: OPCode, OPCodeMetadata: Array<byte>}``

### OPCodes

Currently, an output is *unlocked* if there is a valid signature for the address that holds the output, and it is not
possible to define alternative conditions.

There are however use cases where being able to define different conditions might be useful. A famous example are hash
locks and time locks, that are used to create
[Hashed Timelock Contracts](https://en.bitcoinwiki.org/wiki/Hashed_Timelock_Contracts) enabling things like atomic swaps
and 2nd layer scaling solutions like the Lightning Network.

The opcode is a single byte that is mapped to a specific unlock method. This will allow us to switch between different
unlock conditions which introduces some very basic smart contract capabilities on the base layer.

``OPCode = byte``

Since some opcodes might require certain parameters (like a timestamp or a hash), we define a metadata field, that holds
a marshaled version of these parameters.

``OPCodeMetadata = Array<byte>`` 

As long as these checks are not much more *expensive* than signature checks, it does not introduce problems but
massively extends the functionality of the protocol. We have to however be very careful with adding new conditions, to
not accidentally introduce potential bottlenecks.

In contrast to bitcoin, we do not add a fully scriptable outputs (because that could result in long execution times),
but we offer predefined methods for different use cases.

For now, we simply reserve the additional fields in the Output but hard code the OPCode to be ``SIG_CHECK = OPCode(0)``.

### Conflict Detection

The biggest benefits of this ledger state is the fast and easy detection of double spends and invalid transaction:

- A transaction is valid, if the sum of the moved funds is ``0`` and it only spends colors in the amounts that were
available in the used inputs. It is however possible to override the color of the consumed tokens using either the
``MINT_COLOR`` color to create a new colored token or by using the ``IOTA_COLOR`` to remove the color.

  Instead of having to walk through multiple transaction to eventually find the spent balance in the tangle, we can now
instantly load the corresponding funds by accessing the consumed outputs. A transaction that tries to spend non-existing
funds would never become solid.

- Accordingly, a transaction is performing a double spend when there is already another transaction consuming the same
output.

# Drawbacks

The drawbacks of this approach are:

- A UTXO-based ledger is much more complex in the implementation than just a dictionary of balances.
- A UTXO-based ledger stores more information and therefore requires "potentially" more disk space.
  
  However, if
sweeping becomes a central part of the protocol with all wallets supporting it, then this solution will most
probably not perform much worse than an account-based ledger.

  Considering how we store ledger state today, with several *checkpoints* where we *cache the ledger state* to reduce
  possible tangle walking time, it might also be possible that the resource consumption drops because we are no longer
  required to have these additional checkpoints with their corresponding ledger state (in memory and on disk).

  In general, it does not introduce a new attack vector because it is already today possible to spread out small
  balances onto many addresses, which is the equivalent of spreading a lot of outputs on a single address.

# Rationale and alternatives

There are currently only two options for a ledger state, that are known - the UTXO model, and the account model.

The account-model does not work very well with "parallelism" (i.e. multiple people sending funds to the same
address). We can never be sure, that our transaction has seen all the funds and the only way to make sure, that this is
the case is to use the tangle structure to define a *scope* for a spend. This however is very slow, because the only way
to use the tangle structure is to walk around in the tangle. In addition, it adds additional constraints to the tip
selection as it requires to have the correct funding transactions in the past cone of a spending transaction.

Considering the "parallel" nature of the tangle, it seems like UTXO is the only possible choice. Using addresses as the
additional identifier for outputs, allows us to bundle multiple colored balances in a single output, which leads to a
smaller fragmentation of the funds as if we would give every color a separate output.

If we decide to not go with this approach, then we will essentially limit ourselves to just a few hundred TPS because of
the massive overhead of checking incoming transactions. In addition, the conflict detection will be much harder.

# Unresolved questions

- We need to think about good unlock opcodes and options.
- We should define a PR that specifies the "parallel branch" based ledger state as this is very closely related to the
use of UTXO.