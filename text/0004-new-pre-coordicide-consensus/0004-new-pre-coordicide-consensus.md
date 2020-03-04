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

Due to white-flag, no part of the tangle can be censored, thus the tangle can't be split by a double-spend. So as long as each new tip (bundle) a user creates approves two other random tips, the tangle shouldn't get divided into several subtangles. Thus we can get have a very fast tip selection by just selecting random tips.

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
All `seened` (by milestone) transaction that can be reached by walking from a given transaction down to its parents. The walk must terminate once we reached a `seened` transaction.

`Transaction Snapshot Index`:
The index of the milestone that marked the transaction as `seen`

`Oldest Transaction Root Snapshot`:
The milestone bundle with the lowest index that marked any of the Approved Transaction Roots as `seen`.

`Youngest Transaction Root Snapshot`:
The milestone bundle with the highest index that marked any of the Approved Transaction Roots as `seen`.



### Timestamp based scoring 

#### Configurable Values
<img src="/text/0004-new-pre-coordicide-consensus/tex/d81a84099e7856ffa4484e1572ceadff.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=22.465723500000017pt/> - Time in ms that a tip's timestamp can be *below* its solidification time.

<img src="/text/0004-new-pre-coordicide-consensus/tex/cb36b0b33747e686aaa07eae059aceae.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=24.7161288pt/> - Time in ms that a tip's timestamp can be *above* its solidification time.

<img src="/text/0004-new-pre-coordicide-consensus/tex/85f3e1190907b9a8e94ce25bec4ec435.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=22.465723500000017pt/> - Max difference between tip solidification time and parent bundle solidification timestamp.

<img src="/text/0004-new-pre-coordicide-consensus/tex/fb97d38bcc19230b0acd442e17db879c.svg?invert_in_darkmode&sanitize=true" align=middle width=17.73973739999999pt height=22.465723500000017pt/> - Max difference between tip solidification time and parent bundle signed timestamp.

#### Definitions
Let <img src="/text/0004-new-pre-coordicide-consensus/tex/7592e8ca3cc64009a29ef0fb58f65c76.svg?invert_in_darkmode&sanitize=true" align=middle width=28.11651809999999pt height=24.65753399999998pt/> be the signed timestamp and <img src="/text/0004-new-pre-coordicide-consensus/tex/c73b6615f0c7bd519371e439b4efff6d.svg?invert_in_darkmode&sanitize=true" align=middle width=30.05337719999999pt height=24.65753399999998pt/> the solidification time of transaction <img src="/text/0004-new-pre-coordicide-consensus/tex/332cc365a4987aacce0ead01b8bdcc0b.svg?invert_in_darkmode&sanitize=true" align=middle width=9.39498779999999pt height=14.15524440000002pt/>. A tip will be marked as <img src="/text/0004-new-pre-coordicide-consensus/tex/6c4adbc36120d62b98deef2a20d5d303.svg?invert_in_darkmode&sanitize=true" align=middle width=8.55786029999999pt height=14.15524440000002pt/> and its direct approved bundle tails are marked as <img src="/text/0004-new-pre-coordicide-consensus/tex/41922e474070adc90e7c1379c28d22fe.svg?invert_in_darkmode&sanitize=true" align=middle width=14.520613799999989pt height=14.15524440000002pt/> and <img src="/text/0004-new-pre-coordicide-consensus/tex/53292819177dbb29ba6d92fe3aa2880c.svg?invert_in_darkmode&sanitize=true" align=middle width=14.520613799999989pt height=14.15524440000002pt/>. Let <img src="/text/0004-new-pre-coordicide-consensus/tex/fb97d38bcc19230b0acd442e17db879c.svg?invert_in_darkmode&sanitize=true" align=middle width=17.73973739999999pt height=22.465723500000017pt/> be some large constant. <img src="/text/0004-new-pre-coordicide-consensus/tex/ca2b74b07b8264fbf88ce0db38c5b23b.svg?invert_in_darkmode&sanitize=true" align=middle width=29.482582799999992pt height=20.221802699999984pt/> is `Oldest Transaction Root Snapshot`:

