# shellcheck shell=bash
# tmux-powerline configuration
# See: https://github.com/erikw/tmux-powerline

# General
export TMUX_POWERLINE_DEBUG_MODE_ENABLED="false"
export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

# Theme — Catppuccin, auto-detected from system appearance
# (matches Ghostty, Neovim, and Claude Code; see docs/catppuccin.md)
case "$("$HOME/.local/libexec/dotfiles/appearance")" in
  dark) export TMUX_POWERLINE_THEME="catppuccin-mocha" ;;
  *)    export TMUX_POWERLINE_THEME="catppuccin-latte" ;;
esac
export TMUX_POWERLINE_DIR_USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/themes"
export TMUX_POWERLINE_DIR_USER_SEGMENTS="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/segments"

# GitHub notifications (hide when zero, summarized count with icon)
export TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_TOKEN="$(gh auth token 2>/dev/null)"
export TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_SUMMARIZE="yes"
export TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_SYMBOL_MODE="yes"
export TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_HIDE_NO_NOTIFICATIONS="yes"

# Status bar
export TMUX_POWERLINE_STATUS_VISIBILITY="on"
export TMUX_POWERLINE_STATUS_INTERVAL=5
export TMUX_POWERLINE_STATUS_JUSTIFICATION="centre"
export TMUX_POWERLINE_STATUS_LEFT_LENGTH=30
export TMUX_POWERLINE_STATUS_RIGHT_LENGTH=90
