# shellcheck shell=bash disable=SC2034
# Catppuccin Mocha theme for tmux-powerline
# https://github.com/catppuccin/catppuccin
#
# Matches the Catppuccin Mocha palette used across Ghostty, Neovim, and
# Claude Code powerline in this dotfiles repo.

# --- Catppuccin Mocha palette ------------------------------------------------
rosewater="#f5e0dc"
flamingo="#f2cdcd"
pink="#f5c2e7"
mauve="#cba6f7"
red="#f38ba8"
maroon="#eba0ac"
peach="#fab387"
yellow="#f9e2af"
green="#a6e3a1"
teal="#94e2d5"
sky="#89dceb"
sapphire="#74c7ec"
blue="#89b4fa"
lavender="#b4befe"
text="#cdd6f4"
subtext1="#bac2de"
subtext0="#a6adc8"
overlay2="#9399b2"
overlay1="#7f849c"
overlay0="#6c7086"
surface2="#585b70"
surface1="#45475a"
surface0="#313244"
base="#1e1e2e"
mantle="#181825"
crust="#11111b"

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
		"#[fg=$mantle,bg=$lavender,nobold,noitalics,nounderscore]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
		"#[fg=$crust,bg=$lavender]"
		$' #I #W#{?window_zoomed_flag, \xef\x8b\x90,} '
		"#[fg=$lavender,bg=$mantle,nobold,noitalics,nounderscore]"
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
		"tmux_session_info $blue $crust"
	)
fi

# --- Right status segments ----------------------------------------------------

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		"theme_refresh $mantle $mantle"
		"mode_indicator $mantle $text"
		"alert_hostname $mauve $crust"
		"github_notifications $lavender $crust"
		"alert_load $(tp_alert_color_load) $crust"
		"alert_mem $(tp_alert_color_mem) $crust"
		"alert_disk $(tp_alert_color_disk) $crust"
	)
fi
