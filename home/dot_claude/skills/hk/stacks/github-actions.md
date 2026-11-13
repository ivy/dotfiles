# GitHub Actions Stack

Linting for GitHub Actions workflows, composite actions and Dependabot configuration, with every action locked to a commit in `.github/workflows/actions.lock`.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `.github/workflows/*.yml` | High |
| `.github/actions/**/action.yml` | High |
| `action.yml` or `action.yaml` at the root | High (extend the glob, see Gotchas) |
| `.github/dependabot.yml` | High |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| jactionlint | `Builtins.jactionlint` | Lints workflows, composite actions and `dependabot.yml` ([jdx/jactionlint](https://github.com/jdx/jactionlint)): syntax, expressions, shellcheck on `run:` scripts, security and policy rules. Has a fix. |

## Tool Install Commands

```bash
mise use aqua:jdx/jactionlint@X.Y.Z
mise use aqua:koalaman/shellcheck@X.Y.Z   # jactionlint runs it on every run: script
```

Lock the actions the workflows use (the [gh-actions-lock](https://github.com/github/gh-actions-lock) extension):

```bash
gh actions-lock                 # writes .github/workflows/actions.lock, rewrites uses: to exact tags
gh actions-lock --verify        # what CI runs
```

## Gotchas

- **hk package version**: `Builtins.jactionlint` exists from hk 2.6.0 (check only) and has its fix from 2.7.0. On an older `hk.pkl` package, write an inline step instead: `["jactionlint"] { glob = List(".github/workflows/*.y*ml"); check = "jactionlint --format gcc {{files}}"; fix = "jactionlint --fix {{files}}" }`.
- **shellcheck must be pinned**: jactionlint shells out to `shellcheck`, and a mise shim with no version behind it is a fatal error rather than a skipped check. Pin shellcheck in the project's `mise.toml` even when the shell stack is not included.
- **Lock, don't SHA-pin**: with `actions.lock` present, jactionlint's `unpinned-uses` rule accepts the exact tags the lockfile pins, so workflows keep readable `uses: actions/checkout@v7.0.1` refs. Run `gh actions-lock` after every change to a `uses:` line, and add a CI job that runs `gh actions-lock --verify` so a stale lockfile fails. Renovate's `github-actions` manager regenerates the lockfile with each update.
- **Root `action.yml` is not in the builtin's glob**: it covers `.github/workflows/`, `.github/actions/**/action.y*ml` and `.github/dependabot.y*ml`. A repository that publishes an action at its root extends it: `(Builtins.jactionlint) { glob = List(".github/workflows/*.y*ml", ".github/actions/**/action.y*ml", ".github/dependabot.y*ml", "action.y*ml") }`.
- **The default profile blocks commits on existing workflows**: it reports missing `timeout-minutes`, `concurrency:` and `permissions:`, `cache-poisoning`, Dependabot cooldowns and more, so a first run on an existing repository usually fails. Fix the findings as part of the bootstrap. `jactionlint --explain <rule>` gives the reasoning and the fix of each rule.
- **Suppress narrowly, with a reason**: for a genuine false positive, or a fix that would change behaviour (a deploy workflow must not cancel in progress), add a durable `ignores:` entry with `rule`, `file` and `reason` to `.github/jactionlint.yaml` ([config reference](https://jactionlint.jdx.dev/config)). Do not turn rules off globally.
- **Overlap with yaml linters**: If you also include yamlfmt/yamllint, exclude `.github/` from them to avoid double-linting workflow files.

## Example Pkl Snippet

```pkl
// Always include if .github/workflows/ exists
["jactionlint"] = Builtins.jactionlint
```
