# Skill Review Checklist

Use this checklist when reviewing skills before deployment. Give this file to the reviewer agent.

## The Cardinal Rule

**If you can't undo it locally, don't auto-allow it.**

## Red Flags (Reject immediately)

These patterns in `allowed-tools` permit dangerous operations:

| Pattern | Why it's dangerous |
|---------|-------------------|
| `Bash(git:*)` | Permits push, reset --hard, clean -f, force push |
| `Bash(npm:*)` | Permits publish, global install, token access |
| `Bash(docker:*)` | Permits push, login, system prune |
| `Bash(gh:*)` | Permits create, merge, delete, release |
| `Bash(curl:*)` | Permits POST, DELETE, data exfiltration |
| `Bash(rm -rf:*)` | Unrestricted recursive deletion |
| Any `--force` without justification | Bypasses safety checks |

## Quick Decision Rules

Before allowing a command, ask:

1. **Can it publish externally?** (push, deploy, create) → DENY
2. **Can it delete data?** (rm, clean, reset --hard) → DENY
3. **Can it expose secrets?** (cat sensitive, env vars) → DENY
4. **Does it affect global state?** (install -g, system config) → DENY
5. **Is it read-only?** (status, log, diff, view, list) → ALLOW
6. **Is it local and reversible?** (add, build) → CONDITIONAL

## Safe vs Unsafe by Tool

### Git

```yaml
# SAFE - read-only, local inspection
- Bash(git status:*)
- Bash(git log:*)
- Bash(git diff:*)
- Bash(git branch --list:*)
- Bash(git show:*)
- Bash(git blame:*)

# CONDITIONAL - local staging (reversible)
- Bash(git add:*)

# NEVER - requires user approval
- Bash(git push:*)        # external publication
- Bash(git reset --hard:*) # data loss
- Bash(git clean:*)        # data loss
- Bash(git checkout .:*)   # data loss
```

### npm/yarn/pnpm

```yaml
# SAFE - read-only
- Bash(npm view:*)
- Bash(npm ls:*)
- Bash(npm audit:*)

# CONDITIONAL - local project
- Bash(npm test:*)
- Bash(npm run lint:*)

# NEVER
- Bash(npm publish:*)     # external publication
- Bash(npm install -g:*)  # system-wide
```

### GitHub CLI

```yaml
# SAFE - read-only
- Bash(gh pr view:*)
- Bash(gh pr list:*)
- Bash(gh issue view:*)

# NEVER
- Bash(gh pr create:*)    # external publication
- Bash(gh pr merge:*)     # modifies remote
- Bash(gh release create:*) # external publication
```

### Docker

```yaml
# SAFE - inspection
- Bash(docker ps:*)
- Bash(docker images:*)
- Bash(docker logs:*)

# CONDITIONAL
- Bash(docker build:*)

# NEVER
- Bash(docker push:*)     # external publication
- Bash(docker login:*)    # credential handling
```

## Mental Models

### The "Unattended Machine" Test

> Would you be comfortable if this skill ran while you were away?

If you'd want to review what happened, those operations need approval.

### The "Intern with Root" Test

> Would you give an unsupervised intern permission to run this automatically?

Captures both skill level AND trust level required.

## Review Process

1. **Check `allowed-tools`** against red flags above
2. **Apply narrowing principle**: Is the most specific pattern used?
3. **Verify shims use hardcoded paths** (not `$SKILL_DIR` - that doesn't exist)
4. **Check for publication risks**: Any command that sends data externally?
5. **Check for deletion risks**: Any command that removes data?

## Good Examples

```yaml
# Narrow, specific permissions
allowed-tools:
  - Bash(git status:*)
  - Bash(git log --oneline:*)
  - Bash(gh pr view:*)
  - Read
  - Glob
```

## Bad Examples

```yaml
# TOO BROAD - reject this
allowed-tools:
  - Bash(git:*)
  - Bash(npm:*)
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
