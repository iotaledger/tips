# IOTA Protocol RFCs

> This process is modelled after the approach taken by the Rust programming
language, see [Rust RFC repository] for more information. Also see
[maidsafe's RFC process] for another project in the crypto space.
Our approach is taken and adapted from these.

To propose changes to the IOTA protocol, we ask for these to go through a more
organized design process --- an *RFC* (request for comments) process. The goal
is to organize work between the different developers affiliated with the IOTA
Foundation, and the wider open source community. We want to vet the ideas early
on, get and give feedback, and only then start the implementation once the
biggest questions are taken care of.

## What is *substantial* and when to follow this process

You need to follow this process if you want to propose changes that affect the IOTA protocol. These are changes that would affect any underlying node software.

+ Anything that constitutes a breaking change to the protocol that would have to be adopted by each node software operating on the network in order to keep participating in the network.
+ Any proposed additional change to the protocol that could be adopted any node software.

Some changes do not require an RFC:

+ Changes to the individual node software implementations - if that is the case, follow the IRI and Bee RFC processes.

## The workflow of the RFC process

To make a change to the IOTA protocol, one must first get the RFC
merged into the RFC repository as a markdown file. At that point the RFC is
"active" and may be implemented with the goal of eventual inclusion into any node software. 

+ Fork the RFC repository
+ Copy `0000-template.md` to `text/0000-my-feature/0000-my-feature.md` (where
  "my-feature" is descriptive; don't assign an RFC number yet; extra documents
  such as graphics or diagrams go into the new folder).
+ Fill in the RFC. Put care into the details: RFCs that do not present
  convincing motivation, demonstrate lack of understanding of the design's
  impact, or are disingenuous about the drawbacks or alternatives tend to be
  poorly-received.
+ Submit a pull request. As a pull request the RFC will receive design feedback
  from the larger community, and the author should be prepared to revise it in
  response.
+ Each pull request will be labeled with the most relevant sub-team, which will
  lead to its being triaged by that team in a future meeting and assigned to
  a member of the subteam.
+ Build consensus and integrate feedback. RFCs that have broad support are much
  more likely to make progress than those that don't receive any comments. Feel
  free to reach out to the RFC assignee in particular to get help identifying
  stakeholders and obstacles.
+ The sub-team will discuss the RFC pull request, as much as possible in the
  comment thread of the pull request itself. Offline discussion will be
  summarized on the pull request comment thread.
+ RFCs rarely go through this process unchanged, especially as alternatives and
  drawbacks are shown. You can make edits, big and small, to the RFC to clarify
  or change the design, but make changes as new commits to the pull request,
  and leave a comment on the pull request explaining your changes.
  Specifically, do not squash or rebase commits after they are visible on the
  pull request.
+ At some point, a member of the subteam will propose a "motion for final
  comment period" (FCP), along with a disposition for the RFC (merge, close, or
  postpone).
    + This step is taken when enough of the tradeoffs have been discussed that
      the subteam is in a position to make a decision. That does not require
      consensus amongst all participants in the RFC thread (which is usually
      impossible). However, the argument supporting the disposition on the RFC
      needs to have already been clearly articulated, and there should not be
      a strong consensus against that position outside of the subteam. Subteam
      members use their best judgment in taking this step, and the FCP itself
      ensures there is ample time and notification for stakeholders to push
      back if it is made prematurely.
    + For RFCs with lengthy discussion, the motion to FCP is usually preceded
      by a summary comment trying to lay out the current state of the
      discussion and major tradeoffs/points of disagreement.
    + Before actually entering FCP, all members of the subteam must sign off;
      this is often the point at which many subteam members first review the
      RFC in full depth.
+ The FCP lasts ten calendar days, so that it is open for at least 5 business
  days. It is also advertised widely, e.g. on discord or in a blog post. This
  way all stakeholders have a chance to lodge any final objections before
  a decision is reached.
+ In most cases, the FCP period is quiet, and the RFC is either merged or
  closed. However, sometimes substantial new arguments or ideas are raised, the
  FCP is canceled, and the RFC goes back into development mode.

