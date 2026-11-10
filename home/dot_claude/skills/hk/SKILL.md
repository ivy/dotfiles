---
name: hk
description: "Use when bootstrapping hk pre-commit hooks for a project."
argument-hint: "[stacks... | --check | --update]"
allowed-tools:
  - Glob
  - Grep
  - Read
  - Bash(command -v:*)
  - Bash(git config --get:*)
  - Bash(git log --oneline:*)
  - Bash(git rev-parse:*)
  - Bash(hk --version:*)
  - Bash(hk check:*)
  - Bash(hk validate:*)
  - Bash(mise --version:*)
  - Bash(mise ls-remote:*)
  - Bash(mise registry:*)
  - Bash(mise which:*)
  - Bash(test -d:*)
  - Bash(test -f:*)
---

# hk — Pre-commit Hook Bootstrap

**Autonomy:** model-invocable · plan approval authorizes the rest — install tools, write config, install hooks, commit — without re-asking · every effect is local to the target repo; never pushes

## Arguments
```
$ARGUMENTS
```

## Pre-computed Context

```
Git repo root: !`git rev-parse --show-toplevel 2>/dev/null || echo "NOT A GIT REPO"`
hk.pkl exists: !`test -f hk.pkl && echo "yes" || echo "no"`
Hooks path: !`git config --get core.hooksPath 2>/dev/null || echo "not set (.git/hooks)"`
hk available: !`command -v hk 2>/dev/null && hk --version 2>/dev/null || echo "not installed"`
mise available: !`command -v mise 2>/dev/null && mise --version 2>/dev/null || echo "not installed"`
Conventional commits: !`git log --oneline -10 2>/dev/null || echo "no git history"`
```

## Constraints

- **Always call `EnterPlanMode` before making any changes.** This skill is plan-first — detection and analysis happen before any writes.
- Never use `git -C <path>` — it rewrites the command prefix, so the command no longer matches the read-only `allowed-tools` patterns.
- If hk is not installed (pre-computed context shows "not installed"), the plan MUST include `mise use hk` as the first install step.
- **Find out how git hooks reach hk before installing any.** When `core.hooksPath` is set (pre-computed context), git reads its hooks from that directory, not from `.git/hooks`. Read the scripts there. An event whose script runs `hk run <event>` is already wired for every repository: a repo-level `hk.pkl` is all the project needs, and the steps of the user's own hk config (`config.pkl` in `HK_CONFIG_DIR`) keep running beside the project's. Do not run `hk install` in that case (step 8), and compose hooks only for the events whose scripts call hk. A `pre-push` or `commit-msg` hook in `hk.pkl` does nothing where no script dispatches it.
- **Where hk does install the hooks, use `--mise` flags**: `hk init --mise` (scaffolds mise.toml with hk task) and `hk install --mise` (hooks execute via `mise x` so tools are in PATH without shell activation).

## Instructions

### Parse Arguments

Determine the mode from arguments:

| Pattern | Mode |
|---------|------|
| (empty) | **Auto-detect**: scan project, detect stacks, full bootstrap |
| `--check` | **Check**: validate existing `hk.pkl`, run `hk check --all` |
| `--update` | **Update**: detect new stacks, propose additions to existing `hk.pkl` |
| `rust shell go ...` | **Force stacks**: use specified stacks, skip auto-detection |

### Mode: --check

If arguments contain `--check`:

1. Verify `hk.pkl` exists — error if not
2. Run `hk validate` to check config syntax
3. Run `hk check --all` to run all checks
4. Report results — do NOT enter plan mode
5. If failures found, suggest `hk fix --all` or `/hk --update`

### Mode: Auto-detect / Force / Update

#### 1. Immediately Enter Plan Mode

Call `EnterPlanMode` now. All remaining work happens in plan mode.

#### 2. Detect Stacks

Probe for indicator files to determine which stacks apply:

| Indicator | Stack | Stack File |
|-----------|-------|------------|
| *(always)* | essential | `stacks/essential.md` |
| `*.sh`, `*.bash`, `bin/` with scripts | shell | `stacks/shell.md` |
| `.github/workflows/*.yml` | github-actions | `stacks/github-actions.md` |
| `Cargo.toml` | rust | `stacks/rust.md` |
| `go.mod` | go | `stacks/go.md` |
| `Package.swift`, `*.xcodeproj`, `*.swift` | swift | `stacks/swift.md` |
| `Dockerfile*`, `Containerfile*`, `docker-compose.yml`, `compose.yml` | docker | `stacks/docker.md` |
| `*.pkl`, `PklProject`, `**/*.yml` (non-GHA) | config-languages | `stacks/config-languages.md` |
| `*.lua`, `.stylua.toml`, `init.lua` | lua | `stacks/lua.md` |

