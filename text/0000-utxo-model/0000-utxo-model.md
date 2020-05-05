+ Feature name: `utxo-model`
+ Start date: 2020-05-04
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

The IOTA protocol uses an account model to keep track of the balances in the ledger state. This RFC describes and
discusses an alternative model - the UTXO model (Unspent Transaction Output) - that has several benefits over the
current model. 

# Motivation

Switching to a voting-based consensus requires a fast and easy way to determine a nodes initial opinion for every
received transaction. This includes the ability to detect double spends and transactions that try to spend non-existing
funds.

The current way of calculating the ledger state - by summing up all the balance changes in a transactions past cone -
does not scale very well because it requires loading and analyzing a large amount of transactions. Furthermore, it lacks
a reliable way of detecting double spends: We would have to constantly perform tip selections and "hope" that we happen
to combine two eventually conflicting sub-tangles. 

The UTXO model uses a different form of record keeping which enables the validation of transactions in constant time
`O(1)` and vastly improves the "expressiveness" of the ledger state by enabling things like:

+ **Colored Coins:** IOTA tokens can be marked with a certain "color". This color is retained throughout transfers and
gives the tokens a certain "meaning" (i.e. tokenized assets, ressource- and access-tokens ...).
  
+ **Scalable Layer1 Smart Contracts:** Balances can be extended by a sequence of dynamic unlock conditions that will
enable the use of a non-touring complete scripting language for smart contracts on layer1, which would not just be run
by a small committee of validators but by everybody. This will enable things like:

    + decentralized gambling
    
    + decentralized exchanges
    
    + hashed timelock contracts (enabling i.e. "lightning network"-like scaling)
    
    + regulatory compliant tokenized assets
    
    + and much more ...

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

Currently, an output is *unlocked* if there is a valid signature for the address that holds the output and it is not possible to define alternative conditions.

There are however use cases where being able to define additional conditions might be useful. A famous example are hashlocks and timelocks, that are used to create [Hashed Timelock Contracts](https://en.bitcoinwiki.org/wiki/Hashed_Timelock_Contracts) enabling things like atomic swaps and 2nd layer scaling solutions like the Lightning Network.

The opcode will allow us to build dynamic unlock methods that are checking additional conditions next to the 

# Drawbacks

The biggest drawback of this approach is the additional disk space it consumes to store the additional information. If
sweeping becomes a central part of the protocol with all wallets supporting it, then this solution will however most probably not perform much worse than an account-based ledger.

Considering how the ledger state is managed today, with several *checkpoints* where we *cache the ledger state* to reduce possible tangle walking time, it is however even possible that the resource consumption drops because we are no longer able

It does not introduce a new attack vector because it is already today possible to spread out small balances on 

# Rationale and alternatives

- Why is this design the best in the space of possible designs?
- What other designs have been considered and what is the rationale for not
  choosing them?
- What is the impact of not doing this?

# Unresolved questions

- What parts of the design do you expect to resolve through the RFC process
  before this gets merged?
- What parts of the design do you expect to resolve through the implementation
  of this feature before stabilization?
- What related issues do you consider out of scope for this RFC that could be
  addressed in the future independently of the solution that comes out of this
  RFC?
