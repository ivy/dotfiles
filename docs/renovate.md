# Renovate: How This Repo Manages Versions

This guide explains how Renovate is configured in this repository, how the custom version manifests work, and when/how to add or update pinned versions. It also includes handy `gh`/`gh api` commands to look up latest tags and resolve commit SHAs.

## TL;DR

- Renovate config lives at `renovate.json5` and opens `type:chore` PRs that squash-automerge once checks pass.
- We pin everything important to immutable versions or digests for reproducibility and supply‑chain safety.
- Updates are batched into one PR per ecosystem — GitHub Actions, container images, mise tools, Neovim plugins, tmux plugins, chezmoi externals — so a week of upstream releases lands as a handful of PRs, not thirty.
- Major version bumps are excluded from the batches and get their own PR, so one breaking change can't block a batch of safe ones.
- Version updates to tools and Actions are held three days before they are raised, so a compromised release has a window to be caught. Branch-tip dependencies can't be held that way and land in a weekly batch instead — see [Quarantine](#quarantine).

---

## Configuration Overview

File: `renovate.json5`

- Extends: `config:recommended`, `:semanticCommits`, `:disableDependencyDashboard`
- Timezone: `America/Los_Angeles`
- Labels: `type:chore`
- Automerge: on, squash strategy
- PR limits: `prHourlyLimit: 10`
- `rebaseWhen: "conflicted"` — see [Batching and rebase churn](#batching-and-rebase-churn)
- `minimumReleaseAge: "3 days"` on timestamped datasources; branch-tip deps run on a weekly `schedule` instead — see [Quarantine](#quarantine)

Enabled managers and file discovery:

- `mise`: `home/dot_config/mise/config.toml`, plus `mise.lock` via `lockFileMaintenance`
- `dockerfile`: `Containerfile`
- `docker-compose`: `home/dot_config/docker-compose/*.y[a]ml`
- `github-actions`: `.github/workflows/*.y[a]ml` (with digest pinning)
- `jsonata`: `home/.chezmoidata/tmux-plugins.yaml`

Everything else — npm, pip, bundler and friends — is off via `enabledManagers`.

---

## Batching and rebase churn

One PR per dependency does not scale here. Between ~30 SHA-pinned Neovim plugins, tmux plugins, chezmoi externals, digest-pinned Actions and container images, a quiet week upstream still produces a double-digit pile of PRs — and each merge rebases every branch behind it.

Two `packageRules` levers keep that in check.

**Grouping.** Semver managers group by manager name; custom managers group by the manifest their versions live in, because each plugin has its own regex manager and there is no shared manager name to match:

| Group | Matched by | Covers |
|-------|-----------|--------|
| `github actions` | `matchManagers: ["github-actions"]` | workflow action versions and digests |
| `container images` | `matchManagers: ["dockerfile", "docker-compose"]` | `Containerfile` and compose image tags/digests |
| `mise tools` | `matchManagers: ["mise"]` | every pinned tool in the mise manifest |
| `neovim plugins` | `matchFileNames: ["home/dot_config/nvim/lazy-lock.json"]` | lazy.nvim lockfile commits |
| `tmux plugins` | `matchFileNames: ["home/.chezmoidata/tmux-plugins.yaml"]` | tmux plugin commits |
| `chezmoi externals` | `matchFileNames: ["home/.chezmoiexternal.toml.tmpl"]` | oh-my-zsh, zsh plugins, ghostty theme |

The semver groups carry `matchUpdateTypes: ["minor", "patch", "digest", "pin", "pinDigest"]`. Major updates fall through to the default and get an individual PR, which is the point: a major bump usually needs a config change alongside it, and batching it would strand the safe updates behind that work. The three `matchFileNames` groups track branch tips through `git-refs`, so every update there is a digest update and no update-type filter is needed.

**Rebasing.** `config:recommended` leaves `rebaseWhen` at `"auto"`, which resolves to `behind-base-branch` whenever `automerge` is enabled — so every push to `main` rebases every open Renovate branch. `main` carries no up-to-date-branch requirement, so automerge does not need that; `rebaseWhen: "conflicted"` restricts rebases to branches that genuinely conflict.

---

## Quarantine

A fresh release is the riskiest one. `minimumReleaseAge: "3 days"` holds an update until its release is three days old, which is long enough for scanners and researchers to flag a compromised publish and covers the window in which a registry can unpublish a version out from under an already-merged bump. Renovate's own `security:minimumReleaseAge*` presets use the same three days for the same reasons.

The rule is keyed on **datasource**, not manager, because the binding constraint is whether a `releaseTimestamp` comes back at all. `minimumReleaseAgeBehaviour` defaults to `timestamp-required`, so an update with no timestamp is treated as pending — and a dependency that can never produce one is held not for three days but forever. Two classes can never produce one:

| Class | Why no timestamp | Treatment |
|---|---|---|
| Branch-tip deps (`git-refs`) | No release exists to age against — the ref is a moving branch | Weekly `schedule`, below |
| Non-Docker-Hub images | Renovate reads publish time from Docker Hub's `tag_last_pushed`; GHCR, Quay and other registries expose no equivalent | Left unquarantined |

So the quarantine covers GitHub Actions, every mise tool, and `cli-versions.toml`. It does not cover the ~41 branch-tip dependencies or any container image.

**Only version updates are held.** The rule carries `matchUpdateTypes: ["major", "minor", "patch"]`, and that filter is load-bearing rather than cosmetic. Renovate checks release age twice: once while looking up the update, and again at branch level against a `releaseTimestamp` field that only version updates carry. A digest update passes the first check and fails the second, leaving a PR open behind a stability check that never clears. One consequence worth knowing: an Action pinned to a moving tag rather than a version — `anthropics/claude-code-action@<sha> # beta`, for instance — produces digest updates, so its bumps are not held.

**The hold is not proof against tag mutation.** For `github-tags` deps, age is measured from the tag's `committedDate`, not from when the tag was pushed. A tag force-pushed onto an old commit satisfies the window immediately. `github-releases` deps carry real publish metadata and don't have this gap.

### Weekly window for branch tips

Branch-tip dependencies get `schedule: ["before 6am on monday"]` instead, with automerge left on. A week of upstream commits collects into one batch per group and lands predictably.

> [!IMPORTANT]
> A schedule is **batching, not quarantine**. It constrains when Renovate looks, not how old a commit must be. A commit pushed on Sunday evening is picked up Monday morning having had hours of upstream scrutiny, not a week. Average delay is around half the window; worst case is none.

---

## Custom Version Manifests

These files purposely centralize versions so Renovate can update them automatically:

- `home/dot_config/dotfiles/cli-versions.toml`
  - Holds pinned CLI versions used by the installer and scripts.
  - Currently: `cosign` (used for signature verification). Renovate updates via GitHub Releases.

- `.mise.toml` and `home/dot_config/mise/config.toml`
  - Define tool versions managed by [mise]. Pins explicit versions (no `latest`).
  - Supports multiple backends:
    - Native mise tools (e.g., `python = "3.13.7"`, `node = "24.11.1"`)
    - Aqua‑sourced tools (`"aqua:owner/repo" = "vX.Y.Z"`)
    - Ubi‑sourced tools (`"ubi:owner/repo" = "vX.Y.Z"`)
    - npm packages (`"npm:@scope/package" = "X.Y.Z"`)
    - Python/pipx tools (`"pipx:package" = "X.Y.Z"`)
  - Renovate updates all these via custom regex managers with appropriate datasources (npm, pypi, github-releases).

- `.devcontainer/devcontainer.json`
  - Base image and all features pinned to immutable `@sha256:` digests. Updated by `devcontainer` manager.

- `home/dot_config/docker-compose/*.yml`
  - Service images pinned with tag+digest (e.g., `image: repo:tag@sha256:...`). Digest updates are auto‑merged.

- `home/.chezmoiexternal.toml.tmpl`
  - All externals pinned to commit SHAs for reproducibility.
  - Tarball archives pinned in the URL with commit SHA.

- `home/.chezmoidata/tmux-plugins.yaml`
  - Tmux plugins pinned to commit SHAs. Renovate's JSONata manager updates them automatically.

---

## Custom Managers (Regex + Datasources)

Using Renovate’s `customManagers` to teach it how to parse and update versions in nonstandard files.

Defined in `renovate.json5`:

1) CLI versions (GitHub Releases)

- File: `home/dot_config/dotfiles/cli-versions.toml`
- Pattern: `^cosign\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases`, `depNameTemplate: sigstore/cosign`

2) Aqua‑prefixed tools in mise TOML (GitHub Releases)

