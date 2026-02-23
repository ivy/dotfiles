# shellcheck shell=bash
# Show load averages only when system is loaded (1-min > core count).
# Returns empty when idle → segment is hidden by powerline.

TMUX_POWERLINE_SEG_ALERT_LOAD_ICON_DEFAULT=" "

run_segment() {
	local icon="${TMUX_POWERLINE_SEG_ALERT_LOAD_ICON:-$TMUX_POWERLINE_SEG_ALERT_LOAD_ICON_DEFAULT}"

	# shellcheck source=../helpers/alert_helpers.sh
	source "${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/helpers/alert_helpers.sh"

	local load cores
	load=$(uptime | sed 's/.*load average[s]*: *\([0-9.]*\).*/\1/')
	cores=$(tp_cpu_count)

	if echo "$load > $cores" | bc -l | grep -q '^1'; then
		local averages
		averages=$(uptime | sed 's/.*load average[s]*: *//')
		echo "${icon}${averages}"
		return 0
	fi

	return 0
}