For **force stacks** mode: use only the specified stacks (plus essential always).

For **update** mode: detect stacks not already covered in existing `hk.pkl`.

#### 3. Read Stack Files

Read each detected stack's `.md` file from the `stacks/` directory (relative to this skill). Extract:
- Builtin names and `Builtins.xxx` syntax
- Tool install commands
- Gotchas and overrides
- Example pkl snippets

#### 4. Analyze Project Context

Check for additional context that affects configuration:
- Does `.editorconfig` exist? (affects editorconfig-checker, shfmt)
- Does `action.yml` exist at the root? (extend the jactionlint glob to lint it)
- Are there `.tmpl` files? (affects shell stack exclusions)
- Is this a chezmoi repo? (template exclusions needed)
- Does the project use conventional commits? (check pre-computed context git log, or look for `commitlint`, `.commitlintrc`)
- What YAML files exist outside `.github/`? (affects yaml linter inclusion)
- Are there JSONC files? (`.json` files with `//` comments — VS Code/Cursor configs). Exclude from jq.
- Are there reference/vendor directories? (`docs/reference/`, `vendor/`, large repo-to-text dumps). Exclude from content-sensitive checks (`detect-private-key`, `markdown-lint`).
- Are there other projects nested in subdirectories with their own `hk.pkl`? Add them to the global `exclude`.
- Is there generated or vendored code (protobuf or sqlc output, `third_party/`)? Exclude it from `trailing-whitespace`, `newlines` and the formatters.
- Which git hook events reach hk, and how? (see Constraints)
- Does the project's mise config already define tasks such as `check`, `fix` or `lint`? Fold hk into them or pick another name. Don't define one twice.
- Which test suites does the project have, and how long does each take? (the tests-on-commit question in step 7)

#### 5. Fetch Latest hk Version

```bash
mise ls-remote hk | tail -1
```

Use the result for the `amends` line in `hk.pkl`.

#### 6. Compose hk.pkl

Mentally compose the `hk.pkl` config following this structure:

```pkl
amends "package://github.com/jdx/hk/releases/download/vX.Y.Z/hk@X.Y.Z#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/vX.Y.Z/hk@X.Y.Z#/Builtins.pkl"

local linters = new Mapping<String, Step | Group> {
  // essential builtins
  // stack-specific builtins with overrides from gotchas
}

hooks = new {
  ["pre-commit"] {
    fix = true
    stash = "git"
    steps = linters
  }
  ["pre-push"] {
    steps = linters
  }
  ["check"] {
    steps = linters
  }
  ["fix"] {
    fix = true
    steps = linters
  }
}
```

If conventional commits detected, add:
```pkl
  ["commit-msg"] {
    steps {
      ["check-conventional-commit"] = Builtins.check_conventional_commit
    }
  }
```

Include `pre-push` and `commit-msg` only where those events reach hk (see Constraints).

**Tests on commit**, when the owner wants them (step 7), are steps like any other, kept in a mapping of their own so `fix` can leave them out:

```pkl
local tests = new Mapping<String, Step | Group> {
  ["go-test"] {
    glob = List("server/**", "proto/**")
    check = "cd server && go test ./..."
  }
}

local everything = new Mapping<String, Step | Group> {
  ...linters
  ...tests
}

hooks = new {
  ["pre-commit"] {
    fix = true
    stash = "git"
    steps = everything
  }
  ["check"] { steps = everything }
  ["fix"] { fix = true; steps = linters }
}
```

- `glob` decides which commits run a suite. List everything the suite reads, generated inputs and fixtures included, and leave out docs.
- With `stash = "git"` the hook stashes unstaged changes first, so a suite tests what is being committed, not the working tree.
- A step that works in a subdirectory changes directory in its command (`cd server && …`). A literal `dir` also scopes the step's `glob` and `exclude` to that directory, so patterns written from the repository root match nothing and the step is skipped without an error.
- `exclusive = true` keeps other steps from starting until a step finishes, for suites that would compete for a build. `depends` names steps that must finish first.

