# shellcheck shell=bash
# Show hostname only in remote (SSH) or container sessions.
# Returns empty when local → segment is hidden by powerline.

run_segment() {
	if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CLIENT" ] || [ -f /.dockerenv ]; then
		hostname -s
		return 0
	fi
	return 0
}
