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

### 2. Safety check

Apply the safety check to the **resolved pattern from step 1**, not the raw input.

**Warn and require explicit confirmation** for patterns that can publish, destroy, or leak:
- `git push` — publishes to remote
- `git config` — can write to global `~/.gitconfig`
- `rm`, `rm -rf`, `rm -r` — destructive
- `curl * | bash`, `wget * | sh` — remote code execution
- `sudo` — privilege escalation
- `sh`, `bash`, `zsh`, `python`, `ruby`, `perl`, `node` (bare interpreter) — arbitrary code execution
- `ssh`, `scp`, `rsync` — remote access
- `gpg`, `security`, `keychain` — secrets access
- `aws`, `gcloud`, `az` — cloud CLI (can mutate infra or leak creds)
- `chmod`, `chown` — permission manipulation

**Warn and suggest narrowing** for overly broad patterns:
- `Bash(*)` — universal wildcard
- Single-segment tool wildcards: `Bash(git:*)`, `Bash(npm:*)`, `Bash(gh:*)`, `Bash(docker:*)`, `Bash(cargo:*)`, `Bash(bundle:*)`
- `WebFetch(domain:*)` — wildcard domain

For both cases: explain the risk, suggest a safer alternative if possible, and ask the user to confirm. If they confirm, proceed.

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
/allow git push            → WARNS: publishes to remote. Proceeds only if user confirms.
/allow npm                 → WARNS: too broad. Suggests npm run, npm test, etc. Proceeds only if user confirms.
```