- Files: `.mise.toml`, `home/dot_config/mise/config.toml`
- Pattern: `"aqua:(?<depName>[^/]+/[^\"]+)"\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases` (e.g., `aqua:mikefarah/yq` → `mikefarah/yq`)

3) Ubi‑prefixed tools in mise TOML (GitHub Releases)

- Files: `.mise.toml`, `home/dot_config/mise/config.toml`
- Pattern: `"ubi:(?<depName>[^/]+/[^\"]+)"\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases` (e.g., `ubi:sst/opencode` → `sst/opencode`)

4) npm‑prefixed tools in mise TOML (npm registry)

- Files: `.mise.toml`, `home/dot_config/mise/config.toml`
- Pattern: `"npm:(?<depName>[^\"]+)"\s*=\s*"(?<currentValue>[^\"]+)"`
- Datasource: `npm` (e.g., `npm:@anthropic-ai/claude-code` → `@anthropic-ai/claude-code`)

5) pipx‑prefixed tools in mise TOML (PyPI)

- Files: `.mise.toml`, `home/dot_config/mise/config.toml`
- Pattern: `"pipx:(?<depName>[^\"]+)"\s*=\s*"(?<currentValue>[^\"]+)"`
- Datasource: `pypi` (e.g., `pipx:<package>` → `<package>`)

