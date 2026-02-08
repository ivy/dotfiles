# Plan: Enforce Source Directory Hook

**Status**: Implemented ([#112](https://github.com/ivy/dotfiles/issues/112))

## Problem

Claude Code frequently tries to read/write files directly in `~/` (e.g., `~/.zshrc`,
`~/.config/ghostty/config`) instead of editing the chezmoi source files in
`home/` within the project. This happens because upstream docs say "edit `~/.zshrc`"
and agents follow literally. Changes made directly to `~/` get overwritten on
the next `chezmoi apply`, losing work.

## Solution

A `PreToolUse` hook that intercepts file operations and Bash commands targeting
the home directory. Writes are hard-blocked (deny); reads and Bash commands get
soft warnings via `additionalContext`.

## Files

| File | Purpose |
|------|---------|
| `.claude/hooks/enforce-source-dir.sh` | Hook script — all detection + decision logic |
| `.claude/settings.json` | Hooks configuration — wires the script to PreToolUse events |
| `test/enforce-source-dir-hook.bats` | BATS test suite (13 tests) |

## Hook Behavior

All logic is in **PreToolUse** (supports both `permissionDecision` for denials and
`additionalContext` for soft warnings).

| Tool | Condition | Action | Mechanism |
|------|-----------|--------|-----------|
| `Write`, `Edit`, `MultiEdit` | `file_path` under `$HOME/` but NOT under `$CLAUDE_PROJECT_DIR/` | Hard block | `decision: "deny"` |
| `Read` | `file_path` under `$HOME/` but NOT under `$CLAUDE_PROJECT_DIR/` | Soft warn | `additionalContext` |
| `Bash` | Command references `~/`, `$HOME/`, or literal home path; **not** a chezmoi command | Soft warn | `additionalContext` |
| Any | Path inside project dir, or outside `$HOME` entirely | Allow | exit 0, no output |

## Key Design Decisions

1. **All PreToolUse, no PostToolUse** — simpler than a split approach and blocks writes *before* they happen.

2. **Only Write/Edit/MultiEdit get hard-blocked** — Bash commands are soft-warned only. Pattern-matching shell commands is inherently imprecise, and false-positive blocks would be worse than a missed warning.

3. **Chezmoi commands exempted** — `chezmoi diff`, `chezmoi apply`, `chezmoi status` legitimately reference `~/`. The script strips leading whitespace and env-var assignments (`DEBUG=1 chezmoi apply`) before checking.

4. **Deny message teaches `chezmoi source-path`** — instead of hardcoding path translations, the deny message gives the agent an executable command. The agent runs it, gets the exact source path, and self-corrects.

5. **Path canonicalization** — `realpath` for existing paths (handles symlinks, `..`). For new files, resolve the parent dir. Bash commands use string matching (best-effort, accepted tradeoff).

6. **Performance** — single `jq` call to extract all fields. Total ~10-15ms per hook invocation.
