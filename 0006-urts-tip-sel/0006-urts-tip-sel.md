+ Feature name: `urts-tip-sel`
+ Start date: 2020-03-09
+ RFC PR: [iotaledger/protocol-rfcs#0006](https://github.com/iotaledger/protocol-rfcs/pull/0006)

# Summary

URTS tip-selection enables a node to perform fast tip-selection to increase transaction throughput.
The algorithm selects tips which are non-lazy in order to maximize confirmation rate.

# Motivation

Because of the `white-flag` confirmation algorithm, it is no longer necessary to perform complex
tip-selection which evaluates ledger mutations while walking, therefore, a simpler and better 
performing algorithm can be used to select tips, which in turn increases overall transaction throughput.

In order to maximize confirmation rate however, the algorithm needs to return tips which are `non-lazy`.
Non-lazy in this context means, that a tip does not attach to a cone of transactions which is too far
in the past, as such cone is likely to be already confirmed and therefore doesn't contribute to the
rate of newly confirmed transactions when a milestone is issued.

# Detailed design

Definitions:
* A `tip` is a tail transaction of a bundle without any approvers.
* A `score` is a scoring  determining the likeliness to select a given `tip`.
* `Confirmed Root Transactions` defines the set of first seen transactions which are confirmed by a previous milestone 
when we walk the past cone of a given transaction. The walk stops on confirmed transactions.  
Yellow = `Confirmed Root Transactions` for PoV transaction, Red = Milestone, Blue = PoV transaction.
![sdf](./images/cnf_tx_roots.PNG)
* `Transaction Snapshot Index (TSI)` defines the index of the milestone which confirmed a given transaction.
* `Oldest Transaction Root Snapshot Index (OTRSI)` defines the lowest milestone index of a given set of
`Confirmed Root Transactions` of a given transaction.
* `Youngest Transaction Root Snapshot Index (YTRSI)` defines the highest milestone index of a given set of
`Confirmed Root Transactions` of a given transaction.

OTRSI / YTRSI example:
Given the blue point of view transaction, the `OTRSI` of it is milestone 1 and `YTRSI` milestone 2.
![sdf](./images/otrsi_ytrsi.PNG)

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