6) Chezmoi externals pinned to SHAs (Git Refs)

- File: `home/.chezmoiexternal.toml.tmpl`
- Datasource: `git-refs` with `currentValueTemplate: "master"` (we track the upstream default branch and replace our pinned SHA when the branch moves).

Current rules:

- oh-my-zsh tarball: `ohmyzsh/ohmyzsh/archive/(?<currentDigest>[a-f0-9]{7,40})\.tar\.gz`
- zsh‑autosuggestions tarball: `zsh-users/zsh-autosuggestions/archive/(?<currentDigest>[a-f0-9]{7,40})\.tar\.gz`
- zsh‑syntax‑highlighting tarball: `zsh-users/zsh-syntax-highlighting/archive/(?<currentDigest>[a-f0-9]{7,40})\.tar\.gz`

Note: When adding new externals, add a matching regex rule so Renovate can keep their SHAs fresh automatically.

7) Tmux plugins (JSONata + YAML)

- File: `home/.chezmoidata/tmux-plugins.yaml`
- Manager: `jsonata` with `fileFormat: "yaml"`
- Query: `tmuxPlugins.{ "depName": repo, "currentValue": ref, "currentDigest": commit }`
- Datasource: `git-refs` — one manager handles all tmux plugins. Adding a plugin to the YAML file is enough; no Renovate config change needed.

---

## End‑to‑End Flow (What Renovate Updates)

- Docker/Devcontainer: PRs updating only digests or minor/patch releases; digests grouped and auto‑merged.
- GitHub Actions: digest pinning and minor/patch updates grouped and auto‑merged.
- Mise tools: PRs update `.mise.toml` and `home/dot_config/mise/config.toml` pins, including:
  - Native runtimes (Python, Node.js, etc.)
  - Aqua/Ubi tools (from GitHub releases)
  - npm packages (via `npm:` prefix)
  - Python/pipx tools (via `pipx:` prefix)
- CLI versions: PRs update `cli-versions.toml` (e.g., `cosign`).
- Chezmoi externals: PRs replace commit SHAs in tarball URLs or `revision = "..."`.

---

## How to Add or Change Pins

