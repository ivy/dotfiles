# GitHub Labels

Labeling system for issue triage and agent-driven prioritization.

## Design Principles

Labels answer three questions:

1. **What should I work on next?** (priority)
2. **Can an agent do this autonomously?** (readiness)
3. **What part of the stack is this?** (area)

A label that doesn't get applied is worse than no label. The system is intentionally small.

## Label Taxonomy

### Priority

Every open issue gets exactly one priority label.

| Label | Meaning | Agent behavior |
|-------|---------|----------------|
| `p0:now` | Broken or blocking current work | Agent should flag immediately |
| `p1:soon` | Wanted this week / next session | Agent picks these up first |
| `p2:later` | Backlog — do when convenient | Agent works these when nothing higher exists |
| `p3:someday` | Nice idea, no urgency | Agent ignores unless explicitly asked |

### Readiness

Every open issue gets exactly one readiness label.

| Label | Meaning |
|-------|---------|
| `for:agent` | Fully specified — an agent can execute without human guidance |
| `for:human` | Requires hands-on work, hardware access, interactive setup, or human judgment calls |

An issue is `for:agent` when the title and body contain enough context for an agent to: understand the goal, find the relevant files, make the change, and verify it worked. If an agent would need to ask "what do you mean by X?" — it's `for:human` until the spec is tightened.

### Status

| Label | Meaning |
|-------|---------|
| `blocked` | Waiting on an external dependency, upstream fix, or another issue. Body should say what it's blocked on. |

Most status lives in GitHub's open/closed state. `blocked` is the one exception worth tracking because it prevents repeated triage of immovable items.

### Type

Describes the nature of the work.

| Label | Scope |
|-------|-------|
| `type:feature` | New capabilities, integrations, or enhancements |
| `type:bug` | Something is broken |
| `type:chore` | Dependency updates, refactoring, cleanup, configuration tuning |
| `type:workflow` | Process improvements, shortcuts, automation |
| `type:security` | Security hardening or credential management |
| `type:test` | Testing infrastructure or coverage |

### Area

Which part of the stack an issue touches. An issue gets one area label. If it spans multiple areas, pick the primary one.

| Label | Scope |
|-------|-------|
| `area:claude` | Claude Code integration — hooks, statusline, skills, agent infra |
| `area:tmux` | tmux config, plugins, powerline, pane management |
| `area:nvim` | Neovim / LazyVim config and plugins |
| `area:shell` | zsh, oh-my-zsh, shell functions, starship prompt |
| `area:git` | Git config, delta, branch protection, workflow |
| `area:mise` | mise config, tool versions, lockfiles, aqua backend |
| `area:renovate` | Renovate config, dependency automation, version pinning |
| `area:os` | macOS/Linux platform config, security hardening, install scripts |

These map to the stack layers in CLAUDE.md. Resist adding more — if an area has fewer than 3 issues historically, it doesn't need a label.

## What's Not Here

**Effort/size labels** — Solo repo. You know how big something is when you read it. Agents don't need T-shirt sizing to pick up `for:agent` work.

**Default GitHub labels** — `bug`, `enhancement`, `documentation`, `good first issue`, `help wanted`, `invalid`, `question`, `wontfix`, `duplicate` are all deleted. They overlap with `type:` labels or don't apply to a personal repo.

## Labeling Workflow

When creating an issue:
1. Assign a **priority** (`p0`–`p3`)
2. Assign **readiness** (`for:agent` or `for:human`)
3. Assign an **area** (`area:claude`, `area:tmux`, etc.)
4. Optionally assign a **type** if not obvious from context

If labeling feels like overhead, the system is broken.

## Agent Triage Query

An agent looking for work should query:

```bash
# Highest priority agent work
gh issue list --label "for:agent" --label "p1:soon" --state open

# Scoped to an area
gh issue list --label "for:agent" --label "area:claude" --state open
```

Fallback to `p2:later` + `for:agent` when `p1` is empty.
