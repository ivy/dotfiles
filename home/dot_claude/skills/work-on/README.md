# `/work-on` — Ship One Unit of Tracked Work

Takes a single unit of tracked work — a [dagger](https://github.com/steading-ai/dagger) node or a GitHub issue — from claimed to draft PR to a closed loop. Invoke it once; it assesses, composes the right skills, verifies against the acceptance criteria, and hands off to whatever comes next.

```
/work-on                                   # claim the top of the ready set
/work-on next --label migration            # steer which ready node
/work-on pinwheel#3                        # a specific dagger node
/work-on #412                              # probes dagger first, falls back to the issue
```

## Why this exists

Agent-driven development has an obvious failure mode and a subtler one.

**The obvious one:** the agent codes confidently in the wrong direction, and by the time a PR exists you have a competent solution to the wrong problem. `/work-on` front-loads the judgment — [`/gather-context`](../gather-context/README.md) for what the code actually says, [`/think`](../think/README.md) for the decisions the work leaves open, [`/plan`](../plan/README.md) for structure before code. Once human and agent agree, execution is mechanical.

**The subtler one, and the reason this skill is built around a graph:** work that closes too early breaks *someone else's* session. Completing a node unblocks its successors for every other agent on the graph, so a node marked done while its migration sits in an unmerged draft PR hands the next agent a column that does not exist — and nothing in that agent's context explains why. The failure surfaces far from its cause.

So the loop's last step is not "open a PR". It is: comment the evidence on the node, then complete **only once the work is delivered** — merged to the default branch, verified by reading the artifact out of it rather than by trusting a merge notification. A node whose deliverable is a decision rather than a diff is delivered when its result body says so; everything else waits for the merge, with no "nothing depends on this" exemption, because that is exactly the judgment an agent under time pressure talks itself into.

Between finishing the work and the merge landing, the node stays claimed with the PR link and the acceptance-criteria evidence attached. That is deliberately not the same as parking it — parking takes work out of the ready set, and only a person can do that.

## How it works

```
resolve → read + inputs → claim → assess → isolate → work → verify ACs → draft PR → close the loop
```

Two things distinguish it from a linear runbook:

**A good node has already done the planning.** A body with named deliverables, acceptance criteria that each carry their own command, and a Notes section full of traps has absorbed the context-gathering and planning phases. Going straight to implementation is the *correct* reading of such a node, not a shortcut — so the tier is assessed on how much is still undecided, never on how much text there is.

**The acceptance criteria are the contract.** Not "the tests pass" — each criterion is reported individually with the command that proves it. That is also the only honest defence against the agent declaring victory against its own reading of an ambiguous requirement.

| Tier | Profile | Shape of the work |
|---|---|---|
| **Quick fix** | One file, no decisions | checkout → fix → commit → draft PR |
| **Small** | One concern, ACs fully specify it | + context only where the body left a gap |
| **Medium** | A design choice left open | + think → plan → review → simplify |
| **Large** | Cross-cutting, parallel workstreams | + worktree fan-out, reflect |
| **Epic** | Multi-node, multi-session | decompose via [`/dagger:epic`](https://github.com/steading-ai/dagger), then work the children |

Orthogonal to tier is **shape**: an implementation node ends in a PR, a spike ends in a decision written as its result, and a gate cannot be claimed by an agent at all — it is prepared, then left for a person. Mistaking a spike for an implementation node is how you get a PR full of speculative code nobody asked for.

## Files

The agent reads these on demand; they are worth a human's time in roughly this order.

- [DAGGER.md](DAGGER.md) — the argument for the completion rule above, plus the traps that make the graph loop worth writing down: why `claim` can hand you the wrong node, why `inputs` is the step everyone skips, what a result body owes the agent that reads it
- [TIERS.md](TIERS.md) — why a long node body usually means *less* work, not more
- [PHASES.md](PHASES.md) — where the one remaining human checkpoint sits, and why the PR is always a draft
- [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md) — slicing, the two edge mistakes that are invisible when wrong, and repo constraints that dictate node boundaries

## The component skills

**Research** — [`/checkout`](../checkout/README.md) · [`/gather-context`](../gather-context/README.md)
**Planning** — [`/think`](../think/README.md) · [`/plan`](../plan/README.md) · [`/review-plan`](../review-plan/README.md) · [`/share-plan`](../share-plan/README.md)
**Execution** — [`/commit`](../commit/README.md)
**Review** — `/simplify` · [`/pr`](../pr/README.md)
**Retrospective** — [`/reflect`](../reflect/README.md)

It reads what exists at activation time and degrades gracefully: a repo with only [`/checkout`](../checkout/README.md), [`/commit`](../commit/README.md), and [`/pr`](../pr/README.md) gets a lean workflow rather than a broken one. It holds no merge capability, and no capability to drop a node or reshape the graph — that is [`/dagger:dagger`](https://github.com/steading-ai/dagger)'s job.
