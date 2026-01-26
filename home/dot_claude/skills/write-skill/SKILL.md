---
name: write-skill
description: Use when the user wants to create a new Claude Code skill. Guides skill creation with playbook patterns.
argument-hint: "[skill-name] [purpose...]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Bash(chezmoi apply:*), Bash(chezmoi diff:*), Bash(chezmoi status:*)
---

# Skill Creation Playbook

Create skills as flexible playbooks, not rigid scripts.

## Arguments

```
$ARGUMENTS
```

## Process

### 0. No Arguments? Extract from Conversation

If arguments are empty, the user wants to codify the task just performed:

1. Analyze the conversation for the repeatable pattern
2. Identify: trigger conditions, tools used, decision points, inputs/outputs
3. Propose a skill name and description based on what was done
4. Draft the skill capturing the workflow as a playbook
5. Ask user to confirm or refine before writing

### 1. Gather Context (when args provided)

If unclear, ask:
- Trigger? (user/auto/always)
- Tools needed?
- Fork context? (noisy output)
- Side effects? (commits/deploys/APIs)

### 2. Draft Skill

Create `$(chezmoi source-path)/dot_claude/skills/<name>/SKILL.md`:

```yaml
---
name: <kebab-case>
description: <When to use + what it does>
argument-hint: <flexible, use brackets>
disable-model-invocation: <true if user-only>
context: <fork if output not needed>
allowed-tools: <minimal safe subset>
---

# <Title>

## Arguments
\`\`\`
\$ARGUMENTS
\`\`\`

## Instructions
<Decision-tree playbook>

## Examples
<Varied inputs and outcomes>
```

After writing: `chezmoi diff` to preview, `chezmoi apply ~/.claude/skills/<name>` to deploy, `chezmoi status` to verify.

### 3. Principles

**Frontmatter:**
- `description`: "Use when..." for auto-invoke
- `context: fork`: noisy output that won't inform follow-up
- `disable-model-invocation: true`: side-effect skills
- `allowed-tools`: narrow scope—`Bash(git mob:*)` not `Bash(git:*)`

**Arguments:**
- Free-form: `[package | url...]` not `<package>`
- Show varied inputs in examples
- Parse flexibly, not strictly

**Content:**
- Decision trees, not linear scripts
- <60 lines; externalize reference material
- Refer to "arguments" after the Arguments section
- `\${CLAUDE_SESSION_ID}` for session-specific context

### 4. Review

Ask reviewer agent to audit for verbosity, tool scope, edge cases, invocation clarity.

## Quick Reference

| Goal | Frontmatter |
|------|-------------|
| User-only trigger | `disable-model-invocation: true` |
| Auto-invoke | `description` with "Use when..." |
| Hidden from `/` menu | `user-invocable: false` |
| Isolate context | `context: fork` |
| Specific agent | `context: fork` + `agent: Explore` |

| Safe | Unsafe |
|------|--------|
| `Bash(git status:*)` | `Bash(git:*)` |
| `Bash(npm test:*)` | `Bash(npm:*)` |
| `Read, Grep, Glob` | `Bash(rm:*)` |

## Examples

```
/write-skill                     → extract skill from current conversation
/write-skill deploy              → guided creation for "deploy" skill
/write-skill search with rg      → skill wrapping ripgrep
```

## Anti-patterns

- Strict positional arguments
- Broad tool access
- Verbose prose over terse bullets
- Missing `context: fork` for noisy ops
- Hardcoded paths vs arguments
