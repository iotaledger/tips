+ Feature name: New Pre-Coordicide Consensus
+ Start date: 2020-02-10
+ RFC PR: [iotaledger/protocol-rfcs#0004](https://github.com/iotaledger/protocol-rfcs/pull/4)


# Summary

A change to the coordinator based protocol that should enable higher throughput of TPS and CTPS. It is achieved by doing the following changes:

1. **White Flag** - Allow milestones to confirm conflicting bundles. Mutate the ledger state by deterministically ordering the bundles and ignoring conflicts.
2. **New Node Tip Selection** - Nodes doing an almost random tip-selection will guarantee high throughputs and that honest txs will not likely be left behind. By adhering to certain constraints we will ensure that new transactions will add to the cumulative weight of existing transactions. A user will use `getTransactionsToApprove` API call with no parameters to invoke this tip selection.
3. **New Compass Tip Selection** - Compass will use a heuristic to confirm a subtangle that has passed a certain threshold of cumulative weight (WIP).

# Motivation

The main motivations:
1. **Defend against censorship attacks** - Conflicts will no longer block bundles from being approved.
2.  **Make reattachments unneccessary** - As long as the network is not saturated, theoretically all bundles should be approved. And no bundle will be left behind.
3. **Increase TPS** - Due to easy node tipselection the network throughput should increase.
4. **Increase CTPS** - Due to the above, increase in TPS and no left-behinds, we expect CTPS to increase as well. 


# Detailed design

## White-Flag

Let's define a `conflicting bundle` as a bundle that leads to a negative balance on an address if applied to the current ledger state.

When a milestone is accepted by a node then the following algorithm to mutate the ledger state is performed: 

1. Look for milestone whose index is the `current latest solid milestone index + 1`. Milestones must be applied in order!
1. When the milestone is found start traversing down the tangle in [DFS](https://en.wikipedia.org/wiki/Depth-first_search) going first to the trunk and only then the branch. Stop at the transactions that has only approved parents.
2. Start applying bundles to the diffmap only as you go up the recursion stack (when you climb up back from the leafs).
3. Every time you attempt to apply a bundle to the diffmap:
   - If it is invalid mark it as `seen` and `ignored` by the milestone. 
   - If it is valid and not conflicting with the current state then apply it to the ledger state. Mark it as `seen` and `approved`.
   - If it is valid but conflicting with the current state then place it in an ordered *Conflict Set*.
4. **Local overdraft handling**: After you are done traversing the subtangle attempt to apply again the conflicting bundles. Iterate the *Conflict Set* in order and attempt to apply the bundles to the ledger state. Mark the applied bundles as `seen` and `approved`. Remove applied bundles from the set. Repeat this step until the *Conflict Set* size doesn't change and mark the remaining bundles of the set as seen and ignored.

**Note**
Once a bundle is marked as ignored/seen/approved this will be final and it can't be changed by a later milestone that comes in.


## Node Tip Selection

Due to white-flag, no part of the tangle can be censored, thus the tangle can't be split by a double-spend. So as long as each new tip (bundle) a user creates approves two other random tips, the tangle shouldn't get divided into several subtangles. Thus we can have a very fast tip selection by just selecting random tips.

The problem is that lazy users may approve bundles or transactions that are not tips. This is a problem because lazy behavior can decrease confirmation rates: a lazy tip approves most likely a cone made up of bundles which are already confirmed and/or contains a low amount of non-yet confirmed, respectively recently broadcasted bundles. So we should have defenses in place to make sure that such lazy transactions will be left behind by honest tip-selection.

So instead of total random tip selection we will do a weighted random tip selection. We will give each tip a score:

```
0 - If it is a lazy tip that shouldn't be selected
1 - If it is a somewhat lazy tip
2 - If it is a non-lazy good tip.
```
Since the actual consensus will be determined by milestone tip selection there can be more than one way to distribute the scores.
We will propose two similar score systems that can be used by node implementations, a timestamp based one, and a milestone based one.

But first some definitions:

`Tip`:
A solid bundle tail of a bundle that has no approvers.

`Approved transaction Roots`:
All `seen` (by milestone) transactions that can be reached by traversing the past cone of a given transaction. We walk down via trunk and branch to all possible paths. The walk must terminate once we reached a `seen` transaction.

`Transaction Snapshot Index`:
The index of the milestone that marked the transaction as `seen`

`Oldest Transaction Root Snapshot`:
The milestone bundle with the lowest index that marked any of the Approved Transaction Roots as `seen`.

`Youngest Transaction Root Snapshot`:
The milestone bundle with the highest index that marked any of the Approved Transaction Roots as `seen`.



### Timestamp based scoring 
The idea of this proposal is to use the signed timestamp of a tip in conjunction with the solidification time of the tip in order to calculate its laziness score.

#### Configurable Values
$C_1$ - Time in ms that a tip's timestamp can be *below* its solidification time.

$C'_1$ - Time in ms that a tip's timestamp can be *above* its solidification time.

$C_2$ - Max difference between tip solidification time and approvee bundle solidification timestamp.

$M$ - Max difference between tip solidification time and approvee bundle signed timestamp.

#### Definitions
Let $t(x)$ be the signed timestamp and $r(x)$ the solidification time of transaction $x$. A tip will be marked as $v$ and its direct approved bundle tails are marked as $v_1$ and $v_2$. Let $M$ be some large constant. $otrs$ is `Oldest Transaction Root Snapshot`:

#### Algorithm

Score 0 (lazy) will be given if one of the following is true:
    
1. $t(v)<r(v)-C_1$ or $t(v)>r(v)+C'_1$
2. $r(v) - t(otrs(v))>M$
3. All $v_i$ satisfy $r(v)-r(v_i) > C_2$
4. if at least one $v_i$ has a score of 0 (to enforce monotonicity)

Else Score 1 (somewhat lazy) will be given if exactly one $v_i$ satisfies $r(v)-r(v_i) \leq C_2$

Else Score 2 (not lazy) will be given.

#### Recommended defaults

$C_1$ - 30 seconds

$C'_1$ - 30 seconds

$C_2$ -  2 minutes

$M$ - 15 minutes

### Milestone based scoring

#### Configurable Values
$C_1$ - The threshold for approving transactions with a root snapshot index that is below the latest solid one.

$C_2$ - Max difference between latest solid milestone index and parent $OTRSI$.

$M$ - Max difference between latest solid milestone index and current transaction $OTRSI$. Current below max depth parameter.

#### Definitions
Let $ytrsi(v)$ be `Youngest Transaction Root Snapshot Index` for transaction $v$ 

Let $otrsi(v)$ be `Oldest Transaction Root Snapshot Index` for transaction $v$

Let $lsmi$ be `Last solid milestone index` 

#### Algorithm

Score 0 (lazy) will be given if one of the following is true:
 
1. $lsmi-ytrsi(v)>C_1$    
2. $lsmi-otrsi(v)>M$    
3. both $v_i$ satisfy $lsmi-otrsi(v_i)>C_2$
4. at least one $v_i$ has a score of 0 (to enforce monotonicity)

Else Score 1 (somewhat lazy) will be given if exactly one $v_i$ satisfies $lsmi -otrsi(v_i) \leq C_2$

Else Score 2 (not lazy) will given.

##### Recommended defaults

$C_1$ - 2

$C_2$ -  7

$M$ - 15 minutes

#### Performing the weighted random selection
A node should have in memory the entire set of `tips` and their scores:

1. Sum up the total score of the tips.
2. Pick a random number, `r` between 1 and the sum.
3. Traverse through the set of tips and subtract the score of each tip from `r`. Stop when you reach 0 or lower.

## Compass Tip Selection
TBD


# Drawbacks

## White Flag
1. If we ever want to supply a proof that a `value transfer` is valid and approved, we can't do so by merely supplying the path from the bundle to the approving milestone as before. A proof will require to have all the transactions that are in the past cone of the approving milestone to the genesis. However, up until now we never required to give such proofs. If we want to do easy proofs we can create merkle trees from approved bundle hashes and add them to milestones.
2. Everything that is `seen` is part of the tangle, including double-spend attempts. Meaning we define that possibly malicious data will be saved as part of the consensus set of the tangle.

## Node Tip Selection
1. Timestamp proposal relies on local values that differ from node to node. This can theoretically cause some tips to appear lazy to certain nodes in the network, but not lazy to others. This may lead to competing subtangles, thus the the milestone proposal is superior. However node implementations that would like to later switch to Coordicide may still consider implementing it.

2. With both proposals users may have to reattach if they create lazy tips. This is not so bad, because honest users should never create lazy tips unless they encounter access barriers to the network, i.e. bad connection or a congested network.

## Compass Tip Selection
TBD

# Rationale and alternatives

- The previous design tried to stay as close as it can to the design outlined by the [original iota whitepaper](https://assets.ctfassets.net/r1dr6vzfxhev/2t4uxvsIqk0EUau6g2sw0g/45eae33637ca92f85dd9f4a3a218e1ec/iota1_4_3.pdf). Due to the pivot to [Coordicide](https://files.iota.org/papers/Coordicide_WP.pdf) it was decided to find a design that can maximize the benefits of the current coordinator based mainnet in the meanwhile. The design proposed here embraces the power of the coordinator rather than utilizing it as an auxiliary tool intended to be removed. This will give us all the benefits described in [motivation](#motivation).

# Unresolved questions

## Whiteflag
Since nodes will try to sort out conflicts themselves perhaps it will be wise to add more protection against forks. In a separate RFC we can maybe define additional data that can be added to milestones to prevent that.

## Node Tip Selection
There can be an alternative definition to a `tip` elligible for selection: 
``
A **valid** solid bundle tail that has no approvers or all of its approvers are also invalid bundles. 
``
Note that under this new definition that if we attach a new valid bundle `B` to an invalid solid `tip`, then `B` may become an elligible `tip` with a positive `score`.

The advantage of this new definition is that we will walk around invalid bundles with honest tip-selection. So it may offset one of the drawbacks of white-flag. We will keep less junk in consensus.
The downside is that we will have to incur validation costs as new bundles are coming in and this may slow down TPS...


## Compass Tip Selection
- TBD
