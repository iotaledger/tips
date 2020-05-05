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
and spent individually. This allows us to exactly specify which funds are getting moved even if multiple parties are
funding an address in parallel.

A transaction moving funds consists out of three building blocks:

- the ``Inputs`` which defines a list of ``OutputIDs`` that reference the *consumed* ``Outputs`` from previous transactions
or the genesis.
- the ``Outputs`` which defines where the consumed tokens are moved.
- the ``Unlock Section`` that contains data used to *unlock* the consumed inputs and *authorize* spends (usually just
the address signatures - more on that later).

The following diagram shows how transactions consume outputs as inputs to create new outputs for future transactions:

![sdf](images/utxo_flow_of_funds.png)

### Output IDs

The transaction ID that created the output together with some _additional identifier_ that distinguishes
different outputs from the same transaction uniquely identifies every output.

Bitcoin (who introduced the UTXO model) uses the
numerical index of the output inside a transaction as this *additional identifier*. It does not actually have a concept
of balances belonging to addresses, and providing a signature for a certain address is simply a special type of
*unlocking condition* for this particular output. This is a very generic way of keeping track of balances that is to a
certain degree even agnostic to the use of addresses as the main way of interacting with such a system.

Even though Bitcoin has this kind of inherent agnosticism towards using addresses, it has proven to be extremely
beneficial to at least have some form of *logical identifier* that groups related outputs together and that can also be
used to *authorize* payments in the form of address signatures. It is for that very reason that the predominant part of
transaction executed on today's DLTs make use of addresses.

To build a bridge between the two worlds of *UTXO-* and *account-based* ledgers, we define our UTXO variant to use
addresses as this additional identifier:

``OutputID = Pair<Address, TransactionID>`

### Transactions and Outputs

A tra

Transactions in a UTXO based ledger have the following 

### Colored Balances

To be able to support tokenized assets on layer1 without the need for touring-complete smart contracts, we allow
balances to have a *color* which can be used to give coins an *additional meaning*. A **color** is simply a random
sequence of bytes that can be set by the user and which is retained when being transferred:

``Color = Array<byte>``

Next to *user defined* colors, there are two *builtin color* values that carry a special meaning:

- ``COLOR_IOTA = Array<byte>(0, 0, 0, ..., 0)`` represents the *base color* of uncolored coins. It can be used to address 

- ``COLOR_MINT = Array<byte>(255, 255, 255, ..., 255)``

  represents a color which is being replaced by the ``Transaction ID`` before booking an output in the ledger state.
  It is consequently used to "mint" new colored coins.

A **colored balance** is now simply the tuple of a balance and its corresponding color:

``ColoredBalance = struct{Balance: uint64, Color: []byte}``

### Outputs

An Output is a list of colored balances that where created by a particular transaction on a certain
address. In addition to the list of balances we store an *opcode* 

``Output = []ColoredBalance``



# Drawbacks

Bigger ledger state

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
