#!/usr/bin/env bats

load test_helper

SRC_LIBEXEC="${BATS_TEST_DIRNAME}/../home/dot_local/libexec"

# Mirror the installed layout in a temp dir: the wrapper resolves its guard sibling
# by DEST name (block-adhoc-installers), so symlink both there under their installed
# names. Symlinks (not copies) keep the suite testing the real source files.
setup() {
	SANDBOX="$(mktemp -d)"
	ln -s "${SRC_LIBEXEC}/executable_claude-bash-pretooluse" "${SANDBOX}/claude-bash-pretooluse"
	ln -s "${SRC_LIBEXEC}/executable_block-adhoc-installers" "${SANDBOX}/block-adhoc-installers"
	WRAPPER="${SANDBOX}/claude-bash-pretooluse"
}

teardown() {
	rm -rf "${SANDBOX}"
}

# A stub `rtk` that shadows any real install (SANDBOX goes first on PATH) and echoes
# a recognizable rewrite, so the rewrite path is deterministic and hermetic.
stub_rtk() {
	cat >"${SANDBOX}/rtk" <<'EOF'
#!/usr/bin/env bash
cmd="$(jq -r '.tool_input.command // empty')"
jq -cn --arg c "rtk ${cmd}" \
	'{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:{command:$c}}}'
EOF
	chmod +x "${SANDBOX}/rtk"
}

# A stub `rtk` that is present but broken: no output, non-zero exit.
stub_rtk_broken() {
	printf '#!/usr/bin/env bash\nexit 1\n' >"${SANDBOX}/rtk"
	chmod +x "${SANDBOX}/rtk"
}

run_wrapper() {
	jq -cn --arg c "$1" '{tool_input: {command: $c}}' |
		PATH="${SANDBOX}:${PATH}" bash "${WRAPPER}"
}

@test "installer command is denied and never rewritten" {
	stub_rtk
	local out
	out="$(run_wrapper 'pip install requests')"
	# Guard wins outright: deny decision, and rtk's rewrite never leaks through.
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.permissionDecision')" = "deny" ]
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.updatedInput.command // "none"')" = "none" ]
}

@test "deny reason still redirects to /install" {
	stub_rtk
	local out
	out="$(run_wrapper 'npx cowsay')"
	[[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.permissionDecisionReason')" == *"/install"* ]]
}

@test "non-installer command is handed to rtk for rewrite" {
	stub_rtk
	local out
	out="$(run_wrapper 'git status')"
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.updatedInput.command')" = "rtk git status" ]
}

@test "fails open when rtk is broken or unavailable" {
	# rtk present but broken (and, equivalently, the absent case: command -v fails).
	# A non-installer must defer with empty output, never block the shell.
	stub_rtk_broken
	local out
	out="$(run_wrapper 'git status')"
	[ -z "${out}" ]
}

@test "CLAUDE_DISABLE_RTK skips the rewrite but the guard still fires" {
	stub_rtk
	local out
	# Rewrite disabled: a non-installer defers (rtk never invoked).
	out="$(jq -cn --arg c 'git status' '{tool_input:{command:$c}}' |
		CLAUDE_DISABLE_RTK=1 PATH="${SANDBOX}:${PATH}" bash "${WRAPPER}")"
	[ -z "${out}" ]
	# Guard remains active even with the rewrite disabled.
	out="$(jq -cn --arg c 'npx cowsay' '{tool_input:{command:$c}}' |
		CLAUDE_DISABLE_RTK=1 PATH="${SANDBOX}:${PATH}" bash "${WRAPPER}")"
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.permissionDecision')" = "deny" ]
}
