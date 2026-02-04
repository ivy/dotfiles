# Subagent Review Checklist

Use this checklist when reviewing subagents before deployment. Give this file to the reviewer agent.

## Understanding `tools` and `disallowedTools`

**Critical distinction:** Subagents inherit ALL tools by default. You must actively restrict them.

- `tools` field → allowlist (only these tools available)
- `disallowedTools` field → denylist (remove these from inherited set)
- Neither specified → inherits ALL tools from parent conversation

### Good Pattern: Explicit Restriction

```yaml
# Read-only code reviewer
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
```

### Bad Pattern: Unrestricted Inheritance

```yaml
# No tools field = inherits everything including Write, Edit, etc.
name: code-reviewer
description: Reviews code
# Missing tools/disallowedTools!
```

## The Cardinal Rule

**Match tool access to task requirements.** A code reviewer doesn't need Write. A debugger might need Edit but not arbitrary Bash.

## Red Flags (Reject immediately)

These patterns indicate over-permissive subagents:

| Pattern | Why it's dangerous |
|---------|-------------------|
| No `tools` or `disallowedTools` on a read-only agent | Inherits Write/Edit unnecessarily |
| `permissionMode: bypassPermissions` | Skips ALL permission checks |
| Read-only description but Write/Edit allowed | Capability exceeds stated purpose |
| `tools: *` or equivalent broad patterns | No meaningful restriction |

## Quick Decision Rules

When defining subagent tools:

1. **Is it read-only?** → Use `tools: Read, Glob, Grep` or add `disallowedTools: Write, Edit`
2. **Does it need Bash?** → Consider `disallowedTools` for dangerous commands, or use hooks
3. **Does it modify files?** → Explicitly document why Write/Edit is needed
4. **Does it run in background?** → Ensure it doesn't need interactive prompts
5. **Does it fetch external content?** → Consider prompt injection risks

## Permission Modes

| Mode | Behavior | When to use |
|------|----------|-------------|
| `default` | Standard prompts | Most subagents |
| `acceptEdits` | Auto-accept Write/Edit | Trusted modification tasks |
| `dontAsk` | Auto-deny prompts | Read-only exploration |
| `bypassPermissions` | Skip all checks | **NEVER** (except parent override) |
| `plan` | Read-only planning | Research and analysis |

**Warning:** `bypassPermissions` should almost never be used in custom subagents.

## Safe Patterns by Task Type

### Code Reviewer (read-only)

```yaml
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
permissionMode: dontAsk
```

### Debugger (needs modification)

```yaml
tools: Read, Edit, Bash, Grep, Glob
# Write intentionally included for creating test files
permissionMode: default  # Prompt for destructive operations
```

### Data Analyst (specific commands)

```yaml
tools: Bash, Read, Write
# Plus PreToolUse hook to validate Bash commands
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-query.sh"
```

## System Prompt Review

Check that the body (system prompt):

1. **Defines role clearly** - "You are a..." statement
2. **Specifies activation** - "When invoked..." or similar
3. **Lists concrete steps** - Numbered workflow or checklist
4. **Stays focused** - Under 50 lines, single purpose
5. **Matches tools** - Doesn't instruct operations beyond tool access

## Review Process

1. **Check tool configuration** - Are tools appropriately restricted?
2. **Verify permission mode** - Does it match task sensitivity?
3. **Review system prompt** - Is it focused and clear?
4. **Check description** - Does it help Claude decide when to delegate?
5. **Validate hooks** - If present, are they correctly structured?
6. **Test mental models** - Apply "Unattended Machine" and "Intern with Root" tests

## Mental Models

### The "Unattended Machine" Test

> Would you be comfortable if this subagent ran while you were away?

If not, add `disallowedTools` or change `permissionMode` to `default`.

### The "Intern with Root" Test

> Would you give an unsupervised intern these capabilities?

Captures both skill level AND trust level required.

### The "Capability Match" Test

> Does the tool access match what the description says it does?

A "read-only reviewer" shouldn't have Write access.
