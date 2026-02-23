# shellcheck shell=bash
# Mode indicator — notification rail style.
# Silent in normal mode; shows Nerd Font icons only for non-default states.
# Overrides upstream mode_indicator.sh via TMUX_POWERLINE_DIR_USER_SEGMENTS.

run_segment() {
	local sep=" "
	local keyboard=$'\xf3\xb0\x8c\x8c' # U+F030C nf-md-keyboard
	local clipboard=$'\xef\x81\xbf'     # U+F07F  nf-fa-clipboard
	local pause=$'\xf3\xb0\x8f\xa4'     # U+F03E4 nf-md-pause

	# Suspend overrides all other modes.
	if [ "$(tmux show-option -qv key-table)" = "suspended" ]; then
		echo "$pause"
		return 0
	fi

	# Prefix and copy use tmux format conditionals (evaluated at render time).
	echo "#{?client_prefix,${keyboard},}#{?pane_in_mode,#{?client_prefix,${sep},}${clipboard},}"

	return 0
}
