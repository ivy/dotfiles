# Epic workflow

Work spanning multiple PRs or sessions. The rule is the same on either tracker: **decompose first, then work the children one at a time through the normal loop.** An epic is never worked directly.

## Recognising one

- Several independently shippable deliverables
- Phased language — "Phase 1", "first we need to"
- Too large for one reviewable PR
- On dagger: a node with open children is already a grouping node and was never in the ready set

## Decomposing

On dagger, **delegate to `/dagger:epic`.** It owns the mini-PRD, the node-per-file format, the frontmatter, and importing a directory as one patch — and it files the whole shape atomically, which matters: a half-built graph is worse than none. This workflow edits only the node it holds; filing the epic's nodes is `/dagger:epic`'s job.

Bring it the slicing decisions; it handles the filing. Each unit should be:

- **Independently shippable** — merging it leaves a working state
- **Independently reviewable** — understandable without the other units
- **One session's work** — a Small, Medium, or Large node

| Good slicing | Bad slicing |
|---|---|
| Vertical: each unit delivers one aspect end to end | Horizontal: "all the models", "all the tests" — pure integration risk |
| Layered: infrastructure first, then what uses it | Arbitrary: splitting a cohesive change to make PRs smaller |
| Dependency order: foundations before dependents | Preference order encoded as dependency — serialises work that could run in parallel |

Two edges deserve care, because both are invisible when wrong:

- **`blocked_by` is "cannot start until"**, not "should happen after". Ordering preference as a dependency means only one node is ever ready and nobody knows why.
- **Giving a node children removes it from the ready set** until every child closes. That is what makes it a milestone instead of a task — intended for a grouping node, a bug anywhere else.

Where a unit ends in a human act — a signup, a credential, a policy call — file it as a **gate** (`assignee_kind: user`) with the agent work that prepares it as a separate node the gate depends on. The person then arrives at the gate with the recommendation already in its inputs.

## Constraints that force the shape

Some repos impose ordering that has nothing to do with the design. Pinwheel's Danger gate fails any PR mixing `db/migrate/` with application code, so every migration is its own PR that must merge before the code using it. Find these early — they decide the node boundaries, and discovering one mid-epic means re-slicing.

A constraint like that also decides the *order you can work in*, not just the slicing: the later node cannot even start until the earlier one has merged. Every PR-shaped node waits for its own merge anyway ([DAGGER.md](DAGGER.md)), so within an epic expect to finish one node, watch it merge, complete it, and only then claim the next — rather than holding several open PRs whose bases keep moving.

## Working the children

For each: run the full loop from `claim` — assess it independently (most are Small or Medium), take a worktree, and close its own loop. Do not carry one node's context into the next as if it were still true.

Between units:
- `claim` the next one, filtered to the epic's `labels` or `kind`. Do not list the children and pick; the set has moved, and other agents work the same graph.
- Check whether earlier PRs merged, and rebase.
- Re-read the inputs. An earlier unit's result is where its surprises were recorded, and it may have invalidated a later assumption.
- If a unit reveals the remaining slicing is wrong, re-file it through `/dagger:epic` rather than improvising around it.

## PR strategy

| Pattern | When |
|---|---|
| One PR per unit | Default. Units are independent and each reviewable alone |
| Stacked PRs | Units build on each other and incremental review is worth the rebase cost |
| Single PR | Units are tightly coupled and splitting would genuinely hurt review |

Default to one per unit; consolidate only when splitting hurts comprehension. Note that a squash-merge of an earlier PR breaks a stack rebased onto it — reset and cherry-pick rather than rebasing through a merged commit, and audit for files the retarget turned into silent deletions.

## Closing out

The grouping node becomes ready only when its children close, so completing the last child is what surfaces it. Complete it with a result that summarises the whole epic — what shipped, what was deliberately deferred, and which assumptions are still unverified. Then `/reflect`.
