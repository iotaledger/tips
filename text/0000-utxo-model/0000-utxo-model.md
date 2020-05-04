+ Feature name: `utxo-model`
+ Start date: 2020-05-04
+ RFC PR: [iotaledger/protocol-rfcs#0000](https://github.com/iotaledger/protocol-rfcs/pull/0000)

# Summary

The IOTA protocol uses an account model to keep track of the balances in the ledger state. This RFC describes and discusses an alternative model - the UTXO model (Unspent Transaction Output) - that has several benefits over the current model. 

# Motivation

Switching to a voting-based consensus requires a fast and easy way to determine a nodes initial opinion for every received transaction. This includes the ability to detect double spends and transactions that try to spend non-existing funds.

The current way of calculating the ledger state - by summing up all the balance changes in a transactions past cone - does not scale very well because it requires loading and analyzing a large amount of transactions. Furthermore, it lacks a reliable way of detecting double spends: We would have to constantly perform tip selections and "hope" that we happen to combine two "eventually" conflicting subtangles. 

The UTXO model uses a different form of record keeping which enables the validation of transactions in constant time `O(1)` and vastly improves the "expressiveness" of the ledger state by enabling things like:

+ **Colored Coins:** IOTA tokens can be marked with a certain "color". This color is retained throughout transfers and gives the tokens a certain "meaning" (i.e. tokenized assets, ressource- and access-tokens ...).
  
+ **Scalable Layer1 Smart Contracts:** Balances can be extended by a sequence of dynamic unlock conditions that will allow us to define a non-touring complete scripting language for smart contracts on layer1, which would not just be run by a small comittee of validators but by everybody. This will enable things like:
    + decentralized gambling
    
    + decentralized exchanges
    
    + hashed timelock contracts (enabling i.e. "lightning network"-like scaling)
    
    + regulatory compliant tokenized assets
    
    + and much more ...

# Detailed design

Instead of simply keeping track of the balances on an address, the UTXO model stores every single balance that was created.


This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the IOTA and to understand, and for somebody familiar with Rust
to implement. This should get into specifics and corner-cases, and include
examples of how the feature is used.

# Drawbacks

Why should we *not* do this?

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
