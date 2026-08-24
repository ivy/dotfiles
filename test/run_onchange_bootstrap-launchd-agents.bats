#!/usr/bin/env bats

load test_helper

SCRIPT="home/run_onchange_after_bootstrap-launchd-agents.sh.tmpl"

@test "renders valid shell on darwin" {
	run chezmoi execute-template --config "$(chezmoi_config darwin)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
	assert_valid_shell "$output"
}

@test "bootstraps every launchd agent" {
	run chezmoi execute-template --config "$(chezmoi_config darwin)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"net.ivyevans.qmd-reindex"* ]]
	[[ "$output" == *"net.ivyevans.qmd-mcp"* ]]
	[[ "$output" == *"net.ivyevans.cbm-reindex"* ]]
	[[ "$output" == *"launchctl bootstrap"* ]]
	# Boots the old job out first so a running agent picks up a changed plist.
	[[ "$output" == *"launchctl bootout"* ]]
}

@test "embeds every plist hash so a change to any of them re-runs it" {
	run chezmoi execute-template --config "$(chezmoi_config darwin)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"reindex plist hash:"* ]]
	[[ "$output" == *"mcp plist hash:"* ]]
	[[ "$output" == *"cbm reindex plist hash:"* ]]
}

@test "creates the log directory launchd will not create itself" {
	run chezmoi execute-template --config "$(chezmoi_config darwin)" --file "$SCRIPT"
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
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[ "$output" = "" ]
}
