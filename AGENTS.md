# AGENTS.md

@AGENTS.local.md

Personal dotfiles managed by coding agents via [Chezmoi](https://www.chezmoi.io/). Targets macOS (darwin) and Fedora Linux. See [docs/vision.md](docs/vision.md) and [docs/core-principles.md](docs/core-principles.md) for the philosophy behind this setup.

## The Stack

| Layer | Component | Config source |
|-------|-----------|---------------|
| Terminal | Ghostty | `home/dot_config/ghostty/config.tmpl` |
| Multiplexer | tmux | `home/dot_config/tmux/tmux.conf` |
| Shell | zsh + Oh-My-Zsh | `home/dot_zshrc.tmpl` |
| Editor | Neovim / LazyVim | `home/dot_config/nvim/` |
| Tools | mise (aqua backend) | `home/dot_config/mise/config.toml` |
| Git | git + delta | `home/dot_config/git/config.tmpl` |
| AI agents | Claude Code | `home/dot_claude/` (user) + `.claude/` (project) |
| SSH | 1Password agent | `home/private_dot_ssh/` |
| Services | Docker Compose | `home/dot_config/docker-compose/` |
| Updates | Renovate | `renovate.json5` |

**What it feels like:** Ghostty launches into tmux, tmux runs zsh with Starship prompt, Neovim is the editor. Vim keybindings work everywhere — shell, multiplexer, editor. Navigation between tmux panes and Neovim splits is seamless via tmux-navigator.

## Repo Map

```
home/                  # All managed dotfiles (Chezmoi source)
  dot_config/          #   -> ~/.config/
  dot_claude/          #   -> ~/.claude/ (user-scope skills, agents, settings)
  dot_local/bin/       #   -> ~/.local/bin/
  private_dot_ssh/     #   -> ~/.ssh/
  private_Library/     #   -> ~/Library/ (macOS only)
bin/                   # Repo scripts: setup, test, sync-claude-*
test/                  # BATS test suite
docs/                  # Architecture docs; decisions in docs/adrs/
.claude/               # Project-scope agent config (this repo only)
  skills/              #   Project slash-commands
  hooks/               #   Pre/post tool hooks
  agents/              #   Subagent definitions
hk.pkl                 # Lint/format hooks (pre-commit, pre-push, CI)
mise.toml              # Dev tool pins + `mise run` tasks
```

## How to Work Here

### The One Rule

**Edit in `home/`, never in `~` or `~/.config/`.** Chezmoi owns the home directory — destination edits get overwritten on next apply.

| To change... | Edit this |
|--------------|-----------|
| `~/.zshrc` | `home/dot_zshrc.tmpl` |
| `~/.config/mise/config.toml` | `home/dot_config/mise/config.toml` |
| `~/.config/ghostty/config` | `home/dot_config/ghostty/config.tmpl` |

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

### Commands

```bash
./bin/setup             # Bootstrap dev tools via mise
./bin/test              # Run all tests (what CI runs)
bats test/<file>.bats   # Run one test file
mise run lint           # Lint + auto-fix (hk fix)
hk check                # Lint without fixing (what CI runs)
```

**Before opening a PR:** `hk check && ./bin/test`

`hk` also runs automatically on pre-commit and pre-push — it stashes unstaged
changes, auto-fixes, and enforces conventional commit messages. See `hk.pkl`.

## Skills

Two scopes, two sources — edit the source, never `~/.claude/`:

- **User** (available everywhere): `home/dot_claude/skills/` → `~/.claude/skills/` on apply
- **Project** (this repo only): `.claude/skills/`

Most-used:

| Skill | Purpose |
|-------|---------|
| `/install <name>` | Add a tool, package, Claude Code plugin, or MCP server — detects type, routes by scope (user→dotfiles, project→repo), pins/updates manifests |
| `/nvim` | Troubleshoot Neovim plugin errors or update after breaking changes |
| `/update` | Morning routine — merge Renovate PRs, rebase, apply chezmoi |
| `/commit` | Commit with conventional message and intentional file selection |

Browse the two dirs above for the full set (~35 skills).

## Change Hygiene

- **Pin versions** — every dependency gets an exact version; Renovate handles updates
- **Prefer mise / `/install`** — add tools, plugins, and MCP servers via `/install`; ad-hoc installers (`npx`/`pipx`/`pip install`/`npm -g`/…) are blocked by a guard hook, so don't reach for them. See [docs/claude-code.md](docs/claude-code.md)
- **One change per commit** — small, conventional commits via `/commit`
- **Package Manager subagent** — use for version conflicts, container images, bulk updates, or GitHub Actions digests (see [docs/renovate.md](docs/renovate.md))

## Deep Dives

| Topic | Doc |
|-------|-----|
| Package management | [docs/package-management.md](docs/package-management.md) |
| Renovate & version pinning | [docs/renovate.md](docs/renovate.md) |
| Neovim / LazyVim | [docs/neovim.md](docs/neovim.md) |
| tmux | [docs/tmux.md](docs/tmux.md) |
| tmux-powerline (notification rail) | [docs/tmux-powerline.md](docs/tmux-powerline.md) |
| Zsh | [docs/zsh.md](docs/zsh.md) |
| Claude Code integration | [docs/claude-code.md](docs/claude-code.md) |
| Core principles | [docs/core-principles.md](docs/core-principles.md) |
| Vision | [docs/vision.md](docs/vision.md) |
| Chezmoi operations | [docs/agents/chezmoi.md](docs/agents/chezmoi.md) |
| Skill effort tuning | [docs/skill-effort-tuning.md](docs/skill-effort-tuning.md) |
| Architecture decisions (ADR 001–006) | [docs/adrs/](docs/adrs/) |
| Supply chain security | [docs/supply-chain-security.md](docs/supply-chain-security.md) |
| GitHub labels & triage | [docs/labels.md](docs/labels.md) |

## Where to Look First

- **Add a tool**: `/install <name>` — it handles everything
- **Fix a broken Neovim plugin**: `/nvim`
- **Understand a config file**: Read the source in `home/` — templates use Go text/template (`.chezmoi.os`, `lookPath`)
- **Platform-specific logic**: Check `.chezmoiignore` and `.tmpl` files for `{{ if eq .chezmoi.os "darwin" }}` guards
- **Morning catchup**: `/update` merges Renovate PRs and applies changes
- **Chezmoi internals**: [docs/agents/chezmoi.md](docs/agents/chezmoi.md) covers templates, scripts, prefixes, and troubleshooting
