# Documentation Skill (Diátaxis Framework)

A Claude Code skill for writing user-centered documentation using the Diátaxis framework.

## Usage

```bash
/doc                                    # Document current discussion topic
/doc feature-x --type tutorial          # Write a tutorial
/doc api.ts --type reference            # Write API reference
/doc "connection pooling" --type explanation  # Explain a concept
/doc docs/ --audit                      # Audit existing docs against Diátaxis
```

## Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with decision matrix |
| `TUTORIAL.md` | Guide for learning-oriented documentation |
| `HOWTO.md` | Guide for goal-oriented documentation |
| `REFERENCE.md` | Guide for information-oriented documentation |
| `EXPLANATION.md` | Guide for understanding-oriented documentation |
| `COMPASS.md` | Decision tool for determining doc type |
| `QUALITY.md` | Functional vs deep quality concepts |
| `WORKFLOW.md` | Iterative improvement process |

## Attribution

This skill is based on the [Diátaxis documentation framework](https://diataxis.fr) by **Daniele Procida**.

The content in this skill has been adapted and reorganized for use as a Claude Code skill. The original framework provides a systematic approach to technical documentation authoring, identifying four distinct documentation types based on user needs.

## License

This adaptation is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

**Original work:** [Diátaxis documentation framework](https://diataxis.fr) © Daniele Procida, licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

**Modifications:** Content has been reorganized, condensed, and formatted as a Claude Code skill with separate files for each documentation type, decision matrices, and practical checklists.