- Add a new mise tool:
  - Native runtime: add to `[tools]` with an exact version (e.g., `node = "24.11.1"`, `python = "3.14.0"`).
  - Aqua‑sourced: use `"aqua:owner/repo" = "vX.Y.Z"` to source releases from GitHub.
  - Ubi‑sourced: use `"ubi:owner/repo" = "vX.Y.Z"` to source releases from GitHub.
  - npm package: use `"npm:package-name" = "X.Y.Z"` or `"npm:@scope/package" = "X.Y.Z"`.
  - Python/pipx tool: use `"pipx:package-name" = "X.Y.Z"`.
  - Renovate will propose version bumps automatically via custom regex managers.

- Add a new CLI pin managed by scripts:
  - Add an entry to `home/dot_config/dotfiles/cli-versions.toml`.
  - Add code to read it where needed (e.g., `install.sh` reads `cosign`).
  - Add a `customManagers` regex rule if it’s not a standard ecosystem.

- Add a new Chezmoi external:
  - Pin to a specific commit SHA (tarball URL or `revision = "<sha>"`).
  - Add a matching `customManagers` rule using `git-refs` so Renovate can update it.

- Docker/Devcontainer:
  - Keep tag+digest pattern for images and features.
  - Renovate will update digests; human‑readable tag remains for clarity.

---

## Handy gh / gh api Commands

Latest release tag for a repo:

```bash
gh release view -R owner/repo --json tagName,url,publishedAt
# or
gh api repos/owner/repo/releases/latest --jq .tag_name
```

List recent tags:

```bash
gh api repos/owner/repo/tags?per_page=10 --jq '.[].name'
```

Resolve a tag to a commit SHA (works for most tags):

```bash
# 1) Direct ref resolution via commits endpoint
gh api repos/owner/repo/commits/v1.2.3 --jq .sha

# 2) For annotated tags, dereference the tag object to the commit:
tag_obj_sha=$(gh api repos/owner/repo/git/ref/tags/v1.2.3 --jq .object.sha)
gh api repos/owner/repo/git/tags/$tag_obj_sha --jq .object.sha
```

Get the latest commit on a branch (e.g., master/main):

```bash
gh api repos/owner/repo/commits/master --jq .sha
# or
gh api repos/owner/repo/commits/main --jq .sha
```

Show the latest 5 commits on a branch:

```bash
gh api repos/owner/repo/commits --method GET -F sha=master -F per_page=5 --jq '.[].sha'
```

Inspect release assets (e.g., to locate binary names/checksums):

```bash
gh api repos/owner/repo/releases/latest --jq '.assets[].name'
```

Examples (from this repo’s usage):

```bash
# Cosign release tag
gh api repos/sigstore/cosign/releases/latest --jq .tag_name

# Chezmoi externals (current master SHA to pin)
gh api repos/ohmyzsh/ohmyzsh/commits/master --jq .sha
gh api repos/zsh-users/zsh-autosuggestions/commits/master --jq .sha
gh api repos/zsh-users/zsh-syntax-highlighting/commits/master --jq .sha
gh api repos/tmux-plugins/tmux-sensible/commits/master --jq .sha
```

---

## Config Validation

Always validate Renovate configuration changes before committing:

```bash
# Validate configuration syntax and migrations
renovate-config-validator renovate.json5

# Check for syntax errors and deprecated patterns
npx renovate-config-validator renovate.json5
```

The validator will:
- Check JSON5 syntax and schema compliance
- Identify deprecated configuration patterns (e.g., `fileMatch` → `managerFilePatterns`)
- Suggest automatic migrations for outdated syntax
- Validate regex patterns and datasource configurations

**Important**: Always apply suggested migrations from the validator output to keep the config modern and prevent future breaking changes.

## Maintenance Tips

- Prefer explicit versions over `latest`; let Renovate do the bumping.
- When adding a new external or bespoke versions file, add a matching `customManagers` rule.
- Keep tag+digest for images: readable tag for humans, digest for reproducibility.
- Use the gh commands above to sanity‑check SHAs/tags when reviewing Renovate PRs.
- **Always validate renovate.json5 with `renovate-config-validator` before committing changes.**
