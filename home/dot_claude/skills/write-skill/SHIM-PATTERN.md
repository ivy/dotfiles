# Shim Pattern for Skills

A shim is a wrapper script that enforces constraints on an underlying command. Use sparingly—most skills don't need this.

## When to Use

Consider a shim when:
- A flag must **always** be present (e.g., `--web` for human review)
- You want to restrict dangerous defaults without limiting `allowed-tools` granularity
- The underlying command is risky without certain constraints
- You need to transform or validate arguments before passing through

## Example: PR Creation Shim

The `/pr` skill uses a shim to enforce `--web`:

```bash
#!/usr/bin/env bash
# $SKILL_DIR/gh-pr-create-web
# Enforces --web flag so PRs always open in browser for human review

set -euo pipefail

# Ensure --web is always included
exec gh pr create --web "$@"
```

**Why:** Prevents accidental automated PR creation. Every PR opens in browser for final human review before submission.

## Structure

Place shims in the skill directory with executable permission:

```
skills/
└── my-skill/
    ├── SKILL.md
    └── executable_my-shim    # chezmoi prefix for executable
```

Reference in `allowed-tools`:

```yaml
allowed-tools:
  - Bash($SKILL_DIR/my-shim:*)
```

## Shim Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate or transform arguments here
# Example: require a flag
if [[ ! " $* " =~ " --safe " ]]; then
    echo "Error: --safe flag required" >&2
    exit 1
fi

# Pass through to real command
exec real-command "$@"
```

## Trade-offs

**Pros:**
- Enforces invariants the skill can't accidentally bypass
- Clear audit trail (shim documents the constraint)
- Works even if skill instructions are ignored

**Cons:**
- Added complexity and indirection
- Another file to maintain
- Requires shell scripting knowledge

## Alternatives

Before reaching for a shim, consider:

1. **Narrow `allowed-tools`**: `Bash(gh pr create --web:*)` instead of `Bash(gh pr create:*)`
2. **Clear instructions**: Sometimes explicit "always use --web" is sufficient
3. **Trust the model**: Well-written instructions usually work

Use shims for high-stakes operations where failure to include a flag could cause real harm.
