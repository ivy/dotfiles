#!/usr/bin/env bats

load test_helper

SCRIPT="home/run_onchange_after_bootstrap-qmd-launchd-agents.sh.tmpl"

darwin_config() {
	cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF
	printf '%s' "$TEST_TMPDIR/darwin-config.toml"
}

@test "renders valid shell on darwin" {
	run chezmoi execute-template --config "$(darwin_config)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
	assert_valid_shell "$output"
}

@test "bootstraps both qmd agents" {
	run chezmoi execute-template --config "$(darwin_config)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"net.ivyevans.qmd-reindex"* ]]
	[[ "$output" == *"net.ivyevans.qmd-mcp"* ]]
	[[ "$output" == *"launchctl bootstrap"* ]]
	# Boots the old job out first so a running agent picks up a changed plist.
	[[ "$output" == *"launchctl bootout"* ]]
}

@test "embeds both plist hashes so a change to either re-runs it" {
	run chezmoi execute-template --config "$(darwin_config)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"reindex plist hash:"* ]]
	[[ "$output" == *"mcp plist hash:"* ]]
}

@test "creates the log directory launchd will not create itself" {
	run chezmoi execute-template --config "$(darwin_config)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"mkdir -p"* ]]
	[[ "$output" == *"Library/Logs"* ]]
}

# chezmoi applies entries in case-sensitive name order, so this script's target
# name has to sort after "Library/" — otherwise it runs before the plists are
# written and finds nothing to load. A numeric prefix silently breaks this.
@test "target name sorts after Library so the plists exist when it runs" {
	local target first
	target="$(basename "$SCRIPT" .sh.tmpl)"
	target="${target#run_onchange_after_}"

	first="$(printf '%s\nLibrary/\n' "$target" | LC_ALL=C sort | head -1)"
	[ "$first" = "Library/" ]
}

@test "does not render on non-darwin systems" {
	cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[ "$output" = "" ]
}
