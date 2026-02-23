# shellcheck shell=bash
# Show hostname only in remote (SSH) or container sessions.
# Returns empty when local → segment is hidden by powerline.

TMUX_POWERLINE_SEG_ALERT_HOSTNAME_ICON_DEFAULT=" "

run_segment() {
	local icon="${TMUX_POWERLINE_SEG_ALERT_HOSTNAME_ICON:-$TMUX_POWERLINE_SEG_ALERT_HOSTNAME_ICON_DEFAULT}"

	if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CLIENT" ] || [ -f /.dockerenv ]; then
		echo "${icon}$(hostname -s)"
		return 0
	fi
	return 0
}
