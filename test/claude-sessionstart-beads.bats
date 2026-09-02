#!/usr/bin/env bats

load test_helper

SRC_LIBEXEC="${BATS_TEST_DIRNAME}/../home/dot_local/libexec"

# The wrapper resolves bd from PATH, then falls back to $HOME's mise shim, so both
# lookups must be controllable. SANDBOX goes first on PATH and doubles as a fake HOME
# whose shim directory the tests populate (or leave empty) per case. Symlinking rather
# than copying keeps the suite testing the real source file.
setup() {
	SANDBOX="$(mktemp -d)"
	ln -s "${SRC_LIBEXEC}/executable_claude-sessionstart-beads" "${SANDBOX}/claude-sessionstart-beads"
	WRAPPER="${SANDBOX}/claude-sessionstart-beads"
	mkdir -p "${SANDBOX}/bin" "${SANDBOX}/.local/share/mise/shims"
}

teardown() {
	rm -rf "${SANDBOX}"
}

# A stub `bd` emitting the SessionStart envelope bd prime --hook-json produces.
stub_bd() {
	local dir="$1"
	cat >"${dir}/bd" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "prime" ] || exit 64
jq -cn '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:"BEADS CONTEXT"}}'
EOF
	chmod +x "${dir}/bd"
}

# A stub `bd` that is present but fails, standing in for a wedged workspace.
stub_bd_broken() {
	local dir="$1"
	printf '#!/usr/bin/env bash\necho "boom" >&2\nexit 1\n' >"${dir}/bd"
	chmod +x "${dir}/bd"
}

# Run with PATH and HOME both confined to the sandbox, so no real bd or shim leaks in.
run_wrapper() {
	env -i HOME="${SANDBOX}" PATH="${SANDBOX}/bin:/usr/bin:/bin" bash "${WRAPPER}"
}

@test "emits bd's SessionStart envelope when bd is on PATH" {
	stub_bd "${SANDBOX}/bin"
	local out
	out="$(run_wrapper)"
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.hookEventName')" = "SessionStart" ]
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.additionalContext')" = "BEADS CONTEXT" ]
}

@test "falls back to the mise shim when bd is not on PATH" {
	# PATH lookup must miss and the shim must be used: hooks are not guaranteed a
	# PATH carrying mise shims.
	stub_bd "${SANDBOX}/.local/share/mise/shims"
	local out
	out="$(run_wrapper)"
	[ "$(printf '%s' "${out}" | jq -r '.hookSpecificOutput.additionalContext')" = "BEADS CONTEXT" ]
}

@test "exits 0 and silently when bd is not installed at all" {
	# Neither PATH nor shim provides bd. A non-zero SessionStart hook puts its stderr
	# in front of the user, so absence must contribute nothing instead of failing.
	run run_wrapper
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "exits 0 and swallows stderr when bd fails" {
	stub_bd_broken "${SANDBOX}/bin"
	run run_wrapper
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "registers no PreCompact hook in the settings syncer" {
	# PreCompact stdout becomes custom compact instructions, so priming there would
	# corrupt the prompt that decides what survives compaction. Guard against a
	# well-meaning future edit adding one. Comment lines are stripped first so the
	# assertion is about code, and does not break when the rationale is reworded.
	run bash -c "grep -v '^[[:space:]]*#' '${BATS_TEST_DIRNAME}/../bin/sync-claude-settings' | grep -n 'PreCompact'"
	[ "$status" -ne 0 ]
}
