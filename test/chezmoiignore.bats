#!/usr/bin/env bats

load test_helper

# Asserting on the rendered .chezmoiignore text is not enough: patterns are
# matched against the *target* path, so a pattern naming a source attribute
# ("private_Library/**") renders fine and matches nothing. These tests ask
# chezmoi which entries it would actually manage.
managed_for() {
	local os="$1"

	chezmoi managed --config "$(chezmoi_config "$os")" --destination "$TEST_HOME_DIR"
}

@test "macOS-only entries are excluded on linux" {
	run managed_for linux
	[ "$status" -eq 0 ]

	[[ "$output" != *"Library/LaunchAgents"* ]]
	[[ "$output" != *"Library/Application Support"* ]]
}

@test "macOS-only entries are managed on darwin" {
	run managed_for darwin
	[ "$status" -eq 0 ]

	[[ "$output" == *"Library/LaunchAgents/net.ivyevans.qmd-mcp.plist"* ]]
}

@test "systemd user units are excluded on darwin" {
	run managed_for darwin
	[ "$status" -eq 0 ]

	[[ "$output" != *".config/systemd"* ]]
}

@test "systemd user units are managed on linux" {
	run managed_for linux
	[ "$status" -eq 0 ]

	[[ "$output" == *".config/systemd/user/qmd-mcp.service"* ]]
	[[ "$output" == *".config/systemd/user/qmd-reindex.timer"* ]]
	[[ "$output" == *".config/systemd/user/cbm-reindex.timer"* ]]
}
