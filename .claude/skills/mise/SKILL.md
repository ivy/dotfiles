---
name: mise
description: Use when adding, updating, troubleshooting, or managing mise tool dependencies. Supplements /install with mise-specific context about backends, lockfiles, and the github-first policy.
argument-hint: [tool...]
allowed-tools:
  - Bash(chezmoi diff:*)
  - Bash(gh release view:*)
  - Bash(mise --cd*lock:*)
  - Bash(mise doctor:*)
  - Bash(mise fmt:*)
  - Bash(mise install:*)
  - Bash(mise latest:*)
  - Bash(mise lock:*)
  - Bash(mise ls:*)
  - Bash(mise ls-remote:*)
  - Bash(mise outdated:*)
  - Bash(mise prune:*)
  - Bash(mise registry:*)
  - Bash(mise run:*)
  - Bash(mise search:*)
  - Bash(mise tool:*)
  - Bash(mise uninstall:*)
  - Bash(mise watch:*)
  - Bash(mise where:*)
  - Bash(mise which:*)
  - Bash(npm view:*)
  - Bash(pip index:*)
  - Glob
  - Grep
  - Read
---

# Mise Tool Management

Mise-specific context for managing CLI tool dependencies. Use `/install` to add
a new tool end-to-end; use `/mise` when you need to understand backends,
troubleshoot failures, update versions, or regenerate lockfiles.

## Arguments

```
$ARGUMENTS
```

## Key Files

| File | Purpose |
|------|---------|
| `home/dot_config/mise/config.toml` | User tool manifest — edit here, never `~/.config/mise/config.toml` |
| `home/dot_config/mise/mise.lock` | User lockfile (auto-generated) |
| `mise.toml` | Project dev tool manifest (bats, shellcheck, hk, etc.) |
| `mise.lock` | Project lockfile (auto-generated) |
| `home/run_onchange_00-install-mise-tools.sh.tmpl` | Install trigger — runs on config/lock hash change |

## Backend Priority

Per [ADR-005](docs/adrs/005-replace-aqua-backend-with-github-releases.md):

| Priority | Backend | When to use |
|----------|---------|-------------|
| 1 | Native (`python`, `node`) | Runtimes |
| 2 | `github:owner/repo` | CLI tools with GitHub releases |
| 3 | `cargo:` | Rust tools without prebuilt binaries |
| 4 | `pipx:` | Python CLI tools |
| 5 | `npm:` | Node CLI tools |

**Do NOT use `aqua:` backend.** Registry lag and attestation mismatches break
`chezmoi apply`. The `github:` backend talks directly to GitHub Releases with
checksum, attestation, and SLSA verification.

## Instructions

### Adding a tool

1. Find the GitHub repo and latest release tag:
   ```bash
   gh release view --repo owner/repo --json tagName --jq '.tagName'
   ```

2. Determine version format — most use bare numbers (`0.18.2`) or `v`-prefixed
   tags (mise strips the `v` automatically). Some tools use non-standard tags
   (e.g., jq uses `jq-1.8.1`). If the tag doesn't follow `vX.Y.Z`, use the
   full tag string as the version.

3. Edit `home/dot_config/mise/config.toml` — add under the CLI tools section:
   ```toml
   "github:owner/repo" = "1.2.3"
   ```

4. Apply and regenerate lockfile:
   ```bash
   chezmoi apply ~/.config/mise/config.toml
   mise install --yes
   mise --cd home/dot_config/mise lock
   ```

5. Verify the tool runs. Check the binary name — it may differ from the repo
   name (e.g., `BurntSushi/ripgrep` installs `rg`).

### Updating a tool

1. Check current vs latest:
   ```bash
   mise ls
   gh release view --repo owner/repo --json tagName --jq '.tagName'
   ```

2. Edit the version in `home/dot_config/mise/config.toml`

3. Apply, install, and regenerate lockfile:
   ```bash
   chezmoi apply ~/.config/mise/config.toml
   mise install --yes
   mise --cd home/dot_config/mise lock
   ```

### Regenerating lockfiles

There are two lockfiles pinning checksums across 7 platforms (linux-arm64,
linux-arm64-musl, linux-x64, linux-x64-musl, macos-arm64, macos-x64,
windows-x64). Regenerate **both** after any config change:

```bash
mise lock                            # project-level (mise.toml)
mise --cd home/dot_config/mise lock  # user-level (config.toml)
```

### Troubleshooting install failures

**"No matching asset found"** — The tool doesn't publish binaries matching the
expected platform naming. Check available assets:
```bash
gh release view --repo owner/repo --json assets --jq '.assets[].name'
```

If assets exist but use unusual naming, the `github:` backend may not auto-detect
them. Options:
- Install via `cargo:` backend if it's a Rust tool
- Pull source via `chezmoiexternal` with a wrapper script in `~/.local/bin`
  (see turbocommit pattern in `.chezmoiexternal.toml.tmpl`)

**"No GitHub attestations found"** — This was the aqua failure mode. The
`github:` backend handles missing attestations gracefully — it verifies when
available but doesn't block when absent.

**Non-standard release tags** — If `mise install` returns 404, the tag format
likely doesn't match. Check the actual tag:
```bash
gh release view --repo owner/repo --json tagName --jq '.tagName'
```
Use the full tag string as the version (e.g., `jq-1.8.1` not `1.8.1`).

**Lockfile conflicts** — Delete and regenerate both:
```bash
mise lock                            # project-level
mise --cd home/dot_config/mise lock  # user-level
```

## Rules

- Edit `home/dot_config/mise/config.toml`, never `~/.config/mise/config.toml`
- Pin exact versions for all tools — Renovate handles updates
- Never use `latest` — always pin to a specific version
- Always regenerate lockfile after config changes
- Always verify the tool runs after installing
