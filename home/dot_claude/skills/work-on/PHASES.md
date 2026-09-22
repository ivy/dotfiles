# Phases

Which skills run at which tier, how they are tracked, and where the autonomy boundary sits.

Use only skills that actually exist in the environment. When one is genuinely absent, do the equivalent work inline — never drop the step because the name sounds optional.

## Sequences

Steps 1–3 of the loop (resolve, read, claim) have already happened. `<ref>` is the node or issue reference.

Every sequence below ends at the draft PR, which is **not** the end of the loop — step 9, closing the loop, follows all of them, and the node is not complete until the work is delivered.

### Quick fix
```
1. /checkout <branch>            (worktree)
2. Edit the file(s)
3. /commit
4. /pr draft
```

### Small
```
1. /checkout <branch>            (worktree)
2. /gather-context <ref>         ONLY if the body left a gap — see DAGGER.md
3. Edit per the Deliverables
4. Verify each acceptance criterion
5. /commit
6. /pr draft
```

### Medium
```
1. /checkout <branch>            (worktree)
2. /gather-context <ref>         full scope
3. /think — the decisions the body left open
4. /plan
5. /review-plan
6. /share-plan <ref>             posts to the node as a comment, not to an issue
7. Implement — one task per distinct change
8. /simplify                     mandatory quality gate
9. Verify each acceptance criterion
10. /commit
11. Doc-refresh judgment → /agents-md if it clears the bar
12. /pr draft
```

### Large
```
1–6. as Medium
7.  Parallel execution across worktrees
8.  /commit as each workstream lands
9.  /simplify                    mandatory
10. Verify each acceptance criterion
11. Doc-refresh judgment → /agents-md if it clears the bar
12. /pr draft
13. /reflect
```

### Epic
Decompose first; do not work it directly. [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md).

## The task list is the runbook

Build it with `TaskCreate` and dependencies as soon as the tier is assessed. Each subject is the **exact invocation or a scoped action** — never a catch-all:

- Skill steps → the literal call: `/share-plan pinwheel#3`
- Implementation steps → an imperative naming the file or module: `Add the runtime_session_id index to the migration`
- Never `Implement the feature` or `Make the changes`

Sub-skills may create their own tasks; that is fine. They must not delete the workflow tasks. After each skill returns, `TaskList` and re-create anything that vanished with the same subjects and dependencies.

Adapt freely as reality intrudes — **except** the gate steps `/review-plan`, `/simplify`, the AC verification, and `/pr`, which stay. If the tier assessment turns out wrong, change the sequence rather than defending it.

## Autonomy boundary

| Phase | Mode | Behaviour |
|---|---|---|
| Resolve / read / claim | Autonomous | Surfaces the node, the inputs, and the assessment |
| `/checkout`, `/gather-context` | Semi-autonomous | Works, then surfaces findings |
| `/think` | **Interactive** | Converge with the human. Pass the specific open decisions as arguments, not "discuss the plan" |
| `/plan` | **Interactive** | Calls `ExitPlanMode` and waits — its own declared posture, and the one stop this workflow does not drive through. Approval is the execution signal |
| `/review-plan` | Autonomous | Verifies the plan's claims against the codebase, returns an Approve/Revise verdict, edits nothing |
| Implementation | Autonomous | Commits incrementally |
| `/simplify` | Autonomous | Scans changed code and fixes what it finds |
| AC verification | Autonomous | Reports each criterion with its evidence |
| `/pr` | Autonomous | Opens a **draft** |
| Close the loop | Autonomous | Comments the evidence; completes only once delivered. Offers to watch an open PR through to merge |
| `/reflect` | Interactive | Large and Epic only |

A node whose body is fully specified has no interactive phase at all — Quick and Small never reach `/think` or `/plan`, which is the common case and should run start to finish without stopping. The two interactive rows exist only at Medium and up, and only because the work genuinely has an open decision.

**Escape hatch:** on a genuine blocker — a self-contradictory body, a failure with no clear fix, an AC that cannot hold — stop and say so. Comment it on the node so the next reader inherits the question.

## Why the PR is a draft

A PR is opened as a draft because green checks only prove the code matches the author's assumption. Promote it once something independent has exercised the assumption — a real run, a reviewer, or the acceptance criteria verified against the merged artifact. The draft state is also the structural gate: this workflow cannot merge, and a draft cannot be merged by accident.

## Doc refresh: when to run `/agents-md`

After `/simplify` and its commits, judge whether the change leaves agent-facing docs (`AGENTS.md` / `CLAUDE.md`, `docs/agents/`) materially stale. The goal is accurate onboarding for the *next* fresh-context agent, not a changelog of this PR.

**Run it when the change:**
- Alters architecture, layout, or the canonical build/test/run commands
- Introduces foundational scaffolding — a new top-level directory, framework, or core pattern
- Adds, removes, or renames a skill, agent, or hook that future agents rely on
- Establishes a convention that should apply repo-wide
- Breaks an instruction already written in `AGENTS.md` / `CLAUDE.md`

**Skip when it is:**
- A bug fix, refactor, or rename that doesn't shift how agents work here
- A single-file tweak, version bump, or doc edit
- Tests, fixtures, or config following an existing pattern

Rule of thumb: would this help ~90% of fresh agent context windows in this repo? If not, skip and say why in one line. When it does run, `/commit` the doc changes before `/pr`.
