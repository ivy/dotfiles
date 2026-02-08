#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2016
# enforce-source-dir.sh — PreToolUse hook for Claude Code
#
# Prevents agents from writing to chezmoi-managed destination files in ~/
# instead of editing source files in the project's home/ directory.
#
# Behavior:
#   Write/Edit/MultiEdit targeting ~/ (outside project) → hard deny
#   Read targeting ~/ (outside project)                  → soft warning
#   Bash referencing ~/ (non-chezmoi command)            → soft warning
#   Everything else                                      → allow (no output)
#
# SC2154: tool_name, file_path, command are assigned by eval
# SC2016: $HOME in single quotes is intentional (grep pattern, not expansion)

set -euo pipefail

# Read hook input from stdin
input=$(cat)

# Extract fields in one jq call
eval "$(echo "$input" | jq -r '
  @sh "tool_name=\(.tool_name // "")",
  @sh "file_path=\(.tool_input.file_path // "")",
  @sh "command=\(.tool_input.command // "")"
')"

# Resolve a file path to its canonical form.
# For existing paths, use realpath. For new files, resolve the parent.
resolve_path() {
	local p="$1"
	if [[ -e "$p" ]]; then
		realpath "$p"
	elif [[ -d "$(dirname "$p")" ]]; then
		echo "$(realpath "$(dirname "$p")")/$(basename "$p")"
	else
		echo "$p"
	fi
}

# Check if a resolved path is under $HOME but NOT under $CLAUDE_PROJECT_DIR
# and NOT under ~/.claude (Claude Code's own workspace: plans, memory, settings)
is_home_not_project() {
	local resolved="$1"
	[[ "$resolved" == "$HOME"/* ]] &&
		[[ "$resolved" != "$CLAUDE_PROJECT_DIR"/* ]] &&
		[[ "$resolved" != "$HOME/.claude"/* ]]
}

case "$tool_name" in
Write | Edit | MultiEdit)
	[[ -z "$file_path" ]] && exit 0
	resolved=$(resolve_path "$file_path")
	if is_home_not_project "$resolved"; then
		jq -n --arg reason "$(
			cat <<MSG
BLOCKED: Do not edit files in ~/ directly. This is a chezmoi-managed dotfiles repo.

To find the correct source file, run:
  chezmoi source-path $resolved

Then edit that source file (under home/ in the project tree), and deploy with:
  chezmoi apply $resolved
MSG
		)" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
	fi
	;;

Read)
	[[ -z "$file_path" ]] && exit 0
	resolved=$(resolve_path "$file_path")
	if is_home_not_project "$resolved"; then
		jq -n --arg ctx "$(
			cat <<MSG
Note: You are reading a chezmoi-managed destination file. This is deployed from
the source tree — do not edit it directly. To find the source file, run:
  chezmoi source-path $resolved
MSG
		)" '{additionalContext: $ctx}'
	fi
	;;

Bash)
	[[ -z "$command" ]] && exit 0

	# Exempt chezmoi commands (strip leading whitespace and env-var assignments)
	stripped=$(echo "$command" | sed 's/^[[:space:]]*//' | sed 's/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]*//')
	# Handle multiple env vars (e.g., DEBUG=1 VERBOSE=1 chezmoi ...)
	while [[ "$stripped" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]] ]]; do
		# shellcheck disable=SC2001 # regex too complex for parameter expansion
		stripped=$(echo "$stripped" | sed 's/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]*//')
	done
	if [[ "$stripped" == chezmoi* ]]; then
		exit 0
	fi

	# Check if command references home directory
	if echo "$command" | grep -qF "$HOME/" ||
		echo "$command" | grep -qE '(~/|\$HOME/)'; then
		jq -n --arg ctx "$(
			cat <<MSG
Note: This command references files in ~/. This is a chezmoi-managed repo — do
not modify files in ~/ directly. To find source files, use:
  chezmoi source-path <target>
MSG
		)" '{additionalContext: $ctx}'
	fi
	;;
esac
