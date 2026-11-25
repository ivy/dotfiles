#!/usr/bin/env bats

load test_helper

# Asserting on the rendered .chezmoiignore text is not enough: patterns are
# matched against the *target* path, so a pattern naming a source attribute
# ("private_Library/**") renders fine and matches nothing. These tests ask
# chezmoi which entries it would actually manage.
managed_for() {
	local os="$1" moshi="${2:-false}"

	chezmoi managed --config "$(chezmoi_config "$os" "$moshi")" --destination "$TEST_HOME_DIR"
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
	[[ "$output" == *"Library/Application Support/mbx/config.toml"* ]]
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

@test "mise config and lockfile are left to the install script's symlinks" {
	run managed_for linux
	[ "$status" -eq 0 ]

	[[ "$output" != *".config/mise/config.toml"* ]]
	[[ "$output" != *".config/mise/mise.lock"* ]]
}

# Moshi is opt-in per machine. The failure notifier is not gated: it is best
# effort and a no-op where Moshi isn't paired.
@test "Moshi's daemon and rule are managed only where Moshi is enabled" {
	run managed_for linux
	[ "$status" -eq 0 ]
	[[ "$output" != *".config/systemd/user/moshi-hook.service"* ]]
	[[ "$output" != *".claude/rules/moshi.md"* ]]
	[[ "$output" == *".config/systemd/user/moshi-notify@.service"* ]]

	run managed_for darwin
	[ "$status" -eq 0 ]
	[[ "$output" != *"Library/LaunchAgents/app.getmoshi.moshi-hook.plist"* ]]
	[[ "$output" != *".claude/rules/moshi.md"* ]]

	run managed_for linux true
	[ "$status" -eq 0 ]
	[[ "$output" == *".config/systemd/user/moshi-hook.service"* ]]
	[[ "$output" == *".claude/rules/moshi.md"* ]]

	run managed_for darwin true
	[ "$status" -eq 0 ]
	[[ "$output" == *"Library/LaunchAgents/app.getmoshi.moshi-hook.plist"* ]]
}
