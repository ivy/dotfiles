# Hooks for Subagents

Subagents can define lifecycle hooks that run during execution. Hooks provide conditional control beyond simple tool restrictions.

## When to Use Hooks

Consider hooks when:
- You need to validate tool inputs (e.g., only allow SELECT queries)
- You want to transform arguments before passing to commands
- A flag must always be present
- You need logging or auditing of subagent operations

Most subagents don't need hooks. Start with `tools`/`disallowedTools`, add hooks only when needed.

## Hook Events for Subagents

| Event | Matcher | When it fires |
|-------|---------|---------------|
| `PreToolUse` | Tool name | Before subagent uses a tool |
| `PostToolUse` | Tool name | After subagent uses a tool |
| `Stop` | (none) | When subagent finishes |

## Syntax

Hooks are defined in frontmatter:

```yaml
---
name: db-reader
description: Execute read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

## Example: SQL Write Blocker

This hook allows Bash but blocks SQL write operations:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
```

The validation script:

```bash
#!/bin/bash
# ./scripts/validate-readonly-query.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block write operations (case-insensitive)
if echo "$COMMAND" | grep -iE '\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE)\b' > /dev/null; then
  echo "Blocked: Only SELECT queries are allowed" >&2
  exit 2  # Exit code 2 blocks the operation
fi

exit 0
```

## Exit Codes

| Code | Behavior |
|------|----------|
| 0 | Allow operation |
| 2 | Block operation (message sent to Claude) |
| Other | Error (typically allows operation) |

## Hook Input Format

Hooks receive JSON via stdin:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "psql -c 'SELECT * FROM users'"
  }
}
```

## Alternatives to Hooks

Before adding hooks, consider:

1. **Narrow tool list**: Remove Bash entirely if not needed
2. **Use `disallowedTools`**: Deny specific tools
3. **Trust the system prompt**: Clear instructions often suffice
4. **Use shims**: Wrapper scripts that enforce flags (see SHIM-PATTERN.md in write-skill)

Hooks add complexity. Use only when simpler approaches don't work.

## Project-Level Hooks

You can also define hooks in `settings.json` that respond to subagent lifecycle:

| Event | Matcher | When it fires |
|-------|---------|---------------|
| `SubagentStart` | Agent name | When a specific subagent begins |
| `SubagentStop` | (none) | When any subagent completes |

Example in settings.json:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "db-reader",
        "hooks": [
          { "type": "command", "command": "./scripts/setup-db.sh" }
        ]
      }
    ]
  }
}
```
