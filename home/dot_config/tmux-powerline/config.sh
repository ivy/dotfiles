# tmux-powerline configuration
# See: https://github.com/erikw/tmux-powerline

# General
export TMUX_POWERLINE_DEBUG_MODE_ENABLED="false"
export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

# Theme — Catppuccin, auto-detected from macOS appearance
# (matches Ghostty, Neovim, and Claude Code; see docs/catppuccin.md)
_style=$(defaults read -g AppleInterfaceStyle 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)
case "$_style" in
  dark) export TMUX_POWERLINE_THEME="catppuccin-mocha" ;;
  *)    export TMUX_POWERLINE_THEME="catppuccin-latte" ;;
esac
unset _style
export TMUX_POWERLINE_DIR_USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/themes"
export TMUX_POWERLINE_DIR_USER_SEGMENTS="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/segments"

# Status bar
export TMUX_POWERLINE_STATUS_VISIBILITY="on"
export TMUX_POWERLINE_STATUS_INTERVAL=5
export TMUX_POWERLINE_STATUS_JUSTIFICATION="centre"
export TMUX_POWERLINE_STATUS_LEFT_LENGTH=60
export TMUX_POWERLINE_STATUS_RIGHT_LENGTH=90
