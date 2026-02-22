#!/usr/bin/env bash
# stop-lint-and-test.sh — Stop hook for Claude Code
#
# Runs lint and test checks when the agent stops and the working tree is dirty.
# Blocks the stop if either check fails, giving the agent a chance to fix issues.
#
# Only lints files that actually changed (staged + unstaged tracked files),
# avoiding false positives from pre-existing issues in unrelated files.

set -euo pipefail

input=$(cat)

# Prevent infinite loops: if the stop hook is already active, allow the stop
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')
if [[ "$stop_hook_active" == "true" ]]; then
	exit 0
fi

# Collect changed files (staged + unstaged tracked files)
files=()
while IFS= read -r f; do
	files+=("$f")
done < <({ git diff --name-only; git diff --cached --name-only; } | sort -u)

# If no tracked files changed, nothing to check
if [[ ${#files[@]} -eq 0 ]]; then
	exit 0
fi

failures=""

# Run lint only on changed files
lint_output=$(hk fix "${files[@]}" 2>&1) || failures="Lint failed:
${lint_output}
"

# Run tests
test_output=$(bats test/ 2>&1) || failures="${failures}Tests failed:
${test_output}"

if [[ -n "$failures" ]]; then
	jq -n --arg reason "$failures" '{"decision": "block", "reason": $reason}'
else
	exit 0
fi
