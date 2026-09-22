---
name: checkout
description: Create a feature branch from the up-to-date default branch. Use when starting work on a new issue, dagger node, or feature.
argument-hint: "[#issue | slug#7 | branch-name]"
allowed-tools:
  - Bash(echo:*)
  - Bash(gh issue view:*)
  - mcp__plugin_dagger_dagger__show_node
  - Bash(git branch --show-current:*)
  - Bash(git checkout -b:*)
  - Bash(git fetch:*)
  - Bash(git remote get-url:*)
  - Bash(git status:*)
  - Bash(git symbolic-ref:*)
  - Bash(head:*)
  - Bash(sed:*)
  - EnterWorktree
---

# Checkout: Create a Feature Branch

**Autonomy:** model-invocable · acts autonomously — fetch, branch, and worktree creation are local and reversible · confirms before discarding uncommitted work

## Arguments
```
$ARGUMENTS
```

## Pre-computed Context

```
Current branch: !`git branch --show-current 2>/dev/null`
Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@refs/remotes/origin/@@' || echo "unknown"`
Dirty worktree: !`git status --porcelain 2>/dev/null | head -5`
Remote: !`git remote get-url origin 2>/dev/null || echo "no remote"`
```

## Constraints

- **Never use `git -C <path>`** — it rewrites the command prefix, breaking `allowed-tools` pattern matching.
- Do not force-delete branches or discard uncommitted work without user confirmation.

## Instructions

### 1. Parse Arguments

Determine what `$ARGUMENTS` contains:

| Pattern | Action |
|---------|--------|
| `#123` or issue URL | Fetch issue title, derive branch name |
| `slug#7` (dagger node) | `show_node` for title, kind and labels, derive branch name |
| Branch name (e.g., `feat/dark-mode`) | Use directly |
| Empty | Ask what to work on |

### 2. Derive Branch Name (from issue or node)

If `$ARGUMENTS` is an issue reference:

1. Fetch: `gh issue view <number> --json number,title,labels`
2. Derive branch name from issue metadata:
   - Check labels for conventional commit type hints (bug/fix labels → `fix/`, feature labels → `feat/`, chore/maintenance labels → `chore/`, default → `feat/`)
   - Format: `<prefix><number>-<kebab-case-title>` (e.g., `feat/123-add-dark-mode`)
   - Truncate to 60 characters max

If it is a dagger node reference, the same shape with `kind` as the type hint (`bug` → `fix/`, `chore` → `chore/`, `spike` → `spike/`, default → `feat/`) and labels as a tiebreak. **Do not put the node number in the branch name** — a branch called `feat/3-…` reads as "issue 3" to every tool that parses branch names, and the node reference belongs in the PR body instead.

### 3. Handle Dirty Worktree

Check pre-computed context for dirty worktree. If dirty:

| Situation | Action |
|-----------|--------|
| Changes are staged/unstaged for current work | Suggest `/commit` first or `git stash` |
| Unrelated leftover changes | Suggest `git stash` with descriptive message |
| Merge conflicts (git status shows `UU`/`AA`/`DD` entries) | Inform user and wait for guidance |

Do not silently discard changes.

### 4. Create the Branch

1. `git fetch origin` — ensure we have latest
2. Decide approach:

| Context | Approach |
|---------|----------|
| Work came from a shared queue — a dagger node, or any graph other agents claim from | **`EnterWorktree`.** Default to isolation: concurrent agents in one working tree produce a corrupted diff |
| User explicitly requested worktree | Use `EnterWorktree` |
| On another feature branch | Prefer `EnterWorktree`; `git checkout -b` only if the user wants simplicity |
| On default branch, clean state, solo work | `git checkout -b <branch> origin/<default>` |

A worktree switches the session's cwd, not its reach — writes outside the tree still work, so a path outside it must be absolute and deliberate, because a relative one silently lands in the worktree. What *is* restricted is Bash: the isolation guard scans each command's text and refuses anything it cannot prove stays inside, which includes a heredoc whose **content** merely mentions git. Use `Write` for those files rather than fighting the quoting.

### 5. Report and Continue

Report the branch name and abbreviated base commit SHA (e.g., `Created feat/123-add-dark-mode from origin/main (abc1234)`), then immediately mark this task complete and execute the next task in the workflow.
