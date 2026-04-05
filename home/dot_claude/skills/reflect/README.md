# `/reflect` — Session Retrospective

Review what happened in a session, extract lessons that will improve future sessions, and persist them where they'll actually be used.

```
/reflect
/reflect the privilege model work
/reflect what went well
```

## Why this exists

Every complex task reveals something. A file that needed to exist but didn't. An instruction that turned out to be ambiguous. A pattern that worked well and should be reinforced. A friction point that should become a skill.

Without [`/reflect`](../reflect/README.md), this knowledge evaporates when the session ends. The next session makes the same mistakes, hits the same friction, re-prompts the same patterns. This is the gap between a development environment that gets better over time and one that stays flat.

[`/reflect`](../reflect/README.md) closes that loop. It's the mechanism by which working with the agent compounds: each session's lessons become the next session's starting point.

## What it produces

The retrospective identifies findings in three categories:

**What went wrong** — mistakes, surprises, friction. Not a list of everything that was hard, but patterns worth capturing: the class of error, the root cause, the fix. "I forgot to apply chezmoi" is noise. "Always run `chezmoi apply` after editing templates, not just `chezmoi diff`" is signal.

**What went well** — validated approaches, especially non-obvious ones. These matter as much as corrections. If the agent tried an unusual approach and you accepted it without pushback, that's a signal worth preserving — otherwise it will second-guess the same choice next time.

**Proposed actions** — each finding maps to a destination:
- `[memory]` — feedback or project memory for future sessions
- `[AGENTS.md]` — context that should be documented for all agents in this project
- `[code]` — a tech debt or DX improvement worth tracking
- `[skip]` — one-off, already in git history, not worth persisting

Everything requires your approval before it's written. You edit the list, drop what doesn't apply, and confirm. Then [`/reflect`](../reflect/README.md) executes: writes memories, updates AGENTS.md, and files GitHub issues for code improvements.

## In the [`/work-on`](../work-on/README.md) workflow

[`/reflect`](../reflect/README.md) runs at the end of Large and Epic tier workflows. Smaller tasks rarely reveal patterns worth capturing — but a multi-session epic almost always surfaces something: friction in the tooling, a gap in the skills, a pattern that should be automated.

The output feeds the issue backlog directly (`gh issue create`). Over time, this creates a prioritized, evidence-backed list of self-improvement work — not aspirational cleanup, but specific fixes grounded in actual friction.

## Standalone usage

[`/reflect`](../reflect/README.md) is useful after any session with significant friction, surprising discoveries, or novel approaches worth reinforcing. It doesn't have to follow a [`/work-on`](../work-on/README.md) workflow — any substantial session is a candidate.
