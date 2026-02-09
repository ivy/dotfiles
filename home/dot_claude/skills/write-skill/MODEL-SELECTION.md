# Model Selection for Skills

Use the `model:` frontmatter field to right-size capability and cost.

## Quick Guide

| Model | Cost | Use when... |
|-------|------|-------------|
| haiku | $ | Mechanical, template-filling, no judgment calls |
| sonnet | $$ | Standard coding, writing, moderate reasoning |
| opus | $$$ | Complex analysis, nuanced decisions, architectural reasoning |

**Default strategy:** Start with haiku. Upgrade if the skill fails on edge cases or requires judgment.

## Decision Tree

```
Is the task mechanical with clear rules?
├─ Yes → haiku
│   Examples: copy to clipboard, format output, run single command
│
└─ No → Does it require reading code and making inferences?
        ├─ No → haiku (probably)
        │
        └─ Yes → Does it require architectural decisions or nuanced judgment?
                ├─ No → sonnet
                │   Examples: PR creation, code formatting, test generation
                │
                └─ Yes → opus
                    Examples: code review, refactoring plans, debugging complex issues
```

## Examples by Model

### haiku

```yaml
# /copy - just pipes to pbcopy
model: haiku
```

```yaml
# /format-json - mechanical transformation
model: haiku
```

### sonnet

```yaml
# /pr - reads commits, drafts PR body, adapts to templates
model: sonnet
```

```yaml
# /gfm - writes markdown following conventions
model: sonnet
```

### opus

```yaml
# /review - evaluates code quality, suggests improvements
model: opus
```

```yaml
# /debug - traces through code to find root cause
model: opus
```

## When to Upgrade

Upgrade from haiku → sonnet when:
- Skill needs to understand context, not just transform it
- Output quality varies based on input complexity
- Skill makes decisions beyond pattern matching

Upgrade from sonnet → opus when:
- Skill evaluates trade-offs or makes recommendations
- Output requires understanding system architecture
- Skill handles ambiguous or incomplete requirements

## Bedrock Portability

Global skills use the `bedrock-model` chezmoi template partial so they work on both direct API and AWS Bedrock:

**Global skill** (`.md.tmpl`): `{{- template "bedrock-model" (dict "tier" "opus" "root" .) }}`
**Local skill** (plain `.md`): omit `model:` to inherit session default

The template reads `[data.claude] use_bedrock` from chezmoi config (set during `chezmoi init` or via `USE_BEDROCK` env var). When false, it emits friendly names (`model: opus`). When true, it calls `bin/resolve-bedrock-models` to query AWS Bedrock for the latest cross-region inference profile IDs (`model: us.anthropic.claude-opus-4-6-v1`), avoiding the billing header leak.

## Cost Consideration

Model selection affects every invocation. A skill used 100x/day at opus costs significantly more than at haiku. Match capability to need.
