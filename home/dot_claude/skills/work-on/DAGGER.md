# Working a dagger node

The dagger skill (`/dagger:dagger`) covers the graph and how to *write* a node. This file covers the other side: consuming one — claiming it, proving you satisfied it, and handing off so the next agent doesn't start from nothing.

## Which tracker

| Argument | Resolves to |
|---|---|
| empty, `next`, `ready` | dagger — `ready`, take the top of the set |
| `slug#7`, `org/slug#7` | that dagger node |
| `dg:#7` / `gh:123` | forced, no probe |
| a GitHub URL, `owner/repo#123` | GitHub issue |
| bare `#7` or `7` | **probe, don't guess** — `show_node` first; if it resolves it is a node, otherwise `gh issue view` |

`project_list` gives the slugs when no current project is configured. Trailing `--kind` / `--label` / `--min-priority` flags steer which ready node you get; pass them to `claim`.

Everything below is the dagger path. On the GitHub path, substitute the issue for the node, its body for the work order, and a comment for the result — the phases in [PHASES.md](PHASES.md) are the same.

## Reading before claiming

`show_node` at `view: full` gives the body. It does **not** give you the predecessors' results — it reports `inputs.count` and `inputs.bytes` so you can see they exist and what reading them costs. `inputs` is the separate call that returns them, and it is the handoff from whoever did the work you depend on.

Skip it and you will re-derive a decision someone already made and wrote down. When the total is larger than you want at once, ask for `view: "summary"` and pull the ones you need individually with `show_node`.

An open predecessor is not an input — it is what the node is waiting on, which `explain` answers. A dropped one is listed with no result. Inputs are not transitive: a predecessor's result already summarizes its own inputs.

## Claiming

`claim` takes **filters, not a reference.** There is no way to say "claim the one I just read", so:

1. Narrow as hard as the node allows — `min_priority`, `kind`, `labels`.
2. Read the returned `reference` and compare it to what you read.
3. If they differ, you are holding *different work*. Read it properly before touching anything, or `release` it.

The returned `lease.id` is a fencing token: every later write to that node carries it, and a stale one is rejected — that is how a reclaimed node resists its previous holder. Through MCP the lease renews in the background, so a long run needs no `heartbeat`; if the session dies it releases with reason `crash`.

## When the body is not enough

A node body worth claiming carries Context, Deliverables, Acceptance criteria, Scenarios and Notes. Read what it cites — the specs and ADRs named in Context usually *are* the rest of the context.

| Body | Do |
|---|---|
| Deliverables name paths, ACs name their own verification | Work it. `/gather-context` would only re-read what the body already told you. |
| Thin, or points into code you don't know | `/gather-context` scoped to the gap, not the whole node |
| Contradicts itself, or the ACs can't all hold | Stop. Comment the contradiction on the node and ask — this is one of the few real blockers |
| Asks a question rather than naming a deliverable | It is a spike or it needs splitting ([TIERS.md](TIERS.md)) |

## Verifying against the acceptance criteria

The ACs are the contract and the only thing a reviewer checks. Report them one per line, each with the command that proves it and its output — not a summary sentence that covers all of them at once.

Two failure modes to watch for, both of which look like success:

- **Declaring victory against your own reading.** If an AC is ambiguous, say which reading you took and why, in the result.
- **Verifying the wrong artifact.** Check the thing the AC names, in the state it names it in. An AC about the default branch is not satisfied by your local branch.

Where the node names a scenario ("running against a database with existing rows leaves every row …"), construct that state and observe it. A scenario is cheap to actually run and is usually the only check that would have caught a wrong default.

## When to complete

**A node is done when its deliverable is delivered — not when the work is finished.** Those are two different moments, and the gap between them is almost always a PR waiting to merge.

| Deliverable | Delivered when |
|---|---|
| Code, docs, config — anything that ships as a PR | **Merged to the default branch.** Read the artifact out of `origin/<default>` and quote it |
| A decision with no committed artifact — a spike, an investigation | **The result body is written.** For these the result *is* the deliverable, so writing it is the delivery |

