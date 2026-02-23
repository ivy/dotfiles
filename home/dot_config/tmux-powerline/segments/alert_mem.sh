# shellcheck shell=bash
# Show memory usage only when above 80%.
# Returns empty when normal → segment is hidden by powerline.
# Uses tp_mem_used_percentage_at_least and tp_mem_used_gigabytes from
# tmux-powerline's lib/mem_used_helper.sh (sourced via headers.sh).

TMUX_POWERLINE_SEG_ALERT_MEM_ICON_DEFAULT=" "

run_segment() {
	local icon="${TMUX_POWERLINE_SEG_ALERT_MEM_ICON:-$TMUX_POWERLINE_SEG_ALERT_MEM_ICON_DEFAULT}"

	if [ "$(tp_mem_used_percentage_at_least 80)" = "1" ]; then
		echo "${icon}$(tp_mem_used_gigabytes)G"
		return 0
	fi

	return 0
}