## The RFC life-cycle

Once an RFC becomes active then authors may implement it and submit the feature
as a pull request to the repo. Being "active" is not a rubber stamp and in
particular still does not mean the feature will ultimately be merged. It does
mean that in principle all the major stakeholders have agreed to the feature
and are amenable to merging it.

Furthermore, the fact that a given RFC has been accepted and is "active"
implies nothing about what priority is assigned to its implementation, nor does
it imply anything about whether a developer has been assigned the task of
implementing the feature. While it is not necessary that the author of the RFC
also write the implementation, it is by far the most effective way to see an
RFC through to completion. Authors should not expect that other project
developers will take on responsibility for implementing their accepted feature.

Modifications to active RFCs can be done in follow up PRs. We strive to write
each RFC in a manner that it will reflect the final design of the feature,
however, the nature of the process means that we cannot expect every merged RFC
to actually reflect what the end result will be at the time of the next major
release. We therefore try to keep each RFC document somewhat in sync with the
network feature as planned, tracking such changes via followup pull requests to
the document.

An RFC that makes it through the entire process to implementation is considered
"implemented" and is moved to the "implemented" folder. An RFC that fails after
becoming active is "rejected" and moves to the "rejected" folder.

## Reviewing RFCs

While the RFC pull request is up, the sub-team may schedule meetings with the
author and/or relevant stakeholders to discuss the issues in greater detail,
and in some cases the topic may be discussed at a sub-team meeting. In either
case a summary from the meeting will be posted back to the RFC pull request.

A sub-team makes final decisions about RFCs after the benefits and drawbacks
are well understood. These decisions can be made at any time, but the sub-team
will regularly issue decisions. When a decision is made, the RFC pull request
will either be merged or closed. In either case, if the reasoning is not clear
from the discussion in thread, the sub-team will add a comment describing the
rationale for the decision.

## Implementing an RFC

Some accepted RFCs represent vital features that need to be implemented right
away. Other accepted RFCs can represent features that can wait until some
arbitrary developer feels like doing the work. Every accepted RFC has an
associated issue tracking its implementation in the affected repositories.
Therefore, the associated issue can be assigned a priority via the triage
process that the team uses for all issues in the appropriate repositories.

The author of an RFC is not obligated to implement it. Of course, the RFC
author (like any other developer) is welcome to post an implementation for
review after the RFC has been accepted.

If you are interested in working on the implementation for an "active" RFC, but
cannot determine if someone else is already working on it, feel free to ask
(e.g. by leaving a comment on the associated issue).

## RFC postponement

Some RFC pull requests are tagged with the "postponed" label when they are
closed (as part of the rejection process). An RFC closed with "postponed" is
marked as such because we want neither to think about evaluating the proposal
nor about implementing the described feature until some time in the future, and
we believe that we can afford to wait until then to do so. Historically,
"postponed" was used to postpone features until after 1.0. Postponed pull
requests may be re-opened when the time is right. We don't have any formal
process for that, you should ask members of the relevant sub-team.

Usually an RFC pull request marked as "postponed" has already passed an
informal first round of evaluation, namely the round of "do we think we would
ever possibly consider making this change, as outlined in the RFC pull request,
or some semi-obvious variation of it." (When the answer to the latter question
is "no", then the appropriate response is to close the RFC, not postpone it.)

## Help! This is all too informal

The process is intended to be as lightweight as reasonable for the present
circumstances. As usual, we are trying to let the process be driven by
consensus and community norms, not impose more structure than necessary.

# Contributions, license, copyright

This IRI network library is licensed under Apache License, Version 2.0,
([LICENSE-APACHE] or http://www.apache.org/licenses/LICENSE-2.0). Any
contribution intentionally submitted for inclusion in the work by you, as
defined in the Apache-2.0 license, shall be licensed as above, without any
additional terms or conditions.

[maidsafe's RFC process]: https://github.com/maidsafe/rfcs
[LICENSE-APACHE]: https://github.com/iotaledger/bee-rfcs/blob/master/LICENSE-APACHE
[Rust RFC repository]: https://github.com/rust-lang/rfcs
