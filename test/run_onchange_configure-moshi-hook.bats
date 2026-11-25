#!/usr/bin/env bats

load test_helper

SCRIPT="home/run_onchange_before_20-configure-moshi-hook.sh.tmpl"

@test "renders valid shell on linux and darwin" {
	local os
	for os in linux darwin; do
		run chezmoi execute-template --config "$(chezmoi_config "$os" true)" --file "$SCRIPT"
		[ "$status" -eq 0 ]

		assert_script_structure "$output"
		assert_valid_shell "$output"
	done
}

# Elsewhere the binary is installed but nothing runs it, so there is nothing to
# configure or restart.
@test "renders nothing where Moshi is not enabled" {
	local os
	for os in linux darwin; do
		run chezmoi execute-template --config "$(chezmoi_config "$os")" --file "$SCRIPT"
		[ "$status" -eq 0 ]
		[ -z "$output" ]
	done
}

# Left on its default, the daemon downloads new releases over the mise install
# in place, behind mise.lock's back.
@test "turns off the daemon's self-updater" {
	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"set auto-update off"* ]]
}

# Claude Code's hooks go through bin/sync-claude-settings, which owns its
# settings.json; the other agents have no other writer.
@test "installs hooks for codex and opencode but not claude" {
	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"install --target codex,opencode"* ]]
	[[ "$output" != *"--target claude"* ]]
}

# The locked version is what makes chezmoi re-run the script on an upgrade.
@test "embeds the locked moshi-hook version" {
	local version
	version="$(yq -p toml '.tools."http:moshi-hook"[0].version' home/dot_config/mise/mise.lock)"
	[ -n "$version" ]

	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"moshi-hook version: ${version}"* ]]
}

# Resolved at runtime rather than with lookPath, because mise installs
# moshi-hook during the same apply.
@test "skips gracefully when moshi-hook is not installed" {
	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"mise which moshi-hook"* ]]
	[[ "$output" == *"exit 0"* ]]
}

@test "restarts a running daemon through the platform's service manager" {
	run chezmoi execute-template --config "$(chezmoi_config linux true)" --file "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"systemctl --user is-active --quiet moshi-hook.service"* ]]
	[[ "$output" == *"systemctl --user restart moshi-hook.service"* ]]
	[[ "$output" != *"launchctl"* ]]

	run chezmoi execute-template --config "$(chezmoi_config darwin true)" --file "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"launchctl kickstart -k"* ]]
	[[ "$output" == *"app.getmoshi.moshi-hook"* ]]
	[[ "$output" != *"systemctl"* ]]
}

# The service files point at the mise shim. The path `moshi-hook service
# install` would write names a versioned install that `mise prune` deletes.
@test "service files run the mise shim, not a versioned install" {
	grep -q 'ExecStart=%h/.local/share/mise/shims/moshi-hook serve' \
		home/dot_config/systemd/user/moshi-hook.service

	run chezmoi execute-template --config "$(chezmoi_config darwin true)" \
		--file home/private_Library/LaunchAgents/app.getmoshi.moshi-hook.plist.tmpl
	[ "$status" -eq 0 ]
	[[ "$output" == *"/.local/share/mise/shims/moshi-hook</string>"* ]]
}
