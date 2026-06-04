#!/usr/bin/env bats

load test_helper

# Stub `claude` and `chezmoi` on PATH so the reconciler exercises its real logic
# against canned JSON without touching the system. Every claude invocation is
# appended to $CLAUDE_CALLS_LOG; the two read queries emit fixtures.
make_stubs() {
	STUB_BIN="$TEST_TMPDIR/bin"
	mkdir -p "$STUB_BIN"

	cat >"$STUB_BIN/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CLAUDE_CALLS_LOG"
case "$*" in
	"plugin marketplace list --json") cat "$FAKE_MARKETPLACES_JSON" ;;
	"plugin list --json") cat "$FAKE_PLUGINS_JSON" ;;
esac
exit 0
STUB

	cat >"$STUB_BIN/chezmoi" <<'STUB'
#!/usr/bin/env bash
case "$*" in
	"data --format json") cat "$FAKE_DATA_JSON" ;;
esac
exit 0
STUB

	chmod +x "$STUB_BIN/claude" "$STUB_BIN/chezmoi"

	export CLAUDE_CALLS_LOG="$TEST_TMPDIR/calls.log"
	export FAKE_MARKETPLACES_JSON="$TEST_TMPDIR/mkts.json"
	export FAKE_PLUGINS_JSON="$TEST_TMPDIR/plugins.json"
	export FAKE_DATA_JSON="$TEST_TMPDIR/data.json"
	: >"$CLAUDE_CALLS_LOG"

	# Sensible empty defaults; individual tests override.
	printf '%s' '[]' >"$FAKE_MARKETPLACES_JSON"
	printf '%s' '[]' >"$FAKE_PLUGINS_JSON"
	printf '%s' '{"mcpServers":{}}' >"$TEST_HOME_DIR/.claude.json"
}

run_reconciler() {
	run env PATH="${RECONCILER_PATH:-$STUB_BIN:$PATH}" HOME="$TEST_HOME_DIR" GITHUB_TOKEN=test \
		bash "${BATS_TEST_DIRNAME}/../bin/sync-claude-extensions" "$@"
}

@test "adds missing marketplaces and installs missing plugins" {
	make_stubs
	printf '%s' '{"claudeExtensions":{"marketplaces":[{"name":"pickled-claude-plugins","repo":"technicalpickles/pickled-claude-plugins"},{"name":"plannotator","repo":"backnotprop/plannotator"}],"plugins":["playground@claude-plugins-official","ci-cd-tools@pickled-claude-plugins"],"mcpServers":[]}}' >"$FAKE_DATA_JSON"
	printf '%s' '[{"name":"pickled-claude-plugins"}]' >"$FAKE_MARKETPLACES_JSON"
	printf '%s' '[{"id":"playground@claude-plugins-official","scope":"user"}]' >"$FAKE_PLUGINS_JSON"

	run_reconciler
	[ "$status" -eq 0 ]

	grep -qF 'plugin marketplace add backnotprop/plannotator' "$CLAUDE_CALLS_LOG"
	grep -qF 'plugin install ci-cd-tools@pickled-claude-plugins --scope user' "$CLAUDE_CALLS_LOG"
	# Already-present items are not re-added/re-installed.
	! grep -qF 'marketplace add technicalpickles' "$CLAUDE_CALLS_LOG"
	! grep -qF 'plugin install playground' "$CLAUDE_CALLS_LOG"
}

@test "idempotent: nothing missing means no add or install calls" {
	make_stubs
	printf '%s' '{"claudeExtensions":{"marketplaces":[{"name":"pickled-claude-plugins","repo":"technicalpickles/pickled-claude-plugins"}],"plugins":["ci-cd-tools@pickled-claude-plugins"],"mcpServers":[]}}' >"$FAKE_DATA_JSON"
	printf '%s' '[{"name":"pickled-claude-plugins"}]' >"$FAKE_MARKETPLACES_JSON"
	printf '%s' '[{"id":"ci-cd-tools@pickled-claude-plugins","scope":"user"}]' >"$FAKE_PLUGINS_JSON"

	run_reconciler
	[ "$status" -eq 0 ]

	! grep -qF 'marketplace add' "$CLAUDE_CALLS_LOG"
	! grep -qF 'plugin install' "$CLAUDE_CALLS_LOG"
}

@test "--check reports actions but mutates nothing" {
	make_stubs
	printf '%s' '{"claudeExtensions":{"marketplaces":[],"plugins":["ci-cd-tools@pickled-claude-plugins"],"mcpServers":[]}}' >"$FAKE_DATA_JSON"

	run_reconciler --check
	[ "$status" -eq 0 ]

	[[ "$output" == *"would run: claude plugin install ci-cd-tools@pickled-claude-plugins --scope user"* ]]
	! grep -qF 'plugin install ci-cd-tools' "$CLAUDE_CALLS_LOG"
}

@test "adds a missing MCP server with transport and url" {
	make_stubs
	printf '%s' '{"claudeExtensions":{"marketplaces":[],"plugins":[],"mcpServers":[{"name":"context7","transport":"http","url":"https://mcp.context7.example/mcp"}]}}' >"$FAKE_DATA_JSON"

	run_reconciler
	[ "$status" -eq 0 ]

	grep -qF 'mcp add --scope user --transport http context7 https://mcp.context7.example/mcp' "$CLAUDE_CALLS_LOG"
}

@test "merges machine-local extras with the committed base" {
	make_stubs
	printf '%s' '{"claudeExtensions":{"marketplaces":[],"plugins":["a@claude-plugins-official"],"mcpServers":[]},"claudeExtensionsExtra":{"plugins":["internal-plugin@private-marketplace"]}}' >"$FAKE_DATA_JSON"
	printf '%s' '[{"id":"a@claude-plugins-official","scope":"user"}]' >"$FAKE_PLUGINS_JSON"

	run_reconciler
	[ "$status" -eq 0 ]

	grep -qF 'plugin install internal-plugin@private-marketplace --scope user' "$CLAUDE_CALLS_LOG"
}

@test "reports user-scope drift but never touches managed scope" {
	make_stubs
	printf '%s' '{"claudeExtensions":{"marketplaces":[],"plugins":[],"mcpServers":[]}}' >"$FAKE_DATA_JSON"
	printf '%s' '[{"id":"y@pickled-claude-plugins","scope":"user"},{"id":"vendor-tool@private-marketplace","scope":"managed"}]' >"$FAKE_PLUGINS_JSON"

	run_reconciler
	[ "$status" -eq 0 ]

	[[ "$output" == *"drift: plugin y@pickled-claude-plugins"* ]]
	[[ "$output" != *"vendor-tool"* ]]
	! grep -qF 'uninstall' "$CLAUDE_CALLS_LOG"
}

@test "skips cleanly when claude is not on PATH" {
	make_stubs
	# Build a PATH containing only the stubs plus the real tools the script needs,
	# deliberately excluding the directory that holds the real claude binary.
	ln -s "$(command -v bash)" "$STUB_BIN/bash"
	ln -s "$(command -v jq)" "$STUB_BIN/jq"
	ln -s "$(command -v grep)" "$STUB_BIN/grep"
	rm -f "$STUB_BIN/claude"
	printf '%s' '{"claudeExtensions":{"marketplaces":[],"plugins":["x@y"],"mcpServers":[]}}' >"$FAKE_DATA_JSON"

	RECONCILER_PATH="$STUB_BIN" run_reconciler
	[ "$status" -eq 0 ]
	[[ "$output" == *"claude not found"* ]]
}