There is no third row. "Nothing depends on this node" is not a licence to complete early: it is the judgment an agent under schedule pressure is most biased to reach, and it is wrong often enough that the rule does not admit it.

Note the test is the artifact on the default branch, not the PR's state. They come apart: a squash merge means your commit SHA never exists on the default branch although the artifact does, a PR can merge into a non-default base, and someone else's merge can satisfy your node without your PR moving at all. Reading the file covers all three; a merge notification covers none of them.

Completing early is expensive in *someone else's* session — a successor starts against an artifact that isn't there, and nothing in its context explains why.

### While the PR is open

Work finished, PR unmerged: **comment and keep the lease.** The comment is the only thing that outlives the session, so it carries the PR URL and its state, every acceptance criterion with its evidence, and an explicit *work complete, awaiting merge — do not redo*.

Do not complete. Do not `release` to tidy up — that returns the node to the ready set where the open PR is invisible. And know what happens if the session simply ends: the lease releases with reason `crash`, the node goes back to the ready set, and your comment is the only thing standing between the next agent and redoing the work. That is why the comment is not optional.

This is also not the same as parking. Parking is the `hold` tool, which takes work out of the ready set until a person releases it, and dagger refuses an agent principal that tries — so an agent that believes work should be parked says so in a comment where a person will read it.

### Closing the loop after the merge

Interactively the merge usually lands in the same session. When the work is done and the PR is still open, say so plainly and offer to watch it through — then on merge, verify the artifact on the default branch and `complete` with the full result body. Check before arming a watch: a PR reviewed while you were working may already be merged, and polling for an event that has happened is pure waste.

If the session ends first, the node returns to the ready set carrying your comment, and whoever reads it next can verify the merge and complete it from there.

## The result body

Downstream agents assemble their whole context from the results of what blocked them. `complete` takes `lease_id` and `result`; a result of "done" throws the handoff away. Five things earn their space:

1. **Where it landed** — commit, PR, branch, and its actual state (merged / open / draft).
2. **What exists now**, concretely. Quote the artifact if it is small enough to quote.
3. **Decisions you took and why** — especially anywhere you chose between readings of the node. Say what would change the call.
4. **What you deliberately did not do.** This is the successor's scope boundary, and the node body's "do not add X here" needs restating as "X does not exist yet".
5. **Traps.** What looked right and wasn't. The highest-value lines in the result, because they transfer knowledge rather than restating intent.

## Gates

A node with `assignee_kind: user` is a gate: policy refuses an agent that claims it, completes it, reclassifies it, or unlinks it. Dropping one does not unblock what it blocks.

Do not try to route around it. Prepare it instead — the agent work that makes the gate easy is a separate node the gate depends on. If you are already holding the work the gate blocks, comment your recommendation on the gate and `release` with reason `gate`. Filing the gate node itself is `/dagger:dagger`.

## Working a shared graph

Other agents and people work the same graph while you hold your node. Expect the ready set to move under you: nodes you saw leave it, nodes you didn't arrive.

- Take a **worktree**, not a branch in the shared checkout. Two agents in one working tree is a corrupted diff.
- Re-run `ready` before claiming anything else; a list you fetched five minutes ago is a guess.
- When something you expected to be ready isn't, `explain` it rather than inferring — it names holds, live leases and their expiry, and open blockers.
- An empty `ready` is not a finished project. The response carries `held_count`, and held work is absent, not done.

## MCP argument names

These differ per tool, so: `show_node`, `inputs`, `explain`, `comment` and `complete` take **`ref`**, and `complete` names the lease **`lease_id`**, not `lease`.

Three take no `ref` at all. `ready` and `claim` are filter-addressed — `projects`, `kind`, `assignee_kind`, `labels`, `min_priority`, plus `wait` / `ttl` on `claim` and `page_size` / `page_token` on `ready`. `release` is *lease*-addressed: required `reason` (`gate` / `crash` / `budget` / `preempted`), optional `lease_id` (defaults to the session's single lease) and `detail`.

Inside an `apply_patch`, the operations name their target **`node`** — except `add_edge`, which takes `from` / `to`.
