# shellcheck shell=bash
# Show disk usage only when root filesystem is above 85%.
# Returns empty when normal → segment is hidden by powerline.

TMUX_POWERLINE_SEG_ALERT_DISK_ICON_DEFAULT=" "

run_segment() {
	local icon="${TMUX_POWERLINE_SEG_ALERT_DISK_ICON:-$TMUX_POWERLINE_SEG_ALERT_DISK_ICON_DEFAULT}"
	local pct
	pct=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

	if [ "$pct" -ge 85 ] 2>/dev/null; then
		echo "${icon}${pct}%"
		return 0
	fi

	return 0
}
