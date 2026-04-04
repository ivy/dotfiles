---
name: allow
description: Add a tool pattern to the global Claude Code permissions allow list in bin/sync-claude-settings
argument-hint: "[tool pattern, e.g. 'git check-ignore', 'limactl', '/think', 'docs.rs']"
allowed-tools:
  - Read(bin/sync-claude-settings)
  - Edit(bin/sync-claude-settings)
  - Bash(bin/sync-claude-settings)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git diff:*)
  - Bash(git status:*)
  - Grep
---

# Allow Tool

Add tool patterns to the global Claude Code permissions managed by `bin/sync-claude-settings`.

## Arguments
```
/allow git check-ignore
/allow limactl
/allow /think
/allow docs.rs
```

## Instructions

### 1. Parse the pattern

Infer the full permission string from the argument:

| Input | Resulting pattern | Why |
|-------|-------------------|-----|
| `git check-ignore` | `Bash(git check-ignore:*)` | bare words → Bash |
| `limactl` | `Bash(limactl:*)` | bare word → Bash |
| `/think` | `Skill(think:*)` | leading slash → Skill |
| `/commit` | `Skill(commit:*)` | leading slash → Skill |
| `docs.rs` | `WebFetch(domain:docs.rs)` | looks like a domain → WebFetch |
| `raw.githubusercontent.com` | `WebFetch(domain:raw.githubusercontent.com)` | domain → WebFetch |
| `Bash(make:*)` | `Bash(make:*)` | already formatted |
| `Skill(think:*)` | `Skill(think:*)` | already formatted |
| `WebFetch(domain:docs.rs)` | `WebFetch(domain:docs.rs)` | already formatted |

Heuristics:
- Starts with `/` → `Skill(<name>:*)`
- Contains a `.` and looks like a domain (no spaces) → `WebFetch(domain:<input>)`
- Already wrapped in `Bash(...)`, `Skill(...)`, `WebFetch(...)`, `Read(...)` → pass through
- Everything else → `Bash(<input>:*)`

### 2. Decision framework

A command belongs on the allow list based on its side-effect profile:

**Allow (no confirmation needed):**
- **Pure reads** — queries state, never mutates it (`ps`, `stat`, `file`, `which`, `uname`, `dig`)
- **Pure transforms** — reads stdin/files, writes only to stdout (`sort`, `uniq`, `cut`, `jq`, `base64`, `shasum`)
- **Bounded benign writes** — side effects are trivial and easily reversed (`mkdir`, `touch`, `mktemp`, `rmdir` empty dirs only)

**Reject (warn, require explicit confirmation):**
A command does NOT belong if it can:
- **Write to arbitrary files** — `tee`, `cp`, `mv`, output redirection
- **Execute arbitrary subcommands** — `xargs`, `sh`, `bash`, `eval`, `python`, `ruby`, `perl`, `node`
- **Publish or transmit data** — `curl`, `wget`, `ssh`, `scp`, `rsync`, `git push`
- **Destroy state** — `rm`, `kill`, `killall`
- **Escalate privileges** — `sudo`, `doas`
- **Mutate permissions or identity** — `chmod`, `chown`
- **Access or leak secrets** — `gpg`, `security`, `keychain`, `op`, `env`, `printenv`, `history`
- **Mutate cloud infra** — `aws`, `gcloud`, `az`
- **Mutate global config** — `git config` (can write `~/.gitconfig` via `--global`)

**Warn and suggest narrowing** for overly broad patterns:
- `Bash(*)` — universal wildcard
- Multi-subcommand tools where we already scope by subcommand: `Bash(git:*)`, `Bash(npm:*)`, `Bash(gh:*)`
- `WebFetch(domain:*)` — wildcard domain
- `Read(...)` / `Edit(...)` with broad paths — can expose or modify sensitive files

For reject and narrowing cases: explain which property is violated, suggest a safer alternative if possible, and ask the user to confirm. If they confirm, proceed.

### 3. Check for duplicates

Grep `bin/sync-claude-settings` for the exact resolved pattern. If it already exists, tell the user and stop.

### 4. Add the pattern

Edit `bin/sync-claude-settings`, inserting the new pattern into the `set_permissions()` function's allow array in **alphabetical order** among its peers.

### 5. Review the edit

Run `git diff bin/sync-claude-settings` and verify:
- Exactly one line was added
- The jq heredoc is still valid (no unclosed quotes)
- The pattern is in the correct alphabetical position

### 6. Apply and commit

```bash
bin/sync-claude-settings
```

Then use `/commit` to commit `bin/sync-claude-settings`.

## Examples

```
/allow git check-ignore    → adds "Bash(git check-ignore:*)", applies, commits
/allow limactl             → adds "Bash(limactl:*)", applies, commits
/allow /think              → adds "Skill(think:*)", applies, commits
/allow docs.rs             → adds "WebFetch(domain:docs.rs)", applies, commits
/allow git push            → REJECTS: publishes to remote. Proceeds only if user confirms.
/allow printenv            → REJECTS: can leak secrets from environment. Proceeds only if user confirms.
/allow npm                 → NARROWS: too broad, suggests npm run, npm test, etc. Proceeds only if user confirms.
```
