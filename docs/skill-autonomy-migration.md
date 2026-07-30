# Skill Autonomy Migration

Runbook for bringing the existing skill set in line with [ADR 007](adrs/007-skill-autonomy-axes-and-reviewer-standing.md). Audience: agents revising skills. **Delete this file when the work list is empty.**

## Read first

This runbook holds the *work*, not the doctrine. Read the doctrine at its source before editing anything:

| Read | For |
|---|---|
| `home/dot_claude/skills/write-skill/AUTONOMY.md` | The three axes, declaration grammar, delegation graphs, unattended-composition audit |
| `home/dot_claude/skills/write-skill/REVIEW.md` | Review rubric, standing table, never-recommend-abstention |
| `docs/adrs/007-...md` | Why, and what was rejected |

Do not restate any of that in a skill body. Skill bodies persist in context every turn; the doctrine does not need to persist 27 times.

## The five changes

Each skill needs some subset. Most need only #1.

1. **Add an `**Autonomy:**` line** to the body, immediately under the `# Title`. Every skill. See the decision procedure below.
2. **Delete false harness claims.** Any sentence asserting an operation "will prompt", "prompts for approval", or "requires confirmation first" because it is absent from `allowed-tools`. Under `defaultMode: auto` that is false. Replace with either a real in-chat confirmation, or nothing.
3. **Remove abstention.** Any branch whose terminal state is "ask the user to decide" where the agent could reach a verdict. *Not* the same as asking for genuinely missing input — "unclear which repo → ask" is fine, because no judgment substitutes for a fact the agent doesn't have.
4. **Declare the delegation graph.** If the body invokes sub-skills, list them as `Skill(<child>)` in `allowed-tools`. If entries exist that the body never invokes, remove them — each one is a live grant.
5. **Fix loop hazards** where the skill is meant to run inside an unattended loop: interactive phases, `ExitPlanMode`, browser opens, unbounded iteration, untrusted input driving writes. Audit list is in `AUTONOMY.md`.

## Decision procedure: deriving the `**Autonomy:**` line

Answer A and C. Never declare B — it is law, identical everywhere.

**Axis A — trigger.** Does the skill *initiate* something where the initiation itself is the risk: an unattended write loop, a deploy, a release, anything the model noticing and starting would be wrong?

- Yes → `disable-model-invocation: true`; declare `human-only`.
- No → leave it model-invocable. Declare `model-invocable`.

Do not set A to make a skill feel safer. A skill an orchestrator must call has to be model-invocable or it is not composable.

**Axis C — commit.** What is the most consequential act the skill performs?

- **Irreversible and external** (merge, publish, release, force-push, delete a remote branch) → prefer *not granting the capability at all*. Declare `has no <verb> capability`. Only if the skill genuinely must perform it: require an explicit in-chat confirmation and declare `confirms before: <verb>`.
- **Reversible and external** (PR comment, issue, label, draft PR, bot directive) → `acts autonomously`.
- **Local only** → `acts autonomously`.

**Then the origin refinement.** Where the act is externally visible and the *agent* originated the judgment behind it, summarize first. Where the request already carries the decision, act. Where the model reached the skill spontaneously with no covering request anywhere in the chain, report instead of acting.

Examples:

```markdown
**Autonomy:** model-invocable · acts autonomously

**Autonomy:** human-only · drives the loop autonomously · has no merge or ready capability

**Autonomy:** model-invocable · posts when the request carries the verdict ·
summarizes first when the verdict is its own
```

## Work list

### Tier 1 — false claims (do first; these are actively wrong)

| File:line | Defect |
|---|---|
| `hk/SKILL.md:49` | "Claude Code will prompt the user to approve each one. This is the intended flow… the user gates each action" — the skill's entire stated safety model, and false in `auto`. Decide what actually gates `hk fix` / `mise use` here, or state that nothing does. |
| `share-plan/SKILL.md.tmpl:103` | "Commands will prompt for approval since they're not in `allowed-tools`." Delete. |
| `socket-ignore/SKILL.md.tmpl:42` | "(This publish prompts for approval — intended; it overrides a security gate.)" Replace with a real confirmation or drop it — see Tier 2. |

### Tier 2 — the two security-triage leaves

Both stay **model-invocable** — they must be callable from a PR-hygiene orchestrator. Neither gets `disable-model-invocation`.