#### 7. Present Plan

Write the plan including:
1. **Detected stacks** — list each with confidence level
2. **Proposed `hk.pkl`** — full file content, including global `exclude` for nested projects
3. **Tools to install** — exact `mise use tool@VERSION` commands (resolve versions via `mise ls-remote`)
4. **Gotchas noted** — any stack-specific warnings that apply
5. **Config files needed** — `.markdownlint.json`, `.stylua.toml`, `.editorconfig`, etc.
6. **Commit strategy** — the exact sequence of commits:
   - Commit 1: config files (`hk.pkl`, `.mise.toml`, `.markdownlint.json`, `.stylua.toml`, etc.)
   - Commit 2: `hk fix --all` auto-formatted changes to tracked files
   - Commit 3: manual fixes for hook-blocking issues (e.g., jactionlint workflow hardening)
7. **Tests on commit** — where the project has test suites, ask with `AskUserQuestion` how much a commit should wait for, giving each suite's measured duration: nothing, the fast unit suites, or everything. Suites that take minutes (UI tests, end-to-end) are better left a manual task.
8. **Noise** — how many findings each linter has today, or that it wasn't measured. A linter the project doesn't pin yet can't run in plan mode: its mise shim exits 1 with `No version is set for shim`, and with stderr discarded that reads as zero findings. Call a linter clean only when it ran, and otherwise expect a formatting commit.

Call `ExitPlanMode` and wait for approval.

#### 8. After Approval — Execute

Run these steps in order:

1. **Install tools one at a time** with pinned versions:
   ```bash
   mise use hk@X.Y.Z
   mise use aqua:jdx/jactionlint@X.Y.Z
   # etc. — one tool per command to avoid partial failures
   ```
   After each install, verify it landed in the project `.mise.toml` (not global config).
   Use `mise x -- TOOL --version` if the tool isn't in PATH yet (avoids shell reload).

   If the project has no `.mise.toml` yet, run `mise x -- hk init --mise` after installing hk
   to scaffold a mise.toml with an hk pre-commit task definition.

2. **Write config files** — `hk.pkl`, `.markdownlint.json`, `.stylua.toml`, etc.

3. **Install hooks** (with mise integration), unless hooks already reach hk through a shared hooks path (see Constraints):
   ```bash
   mise x -- hk install --mise
   ```
   `hk install --help` (2.11.1) says a per-repo install on Git 2.54+ adds config-based hooks (`hook.<name>.command`), and is skipped only when the global git config has `hook.hk-*` entries, which `hk install --global` writes. A hand-written script in a global hooks directory is not such an entry. Going by that, hk wouldn't detect it and would install its own hooks beside it, so hk would run twice on an event. This has not been tried.
   The `--mise` flag makes hooks execute via `mise x`, so all mise-managed tools are
   automatically in PATH — other developers don't need mise activated in their shell.

4. **Validate config**:
   ```bash
   mise x -- hk validate
   ```

5. **Run checks**:
   ```bash
   mise x -- hk check --all
   ```

6. **If check failures**, fix:
   ```bash
   mise x -- hk fix --all
   ```
   Then re-run `hk check --all` to verify. `hk check --all --skip-step NAME` leaves a slow suite out while the linters are being settled.

7. **Verify what a passing check can't show**:
   - For one file of each kind the project has, `mise x -- hk check --plan -g PATH` lists the steps that would run. A step that should run and shows `no files matched filters` has a `glob` or `dir` that doesn't reach the file.
   - Read the diff `hk fix` made. `check` and `fix` read the same configuration, so a formatter set up wrongly still passes its own check.
   - Where the hook runs tests, see it refuse a commit: stage a deliberately failing test, try to commit, and confirm the commit fails and `HEAD` hasn't moved. Then unstage and restore the file.
   - Before adding tasks to the project's mise config, list the ones it has (`mise tasks`). A second task of the same name is a duplicate TOML key, and with an invalid config mise and its shims stop working in that directory until it's fixed.

8. **Commit in sequence** (per the plan's commit strategy):
   - Commit 1: config files only
   - Commit 2: auto-formatted changes from `hk fix`
   - Commit 3: manual fixes (e.g., jactionlint workflow hardening) if needed

9. **Report results** — summarize what was installed, configured, and any remaining issues.
