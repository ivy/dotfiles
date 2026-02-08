# AGENTS.md

@AGENTS.local.md

Personal dotfiles managed by coding agents via [Chezmoi](https://www.chezmoi.io/). Targets macOS (darwin) and Fedora Linux. See [docs/vision.md](docs/vision.md) and [docs/core-principles.md](docs/core-principles.md) for the philosophy behind this setup.

## The Stack

| Layer | Component | Config source |
|-------|-----------|---------------|
| Terminal | Ghostty | `home/dot_config/ghostty/config` |
| Multiplexer | tmux | `home/dot_tmux.conf.local` |
| Shell | zsh + Oh-My-Zsh | `home/dot_zshrc.tmpl` |
| Editor | Neovim / LazyVim | `home/dot_config/nvim/` |
| Tools | mise (aqua backend) | `home/dot_config/mise/config.toml` |
| Git | git + delta | `home/dot_config/git/config.tmpl` |
| AI agents | Claude Code | `.claude/` (skills, hooks, agents) |
| SSH | 1Password agent | `home/private_dot_ssh/` |
| Services | Docker Compose | `home/dot_config/docker-compose/` |
| Updates | Renovate | `renovate.json5` |

**What it feels like:** Ghostty launches into tmux, tmux runs zsh with Starship prompt, Neovim is the editor. Vim keybindings work everywhere — shell, multiplexer, editor. Navigation between tmux panes and Neovim splits is seamless via tmux-navigator.

## Repo Map

```
home/                  # All managed dotfiles (Chezmoi source)
  dot_config/          #   -> ~/.config/
  dot_local/bin/       #   -> ~/.local/bin/
  private_dot_ssh/     #   -> ~/.ssh/
  private_Library/     #   -> ~/Library/ (macOS only)
test/                  # BATS test suite
docs/                  # Architecture docs and ADRs
.claude/               # Agent infrastructure
  skills/              #   Slash-command skills
  hooks/               #   Pre/post tool hooks
  agents/              #   Subagent definitions
```

## How to Work Here

### The One Rule

**Edit in `home/`, never in `~` or `~/.config/`.** Chezmoi owns the home directory — destination edits get overwritten on next apply.

| To change... | Edit this |
|--------------|-----------|
| `~/.zshrc` | `home/dot_zshrc.tmpl` |
| `~/.config/mise/config.toml` | `home/dot_config/mise/config.toml` |
| `~/.config/ghostty/config` | `home/dot_config/ghostty/config` |

### Change Workflow

1. Edit source files in `home/`
2. `chezmoi diff` — review; only your changes should appear
3. `chezmoi apply [target ...]` — apply (selectively if diff shows unrelated changes)
4. `chezmoi status` — confirm clean state
5. Verify in a tmux PTY when touching shell/terminal config:

```bash
tmux new-session -d -s verify -x 200 -y 50 "zsh -l"
sleep 2 && tmux capture-pane -t verify -p
tmux kill-session -t verify
```

### Testing

```bash
bats test/              # Run all tests
bats test/<file>.bats   # Run one test file
```

## Skills

| Skill | Purpose |
|-------|---------|
| `/install <pkg>` | Add a tool — detects type, pins version, updates manifests |
| `/nvim` | Troubleshoot Neovim plugin errors or update after breaking changes |
| `/update` | Morning routine — merge Renovate PRs, rebase, apply chezmoi |
| `/commit` | Commit with conventional message and intentional file selection |

## Change Hygiene

- **Pin versions** — every dependency gets an exact version; Renovate handles updates
- **Prefer mise** — install CLI tools via `mise use` (aqua backend), not brew/dnf/npm
- **One change per commit** — small, conventional commits via `/commit`
- **Package Manager subagent** — use for version conflicts, container images, bulk updates, or GitHub Actions digests (see [docs/renovate.md](docs/renovate.md))

## Deep Dives

| Topic | Doc |
|-------|-----|
| Package management | [docs/package-management.md](docs/package-management.md) |
| Renovate & version pinning | [docs/renovate.md](docs/renovate.md) |
| Neovim / LazyVim | [docs/neovim.md](docs/neovim.md) |
| tmux | [docs/tmux.md](docs/tmux.md) |
| Zsh | [docs/zsh.md](docs/zsh.md) |
| Claude Code integration | [docs/claude-code.md](docs/claude-code.md) |
| Core principles | [docs/core-principles.md](docs/core-principles.md) |
| Vision | [docs/vision.md](docs/vision.md) |
| Chezmoi operations | [docs/agents/chezmoi.md](docs/agents/chezmoi.md) |
| Shell architecture ADR | [docs/adrs/0002-agent-optimized-shell-with-envsense.md](docs/adrs/0002-agent-optimized-shell-with-envsense.md) |

## Where to Look First

- **Add a tool**: `/install <name>` — it handles everything
- **Fix a broken Neovim plugin**: `/nvim`
- **Understand a config file**: Read the source in `home/` — templates use Go text/template (`.chezmoi.os`, `lookPath`)
- **Platform-specific logic**: Check `.chezmoiignore` and `.tmpl` files for `{{ if eq .chezmoi.os "darwin" }}` guards
- **Morning catchup**: `/update` merges Renovate PRs and applies changes
- **Chezmoi internals**: [docs/agents/chezmoi.md](docs/agents/chezmoi.md) covers templates, scripts, prefixes, and troubleshooting