#### Algorithm

Score 0 will be given if one of the following is true:
    
1. <img src="/text/0004-new-pre-coordicide-consensus/tex/387958f29c632656a8495107e16cf219.svg?invert_in_darkmode&sanitize=true" align=middle width=116.80582154999998pt height=24.65753399999998pt/> or <img src="/text/0004-new-pre-coordicide-consensus/tex/1b3ad4bd8eb7c4c75a64fe6e3af68ba3.svg?invert_in_darkmode&sanitize=true" align=middle width=116.80582154999998pt height=24.7161288pt/>
2. <img src="/text/0004-new-pre-coordicide-consensus/tex/f2059b96298c6ad5fe2faee5854c4f82.svg?invert_in_darkmode&sanitize=true" align=middle width=158.51217854999996pt height=24.65753399999998pt/>
3. All <img src="/text/0004-new-pre-coordicide-consensus/tex/9f7365802167fff585175c1750674d42.svg?invert_in_darkmode&sanitize=true" align=middle width=12.61896569999999pt height=14.15524440000002pt/> satisfy <img src="/text/0004-new-pre-coordicide-consensus/tex/a9915144fa53f2c0ab4fa14d0b57ed67.svg?invert_in_darkmode&sanitize=true" align=middle width=123.62570054999999pt height=24.65753399999998pt/>
4. if at least one <img src="/text/0004-new-pre-coordicide-consensus/tex/9f7365802167fff585175c1750674d42.svg?invert_in_darkmode&sanitize=true" align=middle width=12.61896569999999pt height=14.15524440000002pt/> has a score of 0 (to enforce monotonicity)

Else Score 1 will be given if exactly one <img src="/text/0004-new-pre-coordicide-consensus/tex/9f7365802167fff585175c1750674d42.svg?invert_in_darkmode&sanitize=true" align=middle width=12.61896569999999pt height=14.15524440000002pt/> satisfies <img src="/text/0004-new-pre-coordicide-consensus/tex/e0104a950fdef28a213187b01144c494.svg?invert_in_darkmode&sanitize=true" align=middle width=123.62570054999999pt height=24.65753399999998pt/>

Else Score 2 will be given.

#### Recommended defaults

<img src="/text/0004-new-pre-coordicide-consensus/tex/d81a84099e7856ffa4484e1572ceadff.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=22.465723500000017pt/> - 30 seconds

<img src="/text/0004-new-pre-coordicide-consensus/tex/cb36b0b33747e686aaa07eae059aceae.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=24.7161288pt/> - 30 seconds

<img src="/text/0004-new-pre-coordicide-consensus/tex/85f3e1190907b9a8e94ce25bec4ec435.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=22.465723500000017pt/> -  2 minutes

<img src="/text/0004-new-pre-coordicide-consensus/tex/fb97d38bcc19230b0acd442e17db879c.svg?invert_in_darkmode&sanitize=true" align=middle width=17.73973739999999pt height=22.465723500000017pt/> - 15 minutes

### Milestone based scoring

#### Configurable Values
<img src="/text/0004-new-pre-coordicide-consensus/tex/d81a84099e7856ffa4484e1572ceadff.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=22.465723500000017pt/> - The threshold for approving transactions with a root snapshot index that is below the latest solid one.

<img src="/text/0004-new-pre-coordicide-consensus/tex/85f3e1190907b9a8e94ce25bec4ec435.svg?invert_in_darkmode&sanitize=true" align=middle width=18.30139574999999pt height=22.465723500000017pt/> - Max difference between latest solid milestone index and parent <img src="/text/0004-new-pre-coordicide-consensus/tex/2d5da4c5f95e5b7b6808d42e6bff07d1.svg?invert_in_darkmode&sanitize=true" align=middle width=57.036576299999986pt height=22.465723500000017pt/>.

