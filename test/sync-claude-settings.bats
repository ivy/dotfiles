#!/usr/bin/env bats

load test_helper

# Stub `chezmoi`, `mise`, `moshi-hook` and `herdr` on PATH so the sync runs its
# real jq merges against a throwaway HOME. `mise which moshi-hook` resolves to
# the stub only when $FAKE_MOSHI_INSTALLED is set, and `mise which herdr` only
# when $FAKE_HERDR_INSTALLED is set; every invocation of either is appended to
# $MOSHI_CALLS_LOG or $HERDR_CALLS_LOG.
make_stubs() {
	STUB_BIN="$TEST_TMPDIR/bin"
	mkdir -p "$STUB_BIN"

	cat >"$STUB_BIN/chezmoi" <<'STUB'
#!/usr/bin/env bash
case "$*" in
	"data --format json") printf '{"claude":{"use_bedrock":false},"moshi":{"enabled":%s}}' "${FAKE_MOSHI_ENABLED:-true}" ;;
esac
exit 0
STUB

	cat >"$STUB_BIN/mise" <<STUB
#!/usr/bin/env bash
if [ "\$*" = "which moshi-hook" ] && [ -n "\${FAKE_MOSHI_INSTALLED:-}" ]; then
	printf '%s\n' "$STUB_BIN/moshi-hook"
	exit 0
fi
if [ "\$*" = "which herdr" ] && [ -n "\${FAKE_HERDR_INSTALLED:-}" ]; then
	printf '%s\n' "$STUB_BIN/herdr"
	exit 0
fi
exit 1
STUB

	cat >"$STUB_BIN/moshi-hook" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOSHI_CALLS_LOG"
exit 0
STUB

	cat >"$STUB_BIN/herdr" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$HERDR_CALLS_LOG"
exit 0
STUB

	chmod +x "$STUB_BIN/chezmoi" "$STUB_BIN/mise" "$STUB_BIN/moshi-hook" "$STUB_BIN/herdr"

	export MOSHI_CALLS_LOG="$TEST_TMPDIR/moshi-calls.log"
	: >"$MOSHI_CALLS_LOG"
	export HERDR_CALLS_LOG="$TEST_TMPDIR/herdr-calls.log"
	: >"$HERDR_CALLS_LOG"
}

run_sync() {
	run env PATH="$STUB_BIN:$PATH" HOME="$TEST_HOME_DIR" \
		bash "${BATS_TEST_DIRNAME}/../bin/sync-claude-settings"
}

@test "installs the moshi-hook Claude Code hooks through moshi's own installer" {
	make_stubs
	export FAKE_MOSHI_INSTALLED=1

	run_sync
	[ "$status" -eq 0 ]

	[ "$(cat "$MOSHI_CALLS_LOG")" = "install --target claude" ]
}

# The installer merges into the file the earlier steps wrote, so it has to run
# after them: the installer guard hook must survive alongside moshi's.
@test "installs moshi's hooks after the managed hooks are written" {
	make_stubs
	export FAKE_MOSHI_INSTALLED=1

	run_sync
	[ "$status" -eq 0 ]

	local guard moshi
	guard="$(printf '%s\n' "$output" | grep -n 'installer guard' | cut -d: -f1)"
	moshi="$(printf '%s\n' "$output" | grep -n 'installing moshi-hook' | cut -d: -f1)"
	[ -n "$guard" ] && [ -n "$moshi" ]
	[ "$guard" -lt "$moshi" ]
}

@test "skips the moshi hooks when moshi-hook is not installed" {
	make_stubs
	unset FAKE_MOSHI_INSTALLED

	run_sync
	[ "$status" -eq 0 ]

	[[ "$output" == *"moshi-hook not installed"* ]]
	[ ! -s "$MOSHI_CALLS_LOG" ]
	jq -e '.hooks.PreToolUse | length == 1' "$TEST_HOME_DIR/.claude/settings.json"
}

@test "skips the moshi hooks where Moshi is not enabled" {
	make_stubs
	export FAKE_MOSHI_INSTALLED=1 FAKE_MOSHI_ENABLED=false

	run_sync
	[ "$status" -eq 0 ]

	[[ "$output" == *"moshi.enabled=false"* ]]
	[ ! -s "$MOSHI_CALLS_LOG" ]
}

# Each moshi-hook release generates different hooks, so an upgrade has to
# re-run the sync.
@test "the chezmoi trigger re-runs on a moshi-hook upgrade" {
	local version
	version="$(yq -p toml '.tools."http:moshi-hook"[0].version' home/dot_config/mise/mise.lock)"
	[ -n "$version" ]

	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file home/run_onchange_sync-claude-settings.sh.tmpl
	[ "$status" -eq 0 ]

	[[ "$output" == *"moshi-hook version: ${version}"* ]]
	# Turning Moshi on or off re-runs it too.
	[[ "$output" == *"moshi enabled: true"* ]]
}

@test "installs herdr's Claude Code integration through herdr's own installer" {
	make_stubs
	export FAKE_HERDR_INSTALLED=1

	run_sync
	[ "$status" -eq 0 ]

	[ "$(cat "$HERDR_CALLS_LOG")" = "integration install claude" ]
}

@test "skips the herdr integration when herdr is not installed" {
	make_stubs
	unset FAKE_HERDR_INSTALLED

	run_sync
	[ "$status" -eq 0 ]

	[[ "$output" == *"herdr not installed"* ]]
	[ ! -s "$HERDR_CALLS_LOG" ]
}

# herdr expects its integration reinstalled after each upgrade.
@test "the chezmoi trigger re-runs on a herdr upgrade" {
	local version
	version="$(yq -p toml '.tools."github:herdrdev/herdr"[0].version' home/dot_config/mise/mise.lock)"
	[ -n "$version" ]

	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file home/run_onchange_sync-claude-settings.sh.tmpl
	[ "$status" -eq 0 ]

	[[ "$output" == *"herdr version: ${version}"* ]]
}
