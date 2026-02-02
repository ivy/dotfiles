---
name: agents-md
description: "Use when asked to create or update an AGENTS.md onboarding file for coding agents, or when asked to bootstrap agent documentation for a repository."
argument-hint: "[repo-path]"
model: opus
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(ls:*)
  - Bash(tree:*)
  - Bash(file:*)
---

# AGENTS.md Generator

You are a coding agent working inside THIS repository. Your task is to create a high-signal, low-bloat onboarding file for coding agents.

## Arguments

```
$ARGUMENTS
```

If arguments include a repo path, `cd` there first. Otherwise, operate on the current working directory.

## Deliverables

1. Create (or update) a root-level file named `AGENTS.md`.
2. Create (or update) a root-level symlink `CLAUDE.md` that points to `AGENTS.md`.

## Core Principles (do not violate)

- Assume the model is stateless: every session starts with zero repo knowledge.
- Less is more: include ONLY universally applicable info. If it won't help for most tasks, don't put it in AGENTS.md.
- Prefer pointers over copies: avoid code snippets and long lists. Prefer "see [document](path/to/document#heading)" references.
- Progressive disclosure: if deeper, task-specific guidance is needed, point to (or create) separate small docs under `docs/agents/` with self-descriptive names. AGENTS.md should index those docs, not duplicate them.
- Don't use the agent as a linter: don't paste style guides. Rely on existing formatters/linters and show only the canonical commands to run them.
- Keep it concise: aim for <150 lines, hard cap 300 lines.

## Workflow

### 1. Repo discovery

Use the tools you have: filesystem, grep, tree, package managers, etc.

- Read root README and any top-level docs to understand the project's purpose and structure.
- Identify the "source of truth" for build/test/run commands:
	- package.json scripts / pnpm-workspace / turbo / nx / bun
	- Makefile
	- pyproject.toml / tox.ini
	- go.mod / magefile
	- docker-compose / justfile / taskfile
	- CI config (GitHub Actions, Buildkite, etc.) for canonical checks
- Identify monorepo layout (apps/, packages/, services/, libs/, etc.) and what each is for.
- Identify "gotchas" that matter broadly (required env vars, bootstrap steps, codegen, DB migrations, local stack).

### 2. Write `AGENTS.md`

Follow THIS structure (keep each section short and skimmable):

   1. Purpose (WHY) — 2-5 bullets
      - What this repo is for, and what success looks like.
   2. Repo map (WHAT) — compact directory map
      - Top-level directories + one-line descriptions.
      - If monorepo: list key apps/packages and how they relate.
   3. How to work here (HOW) — the minimum commands that actually matter
      - Setup/bootstrap: the single best "first command".
      - Build: canonical command(s).
      - Test: canonical command(s) (unit/integration/e2e if truly standard).
      - Typecheck/lint/format: canonical command(s) (no rule lists).
      - Run/dev: canonical command(s).
      - "Verify before you open a PR": the shortest reliable check sequence.
      Notes:
      - Prefer referencing existing scripts ("See [package.json](path/to/package.json)") over duplicating many commands.
      - If multiple stacks exist, give a tiny "most common path" + pointers for the rest.
   4. Change hygiene — universal expectations (max ~8 bullets)
      - Examples: keep diffs small, add/adjust tests, follow existing patterns, don't do repo-wide reformatting, don't commit secrets, explain tradeoffs in PR description, etc.
   5. Progressive disclosure index (docs/agents/)
      - Create `docs/agents/` only if needed.
      - Add a short list like:
        - docs/agents/running-tests.md — deeper test matrix (read when modifying CI/tests)
        - docs/agents/service-architecture.md — service boundaries (read when changing APIs)
      - Each doc should be short, pointer-heavy, and avoid code duplication.
   6. "Where to look first" (2-6 bullets)
      - The few best files/dirs for common tasks (e.g., config, main entrypoints, API definitions).

### 3. Implementation details (files + symlink)

- Write `AGENTS.md` at repo root.
- Create/update the symlink so `CLAUDE.md -> AGENTS.md` (relative symlink).
- If `CLAUDE.md` exists as a real file, replace it with a symlink (unless the repo forbids it; if so, explain).

### 4. Open for human review

After writing `AGENTS.md`, open it in a new tmux pane for the user to review and edit:

```bash
tmux split-window -h "$EDITOR AGENTS.md"
```

### 5. Quality Bar (self-check before finishing)

- Would ~80% of tasks benefit from everything in AGENTS.md? If not, delete or move to docs/agents/.
- Is it skimmable in under 60 seconds?
- Did you avoid long command menus, style rule dumps, and code snippets?
- Did you include the minimum set of commands to build/test/verify changes?
- Did you add precise pointers to authoritative docs/files instead of duplicating content?

## Output Requirements

- Commit-ready `AGENTS.md` content.
- Ensure `CLAUDE.md` is a symlink to `AGENTS.md`.
- In your final response, summarize what you changed and where you found the canonical commands (file paths).
