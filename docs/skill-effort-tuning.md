# Skill Effort & Model Tuning

Draft proposal for reviewing `model:` and `effort:` frontmatter across `home/dot_claude/skills/*`. Based on community guidance from [Claude Code effort levels explained (Reddit)](https://www.reddit.com/r/ClaudeCode/comments/1soqwfl/claude_code_effort_levels_explained_what/) — cross-checked against Anthropic's official docs.

**Status:** Draft for review. Not yet implemented.

## TL;DR

Three skills have quality bugs worth fixing immediately. Eighteen skills inherit their model from the session when they should be pinned. Total work: one focused fix-commit plus a batch-pin commit.

## Background — what effort actually controls

From the article:

- **5 levels:** low, medium, high, xhigh, max
- Effort is a **behavioural signal, not a strict token budget**
- **Opus 4.7 defaults to xhigh on every plan**. **Sonnet 4.6** defaults to medium on Pro/Max
- **Low-effort Opus 4.7 ≈ medium-effort Opus 4.6** — the whole scale shifted up
- Controls thinking depth, tool-call appetite, response length, and agentic persistence
- Anthropic says max "shows diminishing returns and is more prone to overthinking" on 4.7

Frontmatter fields (both supported in SKILL.md):

- `model:` — `haiku` / `sonnet` / `opus` (or `inherit`)
- `effort:` — `low` / `medium` / `high` / `xhigh` / `max`

Haiku 4.5 does not support `effort:` the same way — pin only the model for Haiku-tier skills.

## Guiding principles for this project

1. **Plan with Opus xHigh, execute with Sonnet at lower effort, Haiku for trivia** (per article's core recommendation).
2. **Context quality > effort level.** Our skills are well-structured with explicit playbooks, so most can run lower than intuition suggests.
3. **Sonnet follows directions closely without drift** — a feature when the skill body is prescriptive, a bug when the skill needs to push back adversarially.
4. **Pin everything.** Skills that inherit cost whatever the session costs. Pinning gives consistent cost and consistent behavior regardless of session context.
5. **Align with core-principles.md:** agent-first, observable, pinned supply chain. Effort/model choice is part of reproducibility.

## Three bugs to fix first

### 1. `work-on: effort: max` — overkill for an orchestrator

**Current:** `model: opus`, `effort: max`
**Recommend:** `model: opus`, remove `effort:` (inherits xhigh default)

Rationale: `work-on` is a dispatcher — it routes work to child skills (`gather-context`, `plan`, `pr`, `reflect`). The deep thinking happens in the children. Running the dispatcher at max wastes tokens on orchestration decisions that don't benefit from max-tier reasoning, and risks overthinking per Anthropic's own warning about 4.7 on max.

### 2. `plan: effort: high` — downgraded below the 4.7 default

**Current:** `model: opus`, `effort: high`
**Recommend:** `model: opus`, remove `effort:` (inherits xhigh) — or set `effort: xhigh` explicitly

Rationale: Opus 4.7 defaults to xhigh. By setting `effort: high` we run planning at *less* than the default. For the one skill where reasoning depth matters most, this is backwards. Anthropic specifically recommends xhigh for planning.

### 3. `review-plan: model: sonnet` — category error

**Current:** `model: sonnet`
**Recommend:** `model: opus`, `effort: high`

Rationale: the skill's job is adversarial critical thinking — catching gaps, ambiguity, missing dependencies, wrong assumptions. Sonnet's "follows directions closely without drift" behavior is a liability here; it tends to validate rather than fight the plan. Opus at `effort: high` gives depth without the overthinking tax of xhigh/max.

## Full recommendation table

| Skill | Current | Recommend | Rationale |
|---|---|---|---|
| **work-on** | opus / max | **opus** (inherit xhigh) | Orchestrator; max overthinks dispatch |
| **plan** | opus / high | **opus** (inherit xhigh) | Don't downgrade from 4.7 default |
| **review-plan** | sonnet | **opus / high** | Adversarial analysis, Sonnet follows too closely |
| **grill-me** | inherit | **opus / xhigh** (pin) | Relentless interviewing needs depth |
| adr | opus | keep | Pressure-testing decisions |
| think | opus | keep | Rigorous thought partner |
| reflect | opus | keep | Judgment-heavy |
| write-skill | opus | keep | Design work |
| write-subagent | opus | keep | Design work |
| agents-md | opus | consider **sonnet / high** | Structured output, Sonnet-friendly — discuss |
| doc | sonnet | keep, consider **opus / high** | Diátaxis is prescriptive but docs need taste — discuss |
| commit | sonnet | keep | Format-following, Sonnet's strong suit |
| pr | sonnet | keep | Writing + git ops |
| project-manager | sonnet | keep | Structured issue writing |
| gather-context | sonnet | keep | Exploration |
| share-plan | sonnet | **haiku** | Mechanical formatting/posting |
| checkout | sonnet | **haiku** | Trivial git |
| youtube | sonnet | **haiku** | Mechanical transcript fetch |
| install-tool | haiku | **sonnet** | Detection logic is non-trivial |
| share-log | haiku | keep | Mechanical |
| bk | inherit | **haiku** (pin) | Tool calls + summary |
| hk | inherit | **haiku or sonnet** (pin) | Scripted bootstrap — discuss |
| copy | inherit | **haiku** (pin) | pbcopy |
| mob | inherit | **haiku** (pin) | Wraps `git mob` |
| export-log | inherit | **haiku** (pin) | Mechanical |
| gitingest | inherit | **haiku** (pin) | Fetch |
| gfm | inherit | **sonnet** (pin) | Writing/review |

## What this buys us

- **Consistent cost.** Pinning means every `/copy` costs Haiku regardless of session model.
- **Quality wins on three skills.** `work-on`, `plan`, and `review-plan` actually get better output, not just cheaper.
- **Reproducibility.** Aligns with the "pinned supply chain" principle — model choice is a dependency worth pinning explicitly.

## Open questions

1. **`work-on: max` — is there a reason I'm missing?** I'm recommending xhigh on Anthropic's own guidance, but if max has produced noticeably better orchestration in practice, that changes the call.
2. **`agents-md` — Opus vs Sonnet?** Generating AGENTS.md from scratch needs good writing. Has Opus been pulling its weight, or would Sonnet suffice given the skill's own structure?
3. **`doc` — Opus vs Sonnet?** Diátaxis is prescriptive and Sonnet follows plans closely, but docs need taste. Has there been a quality comparison?
4. **`hk` — haiku or sonnet?** Bootstrap is scripted but detection logic exists. Depends on how prescriptive the skill body is.
5. **`grill-me` — is xhigh right, or should it be max?** This is the one skill where max's "push until you find the flaw" tendency might actually pay off. Though the article says max often overthinks on routine stuff — "relentless interviewing" may or may not count as routine.

## Rollout plan

Split into two commits following the repo's "one change per commit" rule:

1. **Commit 1 — fix the three bugs:** `work-on`, `plan`, `review-plan`. This is a quality change, not a cost change. Worth landing on its own.
2. **Commit 2 — batch-pin the inheritance skills:** `bk`, `copy`, `export-log`, `gfm`, `gitingest`, `grill-me`, `hk`, `mob`. Same conceptual change applied uniformly. Acceptable as a batch per the "one logical change" interpretation.
3. **Commit 3 (optional) — adjust misfits:** `share-plan`, `checkout`, `youtube`, `install-tool`, and the `agents-md` / `doc` decisions once resolved in review.

Each commit needs `chezmoi diff && chezmoi apply home/dot_claude/skills/...` to validate the templates render correctly.

## References

- [Reddit — Claude Code effort levels explained](https://www.reddit.com/r/ClaudeCode/comments/1soqwfl/claude_code_effort_levels_explained_what/)
- Clipping: `~/Documents/Gusto/Clippings/Claude Code effort levels explained  - what LowMediumHighMax actually do (and which to use).md`
- [docs/vision.md](vision.md), [docs/core-principles.md](core-principles.md)
- `home/.chezmoitemplates/bedrock-model` — existing tier-resolution template
