# Dotfiles Redux

This repository contains my personal dotfiles for setting up a productive developer environment on macOS, Linux, and containerized setups using [Devcontainers](https://containers.dev/). The goal is to provide a stable and maintainable environment that prioritizes pragmatic defaults over heavy customization.

## Philosophy

- **Pragmatism**: I prefer tools and configurations that are stable, well supported, and widely adopted. Instead of tinkering with bleeding-edge setups, I rely on curated collections such as Oh My Zsh and "sensible" defaults for various applications.
- **Portability**: These dotfiles should work across macOS and Linux machines, as well as within containers. They are designed to be reliable whether installed system-wide or through a Devcontainer configuration.
- **Consistency**: The configuration aims to make pairing with others easy by sticking to intuitive shortcuts and well-known conventions. While these dotfiles improve my workflow, I can still work effectively without them if necessary.
- **Reliability over Performance**: Start-up speed is less important than ensuring things always work. Runtime performance should not be significantly degraded by these configurations.

## Goals

1. **Stable setup** that rarely fails and is simple to maintain.
2. **Easy installation** on a fresh Mac or Linux system, with support for Devcontainers for containerized development.
3. **Shared tools** that follow common standards, enabling me to collaborate with others without friction.
4. **Documentation** that clearly explains the rationale behind each configuration choice.

## Installation

### Quick Start

```bash
git clone https://github.com/ivy/dotfiles-redux.git && cd dotfiles-redux && ./install.sh
```

### Advanced Usage

The installer supports various options and can pass arguments directly to `chezmoi init`:

```bash
# Force reinstall tools (if already installed)
REINSTALL_TOOLS=true ./install.sh

# Pass arguments to chezmoi init
./install.sh -- --force          # Force chezmoi to overwrite existing files
./install.sh -- --one-shot       # Use chezmoi's one-shot mode

# Combine options
REINSTALL_TOOLS=true ./install.sh -- --force
```

### Environment Variables

You can customize the installation behavior with these environment variables:

- `REINSTALL_TOOLS=true` - Force reinstallation of tools even if already present
- `BIN_DIR=/custom/path` - Install binaries to a custom directory (default: `~/.local/bin`)
- `DEBUG=1` - Enable debug output during installation
- `VERIFY_SIGNATURES=false` - Disable signature verification (not recommended)

For a complete list of options, run `./install.sh --help`.

## License

This project is open source under the [ISC License](LICENSE.md), credited to Ivy Evans.

