# Dotfiles

A personal developer environment managed by coding agents. I provide intent and taste; agents handle the rest — installation, configuration, updates, and repairs.

Built on [Chezmoi](https://www.chezmoi.io/) for dotfile management, [Renovate](https://docs.renovatebot.com/) for automated dependency updates, and [Claude Code](https://docs.anthropic.com/en/docs/claude-code) for everything else.

## Stack

| Layer | Tool | What's going on |
|-------|------|-----------------|
| Terminal | [Ghostty](home/dot_config/ghostty/) | FiraCode Nerd Font, Catppuccin theme, split/tab keybindings |
| Shell | [zsh](home/dot_zshrc.tmpl) | Oh My Zsh, vi keybindings, atuin history, syntax highlighting, 1Password credential injection |
| Multiplexer | [tmux](home/dot_tmux.conf.local) | gpakosz/.tmux framework, vim-tmux-navigator, vi copy mode |
| Editor | [Neovim](home/dot_config/nvim/) | LazyVim distribution, Catppuccin, 30+ plugins, Claude Code integration |
| Tools | [mise](home/dot_config/mise/config.toml) | 20+ pinned CLIs across aqua, npm, pipx, and cargo backends |
| Dotfiles | [Chezmoi](home/) | Templated configs, run-on-change scripts, pinned externals |
| Deps | [Renovate](renovate.json5) | Automated updates for mise, Actions, Docker, Neovim plugins, and Chezmoi externals |
| CI | [GitHub Actions](.github/workflows/) | ShellCheck + BATS on push, Claude Code review on PRs |
| Agents | [Claude Code](.claude/) | Skills, hooks, specialized subagents — agents manage the environment end-to-end |
| Containers | [Devcontainer](.devcontainer/) | Debian Bookworm with mise, Docker-in-Docker, and GitHub CLI |

Every dependency is version-pinned. Every update flows through automation.

For the thinking behind this setup, see [docs/vision.md](docs/vision.md) and [docs/core-principles.md](docs/core-principles.md).

## Installation

```bash
git clone https://github.com/ivy/dotfiles.git && cd dotfiles && ./install.sh
```

Run `./install.sh --help` for options, or see [CLAUDE.md](CLAUDE.md) for the full development workflow.

## Not a Product

This is a personal setup. There's no support, no issues, no PRs. You're welcome to read, learn from, and steal from it — but it's built for one person and maintained by their agents.

## License

[ISC License](LICENSE.md) — Ivy Evans.
