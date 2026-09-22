# Assessment: shape × tier

Two independent questions, and conflating them is how a spike turns into a pointless PR.

- **Shape** — what the deliverable *is*. Decides how the loop ends.
- **Tier** — how much work it is. Decides which phases run ([PHASES.md](PHASES.md)).

Assess both before doing anything, and state each with its one-line reason.

## Shape

| Shape | Signals | Deliverable | Ends with |
|---|---|---|---|
| **Implementation** | Deliverables name paths; ACs name commands | a PR | `complete` once that PR is **merged** and the artifact is verified on the default branch |
| **Spike** | `kind: spike`; the title says *measure*, *decide whether*, *investigate*; no path in Deliverables | **a decision, written as the result body** — plus a doc if it is worth keeping, plus follow-up nodes | `complete` with the recommendation and what would change it. Often no code at all. |
| **Gate** | `assignee_kind: user` | a human act — a signup, a token, a payment, a policy call | **not claimable.** Prepare it; see [DAGGER.md](DAGGER.md) |
| **Grouping** | has open children | its children | never ready; work the children |

A spike that opens a PR full of speculative code has misread its shape. A spike that ends with "measured X, recommend Y because Z, would revisit if W" has hit it exactly.

## Tier

On the dagger path the node body is the signal, and it is a much better one than issue metadata:

| Signal | Reads as |
|---|---|
| **Deliverable count** | One artifact → Quick/Small. Several across surfaces → Medium+ |
| **AC count and specificity** | ACs that each name a command → smaller than they look; the thinking is already done |
| **Notes section** | Long Notes means known traps — not more work, but more care |
| **`inputs.count` / `.bytes`** | A large handoff means the shape was decided upstream → usually smaller than it appears |
| **Open questions in the body** | "should we X or Y" → Medium at minimum; needs `/think` |
| **`priority`** | Orders the ready set. Not a complexity signal — `p1` chores exist |
| **`kind`** | `chore` → usually Quick. `bug` → whatever reproducing costs |
| **Cited specs/ADRs** | Context that already exists. Read it; don't re-derive it |

On the GitHub path, fall back to issue signals: labels (type, readiness, scope), body length, comment count, linked issues, sub-task checkboxes, and explicit "should we" questions.

### Tiers

| Tier | Profile | Examples |
|---|---|---|
| **Quick fix** | One file, exact description, no decisions | A README claim that is wrong; a version pin; a wrong default |
| **Small** | One concern, 1–3 files, ACs fully specify it | One migration; one predicate plus its test; a scoped rename |
| **Medium** | Several components, or a design choice the body leaves open | A new service object and its callers; a tool plus its wiring; a bug spanning layers |
| **Large** | Cross-cutting, parallelizable workstreams, architectural reach | A new subsystem boundary; replacing a mechanism across surfaces |
| **Epic** | Multi-node, multi-PR, likely multi-session | See [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md) — decompose first, work the children |

### A well-written node is smaller than it looks

The reflex is to size by how much text the body has. That is backwards: a body with Context, named Deliverables, ACs carrying their own commands, and a Notes section full of traps has *already absorbed* the context-gathering and planning phases. Going straight to implementation is the correct response to one, not a shortcut.

Size by **how much is still undecided**, not by how much is written down. A one-paragraph node with an open design question is Medium; a page-long node that names every path and command is Small.

## When in doubt

- Torn between tiers → take the higher one. Over-planning costs minutes, under-planning costs hours.
- Torn on shape → look at what a successor would consume. If it is a decision, it is a spike.
- The body says it needs a human decision → it is a gate, or it needs one filed. Do not decide it for them, and do not file a gate to avoid a call you could make.
