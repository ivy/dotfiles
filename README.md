# Dotfiles

A personal developer environment managed by coding agents. I provide intent and taste; agents handle the rest — installation, configuration, updates, and repairs.

Built on [Chezmoi](https://www.chezmoi.io/) for dotfile management, [Renovate](https://docs.renovatebot.com/) for automated dependency updates, and [Claude Code](https://docs.anthropic.com/en/docs/claude-code) for everything else.

## What's Here

zsh, tmux, neovim (LazyVim), ghostty, mise, and the glue that holds them together. Every dependency is version-pinned. Every update flows through automation.

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
