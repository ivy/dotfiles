# Model Selection for Subagents

Use the `model:` frontmatter field to right-size capability and cost.

## Quick Guide

| Model | Cost | Use when... |
|-------|------|-------------|
| haiku | $ | Fast exploration, simple queries, mechanical tasks |
| sonnet | $$ | Standard coding, analysis, moderate reasoning |
| opus | $$$ | Complex analysis, nuanced decisions, architectural reasoning |
| inherit | varies | Match parent conversation (default) |

**Default strategy:** Use `inherit` unless you have a specific reason to override.

## Decision Tree

```
Is the task mechanical with clear rules?
├─ Yes → haiku
│   Examples: file search, pattern matching, simple queries
│
└─ No → Does it require code understanding and judgment?
        ├─ No → haiku
        │
        └─ Yes → Does it require architectural decisions or nuanced judgment?
                ├─ No → sonnet
                │   Examples: code review, debugging, test generation
                │
                └─ Yes → opus (or inherit if parent uses opus)
                    Examples: refactoring plans, security review, complex debugging
```

## Subagent-Specific Considerations

Unlike skills, subagents often handle longer-running tasks that accumulate context. Consider:

- **Background subagents**: Haiku is often sufficient since they run unattended
- **Exploration**: Haiku handles codebase search well (the built-in Explore agent uses it)
- **Analysis**: Sonnet balances capability and cost for most review tasks
- **Planning**: Consider `inherit` to match the planning complexity of the parent

## Examples by Model

### haiku

```yaml
# Codebase explorer - fast file discovery
model: haiku
```

```yaml
# Log analyzer - pattern matching
model: haiku
```

### sonnet

```yaml
# Code reviewer - needs to understand patterns
model: sonnet
```

```yaml
# Test generator - needs code comprehension
model: sonnet
```

### opus

```yaml
# Security reviewer - nuanced vulnerability detection
model: opus
```

```yaml
# Architecture advisor - system-level reasoning
model: opus
```

### inherit

```yaml
# General assistant - match parent capability
model: inherit  # or omit (inherit is default)
```

## When to Override Parent

Override from `inherit` when:

- **Downgrade to haiku**: Task is simpler than parent conversation needs
- **Upgrade to opus**: Task requires more capability than parent provides
- **Force consistency**: Always use same model regardless of parent

Most subagents should use `inherit` or `haiku`. Explicit opus is rare.

## Bedrock Portability

Global subagents use the `bedrock-model` chezmoi template partial so they work on both direct API and AWS Bedrock:

**Global subagent** (`.md.tmpl`): `model: {{ template "bedrock-model" (dict "tier" "opus" "root" .) }}`
**Local subagent** (plain `.md`): `model: opus` or omit to inherit

The template reads `[data.claude] use_bedrock` from chezmoi config (set during `chezmoi init`). When false, it passes through the friendly name (`opus`). When true, it calls `bin/resolve-bedrock-models` to look up the latest Bedrock inference profile ID.

Chezmoi's `output` function caches the resolver — one AWS API call per `chezmoi apply`, shared across all templates.

## Cost Impact

Subagents may run for many turns accumulating context. A subagent at opus that runs 50 turns costs significantly more than one at haiku.

For background/long-running subagents, prefer haiku unless task quality suffers.
