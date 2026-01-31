# Skill Review Checklist

Use this checklist when reviewing skills before deployment. Give this file to the reviewer agent.

## Understanding `allowed-tools`

**Critical distinction:** `allowed-tools` controls what runs WITHOUT user approval, not what the skill CAN use.

- Tools IN `allowed-tools` → execute automatically
- Tools NOT in `allowed-tools` → prompt user for approval before executing

A skill can instruct execution of any tool. Omitting dangerous tools from `allowed-tools` is the CORRECT safety pattern—it ensures the user approves those operations.

### Good Pattern: Gate Dangerous Operations

```yaml
# PR skill - auto-allows only safe reads, gates publication
allowed-tools:
  - Glob
  - Read
# git push, gh pr create → will prompt for approval ✓
```

This skill can still run `git push` and `gh pr create`—it just requires user confirmation first. This is safe and intentional.

### Bad Pattern: Auto-Allow Dangerous Operations

```yaml
# Dangerous - auto-allows publication without approval
allowed-tools:
  - Bash(git:*)
  - Bash(gh:*)
```

## The Cardinal Rule

**If you can't undo it locally, don't auto-allow it.**

Operations that publish externally, delete data, or modify system state should require user approval (i.e., be OMITTED from `allowed-tools`).

## Red Flags (Reject immediately)

These patterns in `allowed-tools` auto-permit dangerous operations:

| Pattern | Why it's dangerous |
|---------|-------------------|
| `Bash(git:*)` | Auto-permits push, reset --hard, clean -f, force push |
| `Bash(npm:*)` | Auto-permits publish, global install, token access |
| `Bash(docker:*)` | Auto-permits push, login, system prune |
| `Bash(gh:*)` | Auto-permits create, merge, delete, release |
| `Bash(curl:*)` | Auto-permits POST, DELETE, data exfiltration |
| `Bash(rm -rf:*)` | Unrestricted recursive deletion |
| Any `--force` without justification | Bypasses safety checks |

## Quick Decision Rules

Before AUTO-ALLOWING a command (adding to `allowed-tools`):

1. **Can it publish externally?** (push, deploy, create) → OMIT (require approval)
2. **Can it delete data?** (rm, clean, reset --hard) → OMIT (require approval)
3. **Can it expose secrets?** (cat sensitive, env vars) → OMIT (require approval)
4. **Does it affect global state?** (install -g, system config) → OMIT (require approval)
5. **Is it read-only?** (status, log, diff, view, list) → ALLOW
6. **Is it local and reversible?** (add, stage, build) → CONDITIONAL

## Safe vs Unsafe to Auto-Allow

### Git

```yaml
# SAFE to auto-allow - read-only, local inspection
- Bash(git status:*)
- Bash(git log:*)
- Bash(git diff:*)
- Bash(git branch --list:*)
- Bash(git show:*)
- Bash(git blame:*)

# CONDITIONAL - local staging (reversible)
- Bash(git add:*)

# NEVER auto-allow - require user approval
# (omit from allowed-tools, skill can still use them)
# - git push         # external publication
# - git reset --hard # data loss
# - git clean        # data loss
# - git checkout .   # data loss
```

### npm/yarn/pnpm

```yaml
# SAFE to auto-allow - read-only
- Bash(npm view:*)
- Bash(npm ls:*)
- Bash(npm audit:*)

# CONDITIONAL - local project
- Bash(npm test:*)
- Bash(npm run lint:*)

# NEVER auto-allow
# - npm publish      # external publication
# - npm install -g   # system-wide
```

### GitHub CLI

```yaml
# SAFE to auto-allow - read-only
- Bash(gh pr view:*)
- Bash(gh pr list:*)
- Bash(gh issue view:*)

# NEVER auto-allow
# - gh pr create     # external publication
# - gh pr merge      # modifies remote
# - gh release create # external publication
```

### Docker

```yaml
# SAFE to auto-allow - inspection
- Bash(docker ps:*)
- Bash(docker images:*)
- Bash(docker logs:*)

# CONDITIONAL
- Bash(docker build:*)

# NEVER auto-allow
# - docker push      # external publication
# - docker login     # credential handling
```

## Mental Models

### The "Unattended Machine" Test

> Would you be comfortable if auto-allowed operations ran while you were away?

Operations requiring review should be omitted from `allowed-tools` so they prompt.

### The "Intern with Root" Test

> Would you give an unsupervised intern permission to run these automatically?

Captures both skill level AND trust level required for auto-approval.

## Review Process

1. **Check `allowed-tools`** against red flags above—are dangerous ops auto-allowed?
2. **Verify dangerous operations are gated**: Instructions may use git push, gh create, etc.—that's fine IF they're not in `allowed-tools`
3. **Apply narrowing principle**: Is the most specific pattern used for auto-allowed tools?
4. **Verify shims use hardcoded paths** (not `$SKILL_DIR`—that doesn't exist)
5. **Check instruction clarity**: Are dangerous operations clearly documented so users know what they're approving?

## Good Examples

```yaml
# Narrow auto-permissions, dangerous ops require approval
allowed-tools:
  - Glob
  - Read
  - Bash(git status:*)
  - Bash(git log --oneline:*)
  - Bash(gh pr view:*)
# git push, gh pr create intentionally omitted → user approves
```

```yaml
# Read-only skill - no Bash needed at all
allowed-tools:
  - Glob
  - Read
  - Grep
```

## Bad Examples

```yaml
# TOO BROAD - auto-allows dangerous operations
allowed-tools:
  - Bash(git:*)
  - Bash(npm:*)
```

```yaml
# UNNECESSARY - adding safe read commands that could be narrower
allowed-tools:
  - Bash(git:*)  # Should be Bash(git status:*), Bash(git log:*), etc.
```

## Shim Pattern Note

When skills use shims for guardrails, they must use hardcoded paths:

```yaml
# CORRECT - hardcoded path
~/.claude/skills/pr/gh-pr-create-web --title "..."

# WRONG - $SKILL_DIR doesn't exist as a substitution
$SKILL_DIR/gh-pr-create-web --title "..."
```

Available substitutions: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `${CLAUDE_SESSION_ID}`
