---
status: "accepted"
date: 2026-09-14
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Skills Inherit the Session Model and Effort

## Context and Problem Statement

Every user-scope skill pinned `model:` (via the `bedrock-model` template partial)
and two pinned `effort:`. Claude Code keeps a separate prompt cache per model, and
a skill whose frontmatter names a model other than the session's is a model switch
for that turn: the request reads the entire conversation history with no cache
hits, and the return to the session model on the next prompt does so again. On
most models `effort:` behaves the same way. With the session on Fable and every
skill pinned to `opus` or `sonnet`, each `/commit` or `/plan` cost two uncached
re-reads of the whole conversation, on top of running the skill itself.

The pins were introduced for two reasons that no longer hold. Model tiering was
meant to right-size cost per skill, but a cache miss on a long session dwarfs the
per-token difference between tiers. The `bedrock-model` partial worked around a
Claude Code 2.1.37 bug where friendly aliases broke on Bedrock; aliases now
resolve there, and the project's own config has `use_bedrock = false`.

## Decision Drivers

- **Token cost is dominated by cache behaviour.** A cache hit costs about a tenth
  of an uncached read. Anything that forces a full re-read on every skill
  invocation outweighs any saving from a cheaper model.
- **Skills compose.** `/work-on` delegates to `/gather-context`, `/plan`,
  `/pr`, `/reflect`; each distinct pin in that chain is another pair of cache
  misses.
- **The session model is the user's choice.** A skill overriding it, silently,
  per turn, is a surprise rather than a feature.

## Considered Options

1. Drop `model:` and `effort:` from every skill; let skills inherit the session
2. Keep pins but align them all to one model
3. Keep pins, move the expensive skills to `context: fork`

## Decision Outcome

Chosen option: **drop `model:` and `effort:` from every skill**, because it is the
only option that removes the cache miss under every session model, and there is
no remaining benefit to weigh against it.

Subagents (`home/dot_claude/agents/`) keep their pins. A subagent runs in its own
context, so its model does not touch the main conversation's cache. The
`bedrock-model` partial and `bin/resolve-bedrock-models` stay for that use.

### Consequences

- **Good**: a skill invocation no longer invalidates the conversation cache.
- **Good**: user-scope skills are plain `SKILL.md` unless the body needs a chezmoi
  directive; nineteen `.tmpl` files became `.md`.
- **Good**: the `/write-skill` guidance no longer asks authors to choose a tier.
- **Bad**: a skill that benefits from more reasoning than the session default
  has no per-skill knob. Ask for it in the body, or switch the session with
  `/model` or `/effort` before invoking.
- **Neutral**: if a future Claude Code version keeps the cache across model
  switches, this decision can be revisited; the cost then reduces to plain
  per-tier pricing.

## Rejected Options

### Align every pin to one model

Pin every skill to the same tier so switches happen only when the session model
differs from that tier.

- **Good**: cost is predictable regardless of session model.
- **Bad**: the session model is whatever the user picked, so the switch, and the
  double cache miss, still happens whenever it differs. The user's session at the
  time of this decision ran a model no skill was pinned to.

### Fork the expensive skills

Run pinned skills under `context: fork` so the switch happens in a subagent.

- **Good**: the main cache survives.
- **Bad**: forking discards the conversation the skill needs. `/plan`, `/commit`,
  and `/reflect` exist to act on what the session just did.

## More Information

- Claude Code docs: prompt caching (per-model cache, skill `model:` as a switch),
  skills frontmatter (`model:` and `effort:` apply to the current turn only).
- ADR-007 for the skill autonomy axes that the `/write-skill` frontmatter
  template also encodes.
- Revisit if Claude Code documents cache reuse across model or effort changes.
