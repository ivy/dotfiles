# Zsh Configuration

This document describes the zsh shell configuration in this dotfiles repository.

## Configuration Files

The zsh configuration is split across two files:

- `home/dot_zshenv` - Environment setup and PATH configuration
- `home/dot_zshrc` - Interactive shell configuration

## Environment Setup (dot_zshenv)

### XDG Base Directory Specification

The configuration implements the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) for standardized directory locations:

```bash
# User directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# System directories
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
```

### PATH Management

The configuration adds `~/.local/bin` to the front of PATH if it exists and isn't already present, following the XDG pattern for user binaries.

## Interactive Shell Configuration (dot_zshrc)

### Oh My Zsh Framework

The configuration uses [Oh My Zsh](https://ohmyz.sh/) framework with:
- Installation path: `$HOME/.oh-my-zsh`
- No custom theme (commented out default)
- Standard configuration options left as comments for reference

### Vi Mode

Vi keybindings are enabled for command line editing:
```bash
bindkey -v
```

### Custom Functions

#### reload! Function

A shell reload function for fast configuration reloads. Simply run `reload!` to restart your shell session with updated configuration.

## Design Philosophy

The configuration follows a minimalist approach:
- Uses Oh My Zsh for base functionality but doesn't over-customize
- Implements standard specifications (XDG Base Directory)
- Provides robust utility functions with comprehensive fallbacks
- Keeps most Oh My Zsh options as commented examples for reference

## Key Features

- **XDG Compliance**: Proper directory structure following standards
- **Clean PATH Management**: Safely adds user bin directory
- **Vi Mode**: Familiar vi keybindings for command editing
- **Tool Integration**: Modern tools (mise, starship) integrated via plugins
- **Fast Reload**: Custom `reload!` function for quick shell restarts