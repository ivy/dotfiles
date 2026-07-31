---
status: "accepted"
date: 2026-07-29
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Separate Skill Autonomy into Three Axes and Bound Reviewer Standing to Facts

## Context and Problem Statement

Skills were authored under a safety model that made two claims, both of which fail
in practice.

The first: omitting a tool from a skill's `allowed-tools` produces an approval
prompt, so dangerous operations are gated by omission. This is false under
`permissions.defaultMode: auto`, where a call matching no allow/ask/deny rule is
routed to a classifier — and a call that *is* the user's request is usually
approved. Two `gh pr comment` publishes ran with no dialog while two skill bodies
asserted they would prompt. Three skills still carry that false claim, and for
`hk` it is the skill's entire stated safety model.

The second: agent judgment is a thing to gate. `REVIEW.md` offered reviewers no
way to distinguish "don't act without me" from "don't decide without me", so a
reviewer rewrote a security-triage skill's verdict table to `Propose nit; the user
chooses. Never self-select.` — against an explicit request for agent-originated
verdicts — and the authoring agent applied it. The user had to interrupt to stop
the diff.

That second failure has a deadline. Skills are becoming components of unattended
loops: parallel `/work-on` runs that churn a PR to green builds and passing bots
without supervision. A sub-skill that answers "the user should decide" is merely
annoying in an interactive session; in a loop it is a hang.

## Decision Drivers

- **Agent autonomy is the point.** The vision puts the human's role at intent and
  taste, not maintenance. A needless approval prompt is babysitting.
- **Skills must compose.** Leaf skills are invoked by orchestrators, so any
  posture that stops a skill mid-flight breaks composition.
- **Gates must be enforceable, not aspirational.** A gate documented in prose
  that the harness does not implement is worse than no gate: it is a false
  assurance sitting in a persistent skill body.
- **Manual permission modes stay supported.** `default` and `plan` mode are used
  for work agents can't be trusted with blindly. The doctrine must be correct in
  both, not tuned to `auto`.
- **The real cost of a mistake is public embarrassment, not catastrophe.** Both
  security-suppression skills sit behind additional systems, teams, and reviewers,
  and their output is a public comment carrying its own evidence.
- **29 skills already exist** under the old model.

## Considered Options

1. **Tighten the existing model** — add `permissions.ask` rules so omission-based
   gates actually fire, and keep gating judgment where stakes are high.
2. **Three axes, structural gates, bounded reviewer standing** — separate trigger
   from judgment from commit; make judgment ungated; move real gates to withheld
   capability; limit reviewers to factual findings.
3. **Remove gates entirely** — trust the model, rely on downstream human and
   automated review to catch mistakes.

## Decision Outcome

Chosen option: **Three axes, structural gates, bounded reviewer standing**,
because it is the only option that makes gates enforceable *and* keeps skills
composable into unattended loops.

Three independent decisions govern a skill's autonomy. Conflating any two is the
defect this ADR exists to prevent:

| Axis | Question | Mechanism |
|---|---|---|
| **A. Trigger** | Human `/slash` only, or may the model invoke it? | `disable-model-invocation` |
| **B. Judgment** | Does the skill reach a verdict, or defer the call? | Body prose |
| **C. Commit** | Who performs the irreversible act? | Capability granted or withheld |

The normative rules:

- A skill **MUST** always reach a verdict, give the one-line reason, and say what
  would change its mind. It **MUST NOT** defer a judgment to the user as a
  terminal state. Axis B is never gated.
- A reviewer **MUST NOT** recommend that a skill withhold a judgment. Where a
  verdict is high-stakes the reviewer **SHOULD** recommend a higher *evidence
  bar* — "this dismissal must cite the `file:line` that makes it safe" — never a
  stop.
- Skill bodies **MUST NOT** claim that an omitted tool will prompt. Narrowing
  `allowed-tools` **SHOULD** still be done; it is real protection in manual modes
  and free in `auto`, but it is defense-in-depth, never a guarantee.
- A gate that must hold in every permission mode **MUST** be either a withheld
  capability or an explicit in-chat confirmation in the body. Withholding is
  preferred: structural gates outside the agent — a draft PR it cannot mark ready,
  a capability it was never granted — hold in every mode, survive a model
  reasoning around prose, and scale to N parallel agents where N prompts do not.
- Every skill **MUST** declare axes A and C in an `**Autonomy:**` line in its
  body. The reviewer audits `allowed-tools` against that line.
- `Skill(<child>)` entries in `allowed-tools` are the **delegation graph**.
  Authorization flows down through them: a child invoked by a parent whose
  declared purpose covers the action inherits that authorization. A parent
  **MUST NOT** relax a child's evidence bar.
- Reviewer findings are disposed of by **standing**, not severity. Factual
  findings — checkable against source, docs, or observed behavior — are verified
  and applied. Intent findings — what the skill should do, who decides, how much
  autonomy — are surfaced verbatim and **unapplied**; the user decides. A reviewer
  never saw the request and has no standing on why the skill exists.

### Consequences

- **Good**: gates that exist are enforceable, and gates that never worked are gone
  rather than silently trusted.
- **Good**: skills compose into unattended loops without deadlocking, which is
  what parallel `/work-on` requires.
- **Good**: the doctrine is correct in every permission mode, so `default` and
  `plan` remain first-class.
- **Good**: reviewers stop generating out-of-standing "the user should decide"
  findings, which were the bulk of review diff churn.
- **Bad**: a skill will eventually post a confident, wrong verdict. Axis B is
  absolute, so nothing stops it at the moment of judgment. The mitigations —
  a cited-evidence requirement and a publicly legible artifact — are weaker than a
  working human gate would be, and are accepted because the human gate did not
  work.
- **Bad**: the `**Autonomy:**` line is a convention with no schema enforcement. It
  can drift from `allowed-tools`, and only the review pass catches drift.
- **Bad**: activation-awareness is model self-report. A skill can widen its own
  authority by concluding the user "basically asked." This is an accepted cost of
  running `auto`; where the blast radius makes it unacceptable, the answer is
  axis A, not hedging on B or C.
- **Bad**: 29 existing skills need revising, and 4 carry false claims today.
- **Neutral**: `permissions.ask` was considered and rejected as the enforcement
  point. Axis A plus withheld capability covers the same ground without adding
  prompt friction to a workflow built to avoid it.

## Pros and Cons of the Options

### Tighten the existing model (add `ask` rules)

Add `permissions.ask` entries in `bin/sync-claude-settings` so that omitting a
tool from `allowed-tools` produces a real prompt, restoring the old doctrine's
premise.

- **Good**: makes existing skill bodies true with no per-skill edits.
- **Good**: enforced by the harness, invocation-independent.
- **Bad**: reintroduces exactly the friction the workflow exists to remove, and
  scales badly — N parallel loops mean N prompts, which is the babysitting.
- **Bad**: does nothing about the judgment failure, which is the one that breaks
  composition.
- **Bad**: a prompt at hour seven of a session, showing only a filename, catches
  less than a public comment carrying a checkable citation.

### Three axes, structural gates, bounded reviewer standing

- **Good**: separates three things that were conflated, so each can be set
  correctly and independently.
- **Good**: structural gates are the only kind that survive `auto` mode, model
  self-report, and parallel execution.
- **Good**: bounding reviewers to facts preserves the rubric's real value — it
  catches over-broad tool patterns and false harness claims — while removing its
  authority over intent.
- **Bad**: requires touching every skill.
- **Bad**: relies on convention (`**Autonomy:**`) that nothing validates.

### Remove gates entirely

- **Good**: zero friction, maximal autonomy, no doctrine to maintain.
- **Bad**: gives up the cases where a gate is cheap and correct — an orchestrator
  simply not holding a merge capability costs nothing and prevents the one class
  of mistake that is genuinely hard to undo.
- **Bad**: discards a rubric that demonstrably catches real defects.

## More Information

Doctrine lives with the tooling that applies it, not in this ADR:

- `home/dot_claude/skills/write-skill/AUTONOMY.md` — the axes in depth,
  declaration grammar, delegation graphs, unattended-composition audit.
- `home/dot_claude/skills/write-skill/REVIEW.md` — the review rubric, standing
  table, and the never-recommend-abstention rule.
- `docs/skill-autonomy-migration.md` — the runbook for bringing the existing 29
  skills into line. Delete it when the migration completes.

Revisit this decision if any of the following change:

- `permissions.defaultMode` moves off `auto`, which would restore omission-based
  gating and make `ask` rules viable again.
- A skill posts a wrong verdict with real consequences, which would test whether
  evidence bars plus public artifacts are sufficient mitigation for an absolute
  axis B.
- Claude Code exposes an invocation-source substitution, which would turn
  activation-awareness from model self-report into something enforceable.
