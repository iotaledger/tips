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
balances associated to **outputs** that are the result of transactions moving funds and that can be addressed and spent
individually. The transaction ID that created the output together with some _additional identifier_ that distinguishes
different outputs from the same transaction, uniquely identifies every output.

Bitcoin (who introduced the UTXO model) uses the
numerical index of the output inside a transaction as this *additional identifier*. It does not actually have a concept
of balances belonging to addresses, and providing a signature for a certain address is simply a special type of
*unlocking condition* for this particular output. This is a very generic way of keeping track of balances that is to a
certain degree even agnostic to the use of addresses as the main way of interacting with such a system.

Even though Bitcoin has this kind of inherent agnosticism towards using addresses, it has proven to be extremely
beneficial to at least have some form of *logical identifier* that groups related outputs together and that can also be
used to *authorize* payments in the form of address signatures. It is for that very reason that the predominant part of
transaction executed on today's DLTs make use of addresses.

To build a bridge between the two worlds of *UTXO-* and *account-based* ledgers, we define our own UTXO variant, that
still makes addresses a central building block (like in an account model) but without sacrificing the *expressiveness*
of a UTXO-based ledger:

## The Basic Design

Instead of simply storing the balances associated to their addresses (like in the current ledger state), we now store balances associated to an `Output` 
An `Output`

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
