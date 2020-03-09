+ Feature name: `white-flag`
+ Start date: 2020-03-06
+ RFC PR: [iotaledger/protocol-rfcs#0005](https://github.com/iotaledger/protocol-rfcs/pull/5)

# Summary

This RFC is part of a set of protocol changes, [Chrysalis](https://roadmap.iota.org/chrysalis), aiming at improving the
network before [Coordicide](https://coordicide.iota.org/) is complete.

The feature presented in this RFC, White Flag, allows milestones to confirm conflicting bundles by enforcing
deterministic ordering of the Tangle and applying only the first bundle(s) that does not violate the ledger state.

The content of this RFC is based on [Conflict white flag: Mitigate conflict spamming by ignoring conflicts](https://iota.cafe/t/conflict-white-flag-mitigate-conflict-spamming-by-ignoring-conflicts/233).

# Motivation

<!-- TODO -->

The main motivations:

- Defend against censorship attacks - Conflicts will no longer block bundles from being approved.
- Make reattachments unnecessary - As long as the network is not saturated, theoretically all bundles should be
approved. And no bundle will be left behind.
- Increase TPS - Due to easy node tip selection the network throughput should increase.
- Increase CTPS - Due to the above, increase in TPS and no left-behinds, we expect CTPS to increase as well.

# Detailed design

<!-- TODO -->

Definitions:
- confirm
- ignored
- applied
- approve
- reference / indirectly

Let's define a conflicting bundle as a bundle that leads to a negative balance on an address if applied to the current
ledger state.

In case of conflicting bundles with White Flag, nodes will apply only one bundle to the ledger state and ignore all the
others. For this to work, nodes need to be sure they are all applying the same bundle; hence, the need for a
deterministic ordering of the Tangle.

First, this RFC propose a deterministic ordering of the Tangle, then it explain which bundle is selected in case of
conflict.

## Deterministic ordering of the Tangle

When a new milestone is broadcasted to the network, nodes will need to order the set of bundles it confirms that are
not already confirmed by any other milestone.

A subset of the Tangle can be ordered depending on many of its properties (e.g. alphanumeric sort of the bundle hashes);
however, to compute the ledger state, a graph traversal has to be done so we can use it to order the bundles in a
deterministic order with no extra overhead.

This ordering is then defined as the [topological ordering](https://en.wikipedia.org/wiki/Topological_sorting) generated
by a post-order [Depth-First Search (DFS)](https://en.wikipedia.org/wiki/Depth-first_search) starting from a milestone
and by going first through trunk bundles, then branch bundles and finally root bundles. Since only a subset of bundles
is considered, the stopping condition of the DFS is reaching bundles that are already confirmed by another milestone.

![][Tangle]

For example: the topological ordering of the set of bundles confirmed by milestone `V` (purple set) is then
`{D, G, J, L, M, R, I, K, N, O, S, V}`.

## Applying first bundle(s) that does not violate the ledger state

<!-- TODO -->

If a conflict was occurring in this set, nodes would confirm the first of the conflicting bundles and ignore the others.

- Start applying bundles to the diffmap only as you go up the recursion stack (when you climb up back from the leafs).
- Every time you attempt to apply a bundle to the diffmap:
If it is invalid, mark it as seen and ignored by the milestone.
If it is valid and not conflicting with the current state then apply it to the ledger state. Mark it as seen and
approved.
If it is valid but conflicting with the current state, mark it as seen and ignored by the milestone.

Note Once a bundle is marked as ignored/seen/approved this will be final and it can't be changed by a later milestone
that comes in.

![][Tangle-conflict]

## Pseudo-code

The below algorithm describes the process of updating the ledger state, updating the ledger state can be done whenever 
there are new known confirmed transactions, an arrival of a new milestone should trigger the update of the ledger state 
since the new milestone confirms many new transactions

Though the tangle is a graph made of transactions, we would like for the sake of this algorithm to consider it as a graph
of bundles where bundle is merely a collection of transactions sharing the same `bundle_hash` field and
pointing to each other via `trunk`  


UpdateLedgerState(newMilestone){


      let ledger be our global ledger state object
      let curr_bundle be the first bundle pointed by newMilestone's trunk
      let seen_bundles be stack
      seen_bundles.push( curr_bundle ) 
      mark curr_bundle as visited.
      while ( seen_bundles is not empty):
         curr_bundle  =  seen_bundles.top( )
         seen_bundles.pop( )
         
         if (!ledger.conflicts(curr_bundle)){
             ledger.apply(curr_bundle)
         }
         
        let bundle_trunk be the next bundle pointed by the trunk of the last transaction in curr_bundle
            if bundle_trunk is not visited :
                     seen_bundles.push( bundle_trunk )         
                    mark bundle_trunk as visited
                    
        let bundle_branch be the next bundle pointed by the branch of any transaction in curr_bundle
            if bundle_branch is not visited :
                     seen_bundles.push( bundle_branch )         
                    mark bundle_branch as visited
                    
}

[Tangle]: img/tangle.svg
[Tangle-conflict]: img/tangle-conflict.svg

# Drawbacks

<!-- TODO -->

- If we ever want to supply a proof that a value transfer is valid and approved, we can't do so by merely supplying the
path from the bundle to the approving milestone as before. A proof will require to have all the transactions that are in
the past cone of the approving milestone to the genesis. However, up until now we never required to give such proofs.
If we want to do easy proofs we can create merkle trees from approved bundle hashes and add them to milestones.
- Everything that is seen is part of the Tangle, including double-spend attempts. Meaning we define that possibly
malicious data will be saved as part of the consensus set of the Tangle.

# Rationale and alternatives

<!-- TODO -->

# Unresolved questions

<!-- TODO -->

Since nodes will try to sort out conflicts themselves perhaps it will be wise to add more protection against forks.
In a separate RFC we can maybe define additional data that can be added to milestones to prevent that.
