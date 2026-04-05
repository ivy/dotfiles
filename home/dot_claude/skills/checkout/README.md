# `/checkout` — Create a Feature Branch

Start work on an issue or feature by creating a well-named branch from an up-to-date base.

```
/checkout #123
/checkout feat/my-feature
```

## Why this exists

Three things go wrong when developers (or agents) branch manually:

**Stale base.** Branching from a local `main` that hasn't been fetched recently means the branch starts behind. The PR will have a larger diff than necessary, and merge conflicts are more likely.

**Untracked naming.** A branch named `fix` or `wip` has no connection to the work it represents. A branch named `fix/123-login-redirect-loop` is immediately traceable to its issue, commit message conventions are obvious, and `git log --branches` is readable.

**Lost work.** Starting a new branch while the working tree is dirty risks forgetting about uncommitted changes. [`/checkout`](../checkout/README.md) surfaces this and forces a decision before anything gets created.

## How to use it

**From an issue reference** — the agent fetches the issue title and derives a conventional branch name:
```
/checkout #123
→ creates feat/123-add-dark-mode (or fix/, chore/, etc. based on issue labels)
```

**With an explicit name** — used directly when you already know the branch name:
```
/checkout refactor/auth-middleware
```

**If the working tree is dirty**, the agent will surface what's changed and ask whether to stash, commit first, or abort. It won't silently discard work.

## Branch naming

Branch names are derived from the issue number and title: `<prefix>/<number>-<kebab-case-title>`. The prefix is inferred from the issue's type labels (bug/fix labels → `fix/`, feature labels → `feat/`, chore/maintenance → `chore/`, default → `feat/`). Names are truncated at 60 characters.

## Worktrees vs. branches

By default, the agent creates a standard `git checkout -b` branch. When you're already on a feature branch and need to start another, it may use `EnterWorktree` instead — giving you two isolated working trees from the same repo. The agent decides based on context; you can override by requesting one explicitly.

## In the [`/work-on`](../work-on/README.md) workflow

[`/checkout`](../checkout/README.md) is Phase 1, Step 1. It runs first, before any investigation or planning, so all subsequent work happens on the right branch from the start. The branch name ties the eventual PR back to the issue automatically when using `gh pr create`.
