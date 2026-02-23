# Tmux Configuration

Standalone tmux configuration using XDG paths (`~/.config/tmux/`) with tmux-sensible as the base layer.

## Overview

- **Config**: `home/dot_config/tmux/tmux.conf` — single self-contained file
- **Plugins**: Data-driven via `home/.chezmoidata/tmux-plugins.yaml`
- **Plugin install**: Chezmoi externals (archive tarballs to `~/.config/tmux/plugins/`)
- **Auto-updates**: Renovate JSONata manager tracks upstream commits
- **Vi Mode**: Vi-style navigation and copy mode throughout

## Architecture

### XDG Layout

```
~/.config/tmux/
  tmux.conf                    # Main config (all settings)
  plugins/
    tmux-sensible/             # Installed by chezmoi external
```

tmux 3.1+ automatically loads `~/.config/tmux/tmux.conf` — no symlinks needed.

### Plugin Management

Plugins are defined in `home/.chezmoidata/tmux-plugins.yaml` and installed as chezmoi archive externals to `~/.config/tmux/plugins/`. Adding a new plugin = add a YAML entry. No template or Renovate config changes needed.

See [ADR 003](adrs/003-use-chezmoi-externals-for-tmux-plugin-management.md) for the decision rationale.

### `tmux-plugins.yaml` Schema

Each entry in `tmuxPlugins` maps to one chezmoi external and one `run-shell` line in `tmux.conf`:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Install directory name under `~/.config/tmux/plugins/` |
| `repo` | string | GitHub slug (`owner/repo`) |
| `ref` | string | Tracking ref (branch or tag) — used by Renovate to find new commits |
| `commit` | string | Pinned commit SHA — used in the archive tarball URL |

Renovate's JSONata manager reads `ref` as `currentValue` and `commit` as `currentDigest`, then updates `commit` when the branch advances.

### Load Order

1. `run-shell` tmux-sensible (sane defaults)
2. Terminal & display settings
3. Prefix (C-a)
4. General behavior (base-index, renumber, mouse)
5. Vi mode + copy mode bindings
6. vim-tmux-navigator smart pane switching
7. Prefix-based pane navigation and resize
8. Utility bindings (clear, split, reload, window chooser, Claude)

tmux-sensible loads first so explicit settings can override its defaults.

## Appearance

The status bar uses [tmux-powerline](https://github.com/erikw/tmux-powerline) with Catppuccin theming. The theme variant is auto-detected from macOS system appearance at shell startup:

- **Dark mode** → `catppuccin-mocha`
- **Light mode** → `catppuccin-latte`

Detection uses the same `defaults read -g AppleInterfaceStyle` pattern as Ghostty, Neovim, and Claude Code powerline (see [docs/catppuccin.md](catppuccin.md#appearance-detection-pattern)).

To switch after changing system appearance: `prefix + r` (reload config). The theme re-evaluates on reload because `config.sh` runs the detection each time tmux-powerline sources it.

## Keybindings

### Prefix

`C-a` (Ctrl+a) — replaces default `C-b`.

### Smart Navigation (vim-tmux-navigator)

Works seamlessly between tmux panes and Neovim splits:

| Key | Action |
|-----|--------|
| `Ctrl+h` | Move left |
| `Ctrl+j` | Move down |
| `Ctrl+k` | Move up |
| `Ctrl+l` | Move right |
| `Ctrl+\` | Previous pane/split |

Requires `christoomey/vim-tmux-navigator` Neovim plugin.

### Prefix-based Navigation

| Key | Action |
|-----|--------|
| `prefix + h/j/k/l` | Select pane |
| `prefix + H/J/K/L` | Resize pane (repeatable) |

### Copy Mode (Vi)

| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `y` | Yank and exit copy mode |

### Utility

| Key | Action |
|-----|--------|
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + C-l` | Clear terminal + history |
| `prefix + r` | Reload config |
| `prefix + w` | Window/session chooser |
| `prefix + e` | Open Claude Code in dotfiles dir |

## Installation & Management

### Apply config

```bash
chezmoi apply
```

This installs both the config file and all plugins.

### Add a new plugin

1. Get the current commit SHA:
   ```bash
   gh api repos/OWNER/REPO/commits/BRANCH --jq .sha
   ```

2. Add entry to `home/.chezmoidata/tmux-plugins.yaml`:
   ```yaml
   - name: plugin-name
     repo: owner/repo
     ref: main
     commit: <sha>
   ```

3. Add `run-shell` line to `tmux.conf`:
   ```bash
   run-shell ~/.config/tmux/plugins/plugin-name/plugin-name.tmux
   ```

4. Apply: `chezmoi apply`

Renovate will automatically keep the commit SHA updated.

### Reload after changes

```bash
# From inside tmux
prefix + r

# From command line
tmux source-file ~/.config/tmux/tmux.conf
```

## Troubleshooting

### Navigation not working

- Ensure Neovim has `vim-tmux-navigator` plugin installed
- Check tmux version: `tmux -V` (need 3.1+ for XDG support)
- Verify `ps` command output format on your system

### Config not loading

- Confirm `~/.config/tmux/tmux.conf` exists: `chezmoi apply`
- Check for syntax errors: `tmux source-file ~/.config/tmux/tmux.conf`
- View tmux messages: `tmux show-messages`

### Plugin issues

- Verify plugin is installed: `ls ~/.config/tmux/plugins/`
- Force re-download: `chezmoi apply --force`

## References

- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) — Sane defaults
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) — Seamless navigation
- [Tmux Manual](http://man.openbsd.org/OpenBSD-current/man1/tmux.1) — Complete documentation
- [ADR 003](adrs/003-use-chezmoi-externals-for-tmux-plugin-management.md) — Plugin management decision
