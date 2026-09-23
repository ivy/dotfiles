---
name: work-on
description: End-to-end workflow for shipping one unit of tracked work — a dagger node or a GitHub issue — from claim through draft PR to a closed loop. Assesses shape and tier, composes the right skills, and verifies against the acceptance criteria.
argument-hint: "[next | slug#7 | #issue | issue URL] [--kind x] [--label y] [--min-priority pN]"
disable-model-invocation: true
allowed-tools:
  - Bash(echo:*)
  - Bash(gh issue view:*)
  - Bash(gh pr view:*)
  - Bash(git branch --show-current:*)
  - Bash(git fetch:*)
  - Bash(git show:*)
  - Bash(git status:*)
  - Bash(head:*)
  - Read
  - TaskCreate
  - TaskList
  - TaskUpdate
  - mcp__plugin_dagger_dagger__project_list
  - mcp__plugin_dagger_dagger__ready
  - mcp__plugin_dagger_dagger__show_node
  - mcp__plugin_dagger_dagger__inputs
  - mcp__plugin_dagger_dagger__explain
  - mcp__plugin_dagger_dagger__claim
  - mcp__plugin_dagger_dagger__release
  - mcp__plugin_dagger_dagger__comment
  - mcp__plugin_dagger_dagger__complete
  - Skill(agents-md)
  - Skill(checkout)
  - Skill(commit)
  - Skill(dagger:dagger)
  - Skill(dagger:epic)
  - Skill(gather-context)
  - Skill(plan)
  - Skill(pr)
  - Skill(reflect)
  - Skill(review-plan)
  - Skill(share-plan)
  - Skill(simplify)
  - Skill(think)
---

# Work On: Ship One Unit of Tracked Work

**Autonomy:** human-only · drives claim → work → draft PR → close the loop without confirmation, except the one plan approval `/plan` itself requires at Medium and up · claims, comments on, releases and completes nodes · has no merge, hold, drop, or `apply_patch` capability

## Arguments
```
$ARGUMENTS
```

## Pre-computed Context

```
Current branch: !`git branch --show-current 2>/dev/null || echo 'unknown'`
Dirty worktree: !`git status --porcelain 2>/dev/null | head -5 || echo 'clean'`
```

## Files

- [DAGGER.md](DAGGER.md) — read at steps 1, 3 and 9; also carries the MCP argument names
- [TIERS.md](TIERS.md) — read at step 4
- [PHASES.md](PHASES.md) — read at step 6
- [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md) — read instead of step 6 when the assessment came back Epic

## The loop

1. **Claim** — on dagger, `claim` with `assignee_kind: agent` plus any flags from the arguments. The claim *chooses* the work; the node it returns is your task. No `ready`, no browsing, no picking first ([DAGGER.md](DAGGER.md)). A GitHub issue, or an explicit node reference, resolves as the tracker table says.
2. **Read it whole.** The claim response carries the body; then **`inputs`** — the predecessors' results are the handoff, and skipping it is how you re-derive what someone already decided.
3. **Take what you were given.** Do not second-guess the claim, shop for a "better" node, or release it to try again. If the node is an Epic or a spike, that changes the shape of the work, not whether it is yours.
4. **Assess** shape × tier ([TIERS.md](TIERS.md)) and state which, with the one-line reason.
5. **Isolate** — `/checkout`, worktree by default: other agents work the same graph concurrently.
6. **Work** the phases for that tier ([PHASES.md](PHASES.md)), tracked as a `TaskCreate` runbook.
7. **Verify against the acceptance criteria** — one line per criterion, each naming the command that proves it.
8. **Publish** — `/commit` incrementally, then `/pr` as a draft.
9. **Close the loop** — comment the PR and the AC evidence on the node, then `complete` only once the deliverable is **delivered**: merged to the default branch, or — for a node whose deliverable is a decision — written into the result ([DAGGER.md](DAGGER.md)).

## Hard rules

- **`claim` is the selector.** It names no node, so a node picked out of `ready` is one you cannot ask for. `ready` is for explaining an empty claim, never for choosing.
- **`inputs` before work, always.** A node's own body is never its predecessors' results, and `show_node` will not give them to you.
- **The acceptance criteria are the contract.** Report each one individually, with the evidence. "Tests pass" verifies nothing the node asked for.
- **Complete on delivered, not on work finished.** Anything that ships as a PR is delivered when it is **merged** — verify by reading the artifact out of `origin/<default>` and quoting it, never from the merge notification. A decision is delivered when the result body says it. There is no "nothing depends on this" exemption. While the PR is open: comment the evidence, keep the lease, don't complete and don't `release`; an agent may not `hold`.
- **A node reference is not a GitHub issue number.** Never write `Closes #7` in a PR for `slug#7` — it closes an unrelated issue.
- **Never drop a node or remove an edge.** Reshaping the graph is `/dagger:dagger`; decomposition is `/dagger:epic`.
- **`/simplify` is a gate, not polish.** Mandatory at Medium and up. "The diff looks clean" is exactly when it earns its keep.
- **Drive autonomously.** Interrupt only for a real blocker: a contradiction in the node body, a failure with no clear fix, or a decision the body leaves genuinely open.
