# GitHub Actions Stack

Linting for GitHub Actions workflows and action definitions.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `.github/workflows/*.yml` | High |
| `action.yml` or `action.yaml` | High (for ghalint_action) |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| ghalint-workflow | `Builtins.ghalint_workflow` | Lints GHA workflow files (pinned actions, timeout-minutes, etc.) |
| ghalint-action | `Builtins.ghalint_action` | Lints GHA action definition files |

## Tool Install Commands

```bash
mise use ghalint
```

## Gotchas

- **Both builtins are `const`**: They cannot be overridden with `(Builtins.ghalint_workflow) { ... }`. Use them as-is or write a custom step instead.
- **ghalint_workflow runs without `{{files}}`**: The check command is `ghalint run` (no file arguments). It scans `.github/workflows/*` via its own glob. This means it always checks all workflows, not just staged files.
- **ghalint blocks commits on pre-existing issues**: Since `ghalint run` checks ALL workflow files (not just staged ones), pre-existing violations (missing `timeout-minutes`, missing job-level `permissions`, unpinned actions) will block every commit. Either: (a) fix all workflow issues as part of the bootstrap, or (b) write a custom step with a `slow` profile so it doesn't block commits by default.
- **ghalint_action**: Only include if the project has an `action.yml` or `action.yaml` in the root. Its glob is `List("**/action.*")` with `types = List("yaml")`.
- **Overlap with yaml linters**: If you also include yamlfmt/yamllint, exclude `.github/workflows/` from them to avoid double-linting GHA workflow files. ghalint is more specific and useful for workflows.

## Example Pkl Snippet

```pkl
// Always include if .github/workflows/ exists
["ghalint-workflow"] = Builtins.ghalint_workflow

// Only include if action.yml exists in project root
["ghalint-action"] = Builtins.ghalint_action
```
