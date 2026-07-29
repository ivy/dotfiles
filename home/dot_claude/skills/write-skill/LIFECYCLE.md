# Skill Lifecycle & Limits

Mental model for how Claude Code loads, retains, and discovers skills. The implications shape how you write them.

## Content lifecycle

When a skill is invoked, its rendered `SKILL.md` enters the conversation as a **single message and stays there for the rest of the session**. Claude Code does NOT re-read the file on later turns.

**Implications:**
- Every line is a recurring token cost — keep the body dense.
- Write guidance as **standing instructions**, not one-time steps ("when X, do Y" beats "now do Y").
- If a skill seems to stop influencing behavior, the content is usually still present; the model is just choosing other paths. Strengthen the description and instructions, or enforce with hooks.

## Auto-compaction

When context fills and Claude Code summarizes the conversation, invoked skills are re-attached after the summary:

- Each re-attached skill keeps its **first 5,000 tokens**.
- All re-attached skills share a **combined 25,000-token budget**, filled most-recent-first.
- If you invoked many skills, the oldest can be **dropped entirely** after compaction.
- If a long skill matters after compaction, **re-invoke it** to restore the full content.

## Description budget

Skill names are always listed; descriptions compete for a character budget:

- `description + when_to_use` are concatenated and capped at **1,536 characters** per skill (`maxSkillDescriptionChars` to override).
- Put the **key use case first** — that's what survives truncation.
- Total skill-listing budget scales at **1% of the model's context window** (`skillListingBudgetFraction` to raise, e.g. `0.02` = 2%).
- When the budget overflows, the **least-used skills lose their description first**.
- Set low-priority entries to `"name-only"` in `skillOverrides` to free budget for others.
- Run `/doctor` to see whether the budget is overflowing.

## Discovery

**Live change detection:** Edits to existing skill files under `~/.claude/skills/`, project `.claude/skills/`, or `.claude/skills/` inside an `--add-dir` directory are picked up **without restarting** the session. Creating a brand-new top-level skills directory that didn't exist at session start **does** require a restart.

**Parent-directory walk:** Project skills load from `.claude/skills/` in your starting directory and **every parent up to the repo root**. Starting in a subdirectory still finds repo-root skills.

**Nested discovery:** When you work with files below your starting directory, nested `.claude/skills/` directories are loaded on demand (monorepo packages can ship their own).

**`--add-dir` exception:** Additional directories grant file access, not config discovery — but `.claude/skills/` inside them **is** auto-loaded. Subagents, commands, and output styles are NOT.

## Practical sizing

- Aim for `<60 lines` in the SKILL.md body (platform tip says `<500`, but dense is better than long since it persists).
- Move large reference material to sibling files and reference them from SKILL.md — supporting files load **only when needed**, not on every invocation.
- `description + when_to_use` together: target well under 1,536 chars, key use case at the front.