<img src="/text/0004-new-pre-coordicide-consensus/tex/fb97d38bcc19230b0acd442e17db879c.svg?invert_in_darkmode&sanitize=true" align=middle width=17.73973739999999pt height=22.465723500000017pt/> - Max difference between latest solid milestone index and current transaction <img src="/text/0004-new-pre-coordicide-consensus/tex/2d5da4c5f95e5b7b6808d42e6bff07d1.svg?invert_in_darkmode&sanitize=true" align=middle width=57.036576299999986pt height=22.465723500000017pt/>. Current below max depth parameter.

#### Definitions
Let <img src="/text/0004-new-pre-coordicide-consensus/tex/f807f11961854816fdf75186dad6ca17.svg?invert_in_darkmode&sanitize=true" align=middle width=57.170239499999994pt height=24.65753399999998pt/> be `Youngest Transaction Root Snapshot Index` for transaction <img src="/text/0004-new-pre-coordicide-consensus/tex/6c4adbc36120d62b98deef2a20d5d303.svg?invert_in_darkmode&sanitize=true" align=middle width=8.55786029999999pt height=14.15524440000002pt/> 

Let <img src="/text/0004-new-pre-coordicide-consensus/tex/77f9e9db2ab560d769b385212a3dd59a.svg?invert_in_darkmode&sanitize=true" align=middle width=56.48908484999999pt height=24.65753399999998pt/> be `Oldest Transaction Root Snapshot Index` for transaction <img src="/text/0004-new-pre-coordicide-consensus/tex/6c4adbc36120d62b98deef2a20d5d303.svg?invert_in_darkmode&sanitize=true" align=middle width=8.55786029999999pt height=14.15524440000002pt/>

Let <img src="/text/0004-new-pre-coordicide-consensus/tex/52ccf34a5ca5c00eb83a41321213e70f.svg?invert_in_darkmode&sanitize=true" align=middle width=33.03015044999999pt height=22.831056599999986pt/> be `Last solid milestone index` 

#### Algorithm

Score 0  will be given if one of the following is true:
 
1. <img src="/text/0004-new-pre-coordicide-consensus/tex/23e239ce29acec2ac8af89ee3bd1fe56.svg?invert_in_darkmode&sanitize=true" align=middle width=150.51060914999996pt height=24.65753399999998pt/>    
2. <img src="/text/0004-new-pre-coordicide-consensus/tex/6f13425189b1db19f58e22a67704c30a.svg?invert_in_darkmode&sanitize=true" align=middle width=149.26779449999998pt height=24.65753399999998pt/>    
3. both <img src="/text/0004-new-pre-coordicide-consensus/tex/9f7365802167fff585175c1750674d42.svg?invert_in_darkmode&sanitize=true" align=middle width=12.61896569999999pt height=14.15524440000002pt/> satisfy <img src="/text/0004-new-pre-coordicide-consensus/tex/aa72b54f7bb589cb6abf0f79acdba77c.svg?invert_in_darkmode&sanitize=true" align=middle width=154.7124744pt height=24.65753399999998pt/>
4. at least one <img src="/text/0004-new-pre-coordicide-consensus/tex/9f7365802167fff585175c1750674d42.svg?invert_in_darkmode&sanitize=true" align=middle width=12.61896569999999pt height=14.15524440000002pt/> has a score of 0 (to enforce monotonicity)

Else Score 1 will be given if exactly one <img src="/text/0004-new-pre-coordicide-consensus/tex/9f7365802167fff585175c1750674d42.svg?invert_in_darkmode&sanitize=true" align=middle width=12.61896569999999pt height=14.15524440000002pt/> satisfies <img src="/text/0004-new-pre-coordicide-consensus/tex/deca66392771e2f673e5d6ec62c126af.svg?invert_in_darkmode&sanitize=true" align=middle width=154.7124744pt height=24.65753399999998pt/>

Else Score 2 will given.

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
