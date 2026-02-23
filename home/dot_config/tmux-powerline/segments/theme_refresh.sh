#!/bin/sh
# Silent segment — re-applies pane/border theme on each status refresh.
# Outputs nothing; powerline skips empty segments so this is invisible.

run_segment() {
	"$HOME/.local/libexec/dotfiles/tmux-apply-theme" >/dev/null 2>&1
	return 0
}
