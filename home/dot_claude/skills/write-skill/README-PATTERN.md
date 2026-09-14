# README Pattern

Every skill ships a `README.md` beside its `SKILL.md`. Plain `.md` — never `.md.tmpl`, even
for a global skill. Chezmoi copies it verbatim and there is nothing in it worth templating.

## Why the split is load-bearing

|  | `SKILL.md` | `README.md` |
|---|---|---|
| Reader | the agent, at invocation | a human, browsing the directory |
| Answers | what to **do** | what it's **for** |
| Voice | imperative, terse bullets, decision trees | descriptive prose |
| Cost | counts against the compaction budget | zero — never loaded |

Claude Code loads only the `SKILL.md` body when a skill activates. Supplementary docs are read
on demand by the agent; `README.md` is read by neither. That is exactly what makes it the right
home for the material that would otherwise bloat the body — rationale, workflow placement,
worked examples, attribution.

So a README is not a summary of the skill file. When a section would read the same in both,
it belongs in one: mechanics in `SKILL.md`, motivation in `README.md`.

## Shape

````markdown
# `/<name>` — <Tagline in Title Case>

<One or two sentences. What it does, indicative mood.>

```
/<name>
/<name> <a second invocation, differently shaped>
/<name> <a third>
```

## Why this exists

<The failure mode. What goes wrong without this skill, concretely, then how the skill
forecloses it.>

## <optional sections — see below>
````

The title line, the opening sentences, and the invocation block are not optional. Everything
after "Why this exists" is chosen per skill.

### Why this exists

The heart of the convention, and the section most likely to be written badly. It argues from a
concrete failure, not from features. `/commit` opens on batched end-of-session commits with
unreviewable diffs; `/checkout` on stale bases and untracked branch names; `/think` on an agent
agreeing with a confident-sounding framing. Bold lead-ins carry a list of distinct failures well.

If the honest answer is "it saves typing," write that in one line rather than inflating it.

### Optional sections

| Section | Use when |
|---|---|
| `## How it works` | The skill runs phases, tiers, or a pipeline worth naming |
| `## How to use it` | Argument forms behave differently enough to warrant examples |
| `## Arguments` | A table maps inputs to behavior more clearly than prose |
| `## What it produces` / `## What it does NOT produce` | Scope boundaries are the surprising part |
| ``## In the [`/work-on`](../work-on/README.md) workflow`` | The skill is a link in that chain — say which phase and why there |
| `## Standalone usage` | The skill is also useful outside the chain |
| `## Files` | Three or more supplementary docs need an index |
| `## Attribution` / `## License` | Content is adapted from third-party material |

Aim for 30–60 lines. Past that, the overflow is usually a supplementary doc.

## Cross-references

Refer to the skill itself in plain backticks — `/reflect`, not a link to its own README. Link
*other* skills relatively: `` [`/work-on`](../work-on/README.md) ``. This keeps the
directory navigable from any entry point without a README linking to itself.

## Checklist

- [ ] `README.md`, plain — no `.tmpl`
- [ ] Title is `` `/<name>` `` plus a tagline
- [ ] Invocation block shows varied argument shapes, not one canonical call
- [ ] "Why this exists" names a concrete failure
- [ ] No section duplicates `SKILL.md`
- [ ] Self-references are backticks; other skills are relative links