- `socket-ignore/SKILL.md.tmpl` — add the `**Autonomy:**` line. Its predicate is mechanical (every dependency path roots in dev/test-only), so it acts once the lockfile confirms that. Reword `:39` so the *verdict* leads ("the alert is legitimate — don't suppress") rather than the asking; the STOP itself is correct and stays.
- `dry-run-sec/SKILL.md.tmpl` — add the `**Autonomy:**` line. Judgment covers arbitrary vulnerability classes, so keep the cited-`file:line` evidence bar at `:65` and do not strengthen it into a stop. `:71` already documents `auto` mode correctly; leave it.

Neither is committed to git yet.

### Tier 3 — blanket interactive gates

| File:line | Change |
|---|---|
| `reflect/SKILL.md.tmpl:161` | "**Wait for user approval before executing any actions.**" Filing an issue on an internal tracker is work to be done, not an act to approve. Scope this to whatever here is actually irreversible, or delete it. `:129` ("unclear which repo → ask") is missing input, not abstention — keep it. |

### Tier 4 — loop hazards, gated on an open question

These block parallel unattended `/work-on`, and the shape of the fix depends on the draft-PR question below. **Do not start these until it is answered.**

| File | Hazard |
|---|---|
| `pr/SKILL.md.tmpl`, `pr/executable_gh-pr-create-web`, `pr/README.md` | Opens a browser for "final review and submission" — N parallel runs fan out N windows. `:152` has no `--draft`; `:171` adds it only if the user says the word. |
| `plan/SKILL.md.tmpl` | `ExitPlanMode` is a hard stop by definition. |
| `work-on/SKILL.md.tmpl:198-210` | Autonomy-boundary table marks `/think` **Interactive** and `/plan` as user-approved. Medium+ tiers therefore park before a PR exists; Quick Fix and Small do not. Parallel unattended runs are viable today only at those two tiers. Also needs `Skill()` entries for any triage children it should be allowed to delegate to — currently neither `dry-run-sec` nor `socket-ignore` is listed, so it cannot call them. |
| `checkout/SKILL.md.tmpl` | Already declares `Skill()` children; verify the graph matches what the body invokes. |

### Tier 5 — everything else

The remaining 18 skills need change #1 only. Derive the line, add it, verify it against `allowed-tools`. No other edits unless a factual defect turns up.

## Open question blocking Tier 4

**Do the bots engage with draft PRs?** The intended end state is: parallel `/work-on` runs open draft PRs, churn to green builds and passing bots unattended, and the human flips to ready and merges on their own schedule. Draft status is then the gate — structural, enforced by GitHub, immune to `auto` mode and to model self-report.

One fact is certain: GitHub does not request CODEOWNERS reviews until `ready_for_review`, so review-based approvals cannot be obtained on a draft. Beyond that it is per-bot — CI commonly skips drafts via `if: github.event.pull_request.draft == false`, Buildkite's GitHub integration has a skip-drafts setting, and DryRun/Socket are Apps that probably fire on draft `pull_request` events but this is unverified.

If bots skip drafts, "green while draft" is unreachable and the design degrades to: open ready → churn → human merges. The human keeps merge, loses the buffer. **Settle this on one throwaway PR before designing Tier 4.**

## Verification

Per skill, before considering it migrated:

1. `**Autonomy:**` line present, and `allowed-tools` grants nothing the line disclaims.
2. `grep -nE 'will prompt|prompts for approval|requires approval first'` → no hits.
3. Every decision branch terminates in a verdict, not a question — except where the missing item is a fact, not a judgment.
4. `Skill()` entries match exactly what the body invokes.
5. For `.tmpl` files: `chezmoi cat ~/.claude/skills/<name>/SKILL.md` renders with correct frontmatter.
6. One review pass, one reviewer. Dispose of findings by standing: apply facts, surface intent findings **unapplied**. If the reviewer recommends the skill withhold a judgment, that finding is wrong by construction — report it, don't apply it.

Corpus-wide, when the work list is empty:

```bash
cd home/dot_claude/skills
grep -rL '\*\*Autonomy:\*\*' */SKILL.md */SKILL.md.tmpl 2>/dev/null   # should be empty
grep -rnE 'will prompt|prompts for approval' . | grep -v write-skill  # should be empty
```

## Definition of done

All 27 skills carry an `**Autonomy:**` line consistent with their `allowed-tools`; no skill body makes a false claim about harness prompting; no skill defers a judgment as a terminal state; delegation graphs match invocation; and the loop-composable skills pass the `AUTONOMY.md` unattended audit. Then delete this file.
