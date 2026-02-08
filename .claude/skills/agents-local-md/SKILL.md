---
name: agents-local-md
description: "Generate machine-specific AGENTS.local.md with host facts, tool provenance, and platform quirks"
argument-hint: "[--force]"
model: sonnet
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(uname:*)
  - Bash(hostname:*)
  - Bash(command -v:*)
  - Bash(which:*)
  - Bash(zsh --version:*)
  - Bash(tmux -V:*)
  - Bash(nvim --version:*)
  - Bash(git --version:*)
  - Bash(mise ls:*)
  - Bash(mise where:*)
  - Bash(mise doctor:*)
  - Bash(chezmoi data:*)
  - Bash(chezmoi ignored:*)
  - Bash(chezmoi managed:*)
  - Bash(chezmoi doctor:*)
  - Bash(readlink:*)
  - Bash(test -f:*)
  - Bash(test -L:*)
  - Bash(ls:*)
  - Bash(cat /etc/os-release:*)
  - Bash(delta --version:*)
  - Bash(starship --version:*)
  - Bash(gh --version:*)
  - Bash(stat:*)
  - Bash(date:*)
  # NOTE: Write and ln require user approval (intentional)
---

# Generate AGENTS.local.md

Probe this machine's environment and write `AGENTS.local.md` — a machine-specific context file that Claude Code auto-loads via `CLAUDE.local.md` symlink. Facts only, no duplication with `AGENTS.md`.

## Arguments

```
$ARGUMENTS
```

Options:
- `--force` — regenerate even if the file is fresh

## Instructions

### 1. Freshness Check

If `AGENTS.local.md` exists in the repo root:

```bash
stat -c %Y AGENTS.local.md 2>/dev/null || stat -f %m AGENTS.local.md 2>/dev/null
```

Read the file and extract the `Generated:` line. If ALL of these are true, report "AGENTS.local.md is current (generated DATE on HOSTNAME)" and **stop**:
- File is less than 7 days old
- Hostname in file matches current hostname
- OS in file matches current OS
- `--force` was NOT passed in arguments

Otherwise, continue to regenerate.

### 2. Probe System Identity

Gather:
```bash
uname -s        # OS kernel (Darwin/Linux)
uname -m        # Architecture (x86_64/arm64)
hostname -s     # Short hostname
cat /etc/os-release  # Linux distro details (skip on macOS)
```

### 3. Probe Package Manager

Determine which system package manager is available:
- macOS: `command -v brew`
- Linux: `command -v dnf` or `command -v apt`

Note how chezmoi uses it (check `home/.chezmoidata/packages.yaml`).

### 4. Probe Tool Versions & Provenance

For each tool: **zsh, tmux, nvim, git, mise, delta, starship, gh**

Collect:
- Version: run `<tool> --version` (or equivalent)
- Path: `command -v <tool>`
- Source: determine provenance:
  - If path contains `/mise/` → "mise"
  - If path contains `/brew/` or `/Homebrew/` → "brew"
  - If path is `/usr/bin/` or `/usr/sbin/` → "system"
  - If path contains `/nix/` → "nix"
  - Otherwise → note the actual path

Use `mise ls` to cross-reference which tools mise manages.

### 5. Probe Platform Quirks

Check for known issues and platform-specific facts:

**Fedora Linux:**
- Is eza available via system package? (`command -v eza`)
- Is dust available via system package? (`command -v dust`)
- How was mise installed? (COPR, curl, or mise shims path)
- Mise shims path: `ls ~/.local/share/mise/shims/` exists?

**macOS:**
- Homebrew prefix: `command -v brew && brew --prefix`
- GNU coreutils installed? (`command -v gdircolors`)

**Both platforms:**
- 1Password SSH agent socket: check if socket exists at platform-appropriate path
- Docker/Podman: `command -v docker` and `command -v podman`

### 6. Analyze Chezmoi Platform View

```bash
chezmoi data --format json | grep -E '"os"|"arch"|"hostname"'
chezmoi ignored
```

Read `.chezmoiignore` to summarize what's excluded on this platform.

### 7. Write AGENTS.local.md

Write the file to the **repo root** (`AGENTS.local.md`). Target <80 lines. Use this structure:

```markdown
# AGENTS.local.md

> Machine-specific context for coding agents. Auto-generated — do not edit.
> Regenerate with `/agents-local-md --force`.

Generated: YYYY-MM-DD on HOSTNAME (OS ARCH)

## System

- **OS:** e.g., Fedora 42 (Linux 6.x) / macOS 15.x (Darwin)
- **Arch:** x86_64 / arm64
- **Package manager:** dnf / brew

## Tool Provenance

| Tool | Version | Source | Path |
|------|---------|--------|------|
| zsh | 5.9 | system | /usr/bin/zsh |
| tmux | 3.5a | system | /usr/bin/tmux |
| nvim | 0.10.x | mise | ~/.local/share/mise/installs/... |
| ... | ... | ... | ... |

## Platform Quirks

- List of notable platform-specific facts
- e.g., "eza not in Fedora repos — installed via mise"
- e.g., "1Password SSH agent at ~/.1password/agent.sock"
- e.g., "Podman available, Docker is not"

## Chezmoi View

- **Excluded on this platform:** list from .chezmoiignore
- **Active templates:** count of .tmpl files with platform guards
```

**Rules for content:**
- Facts only — no opinions, no recommendations
- No duplication with `AGENTS.md` (which covers repo structure and workflow)
- No upstream documentation content
- No session-ephemeral data (PID, uptime, load)
- Truncate long paths with `~` for home directory

### 8. Create Symlink

```bash
ln -sf AGENTS.local.md CLAUDE.local.md
```

This makes Claude Code auto-load the file as `CLAUDE.local.md`.

### 9. Verify

```bash
test -f AGENTS.local.md && echo "AGENTS.local.md exists"
test -L CLAUDE.local.md && readlink CLAUDE.local.md
git status AGENTS.local.md CLAUDE.local.md
```

Confirm:
- `AGENTS.local.md` exists and has content
- `CLAUDE.local.md` is a symlink pointing to `AGENTS.local.md`
- Both are gitignored (should not appear in `git status`)

Report: "Generated AGENTS.local.md (N lines) — CLAUDE.local.md symlinked. Both gitignored."
