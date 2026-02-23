# shellcheck shell=bash disable=SC2034
# Catppuccin Latte theme for tmux-powerline
# https://github.com/catppuccin/catppuccin
#
# Matches the Catppuccin Latte palette used across Ghostty, Neovim, and
# Claude Code powerline in this dotfiles repo.

# --- Catppuccin Latte palette -------------------------------------------------
rosewater="#dc8a78"
flamingo="#dd7878"
pink="#ea76cb"
mauve="#8839ef"
red="#d20f39"
maroon="#e64553"
peach="#fe640b"
yellow="#df8e1d"
green="#40a02b"
teal="#179299"
sky="#04a5e5"
sapphire="#209fb5"
blue="#1e66f5"
lavender="#7287fd"
text="#4c4f69"
subtext1="#5c5f77"
subtext0="#6c6f85"
overlay2="#7c7f93"
overlay1="#8c8fa1"
overlay0="#9ca0b0"
surface2="#acb0be"
surface1="#bcc0cc"
surface0="#ccd0da"
base="#eff1f5"
mantle="#e6e9ef"
crust="#dce0e8"

# --- Powerline separators (Nerd Font slants) ---------------------------------
TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=$'\xee\x82\xba'  # U+E0BA nf-pl-left_hard_divider_inverse
TMUX_POWERLINE_SEPARATOR_LEFT_THIN=$'\xee\x82\xbb'  # U+E0BB nf-pl-left_soft_divider_inverse
TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=$'\xee\x82\xbc' # U+E0BC nf-pl-right_hard_divider_inverse
TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=$'\xee\x82\xbd' # U+E0BD nf-pl-right_soft_divider_inverse
TMUX_POWERLINE_SEPARATOR_THIN="|"

# --- Alert helpers (color escalation for notification rail) ------------------
source "${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/helpers/alert_helpers.sh"

# --- Theme defaults -----------------------------------------------------------
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-$mantle}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-$text}
TMUX_POWERLINE_SEG_AIR_COLOR=$(tp_air_color)

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

# --- Window status (centre tab list) -----------------------------------------
# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_CURRENT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[$(tp_format inverse)]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
		$' #I #W#{?window_zoomed_flag, \xef\x8b\x90,} '
		"#[$(tp_format regular)]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_STYLE" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
		"$(tp_format regular)"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_FORMAT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[$(tp_format regular)]"
		$' #I #W#{?window_zoomed_flag, \xef\x8b\x90,} '
	)
fi

# --- Left status segments ----------------------------------------------------
# Format: "segment_name bg fg [separator] [sep_bg] [sep_fg] [spacing] [sep_disable]"

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		"tmux_session_info $blue $base"
	)
fi

# --- Right status segments ----------------------------------------------------

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		"mode_indicator $mantle $text"
		"alert_hostname $mauve $base"
		"github_notifications $lavender $base"
		"alert_load $(tp_alert_color_load) $base"
		"alert_mem $(tp_alert_color_mem) $base"
		"alert_disk $(tp_alert_color_disk) $base"
	)
fi
