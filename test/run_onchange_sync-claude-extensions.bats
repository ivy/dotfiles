#!/usr/bin/env bats

load test_helper

@test "renders correctly and produces valid shell syntax" {
	local script_file="home/run_onchange_sync-claude-extensions.sh.tmpl"

	run chezmoi execute-template --file "$script_file"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
}

@test "invokes the reconciler from the working tree" {
	local script_file="home/run_onchange_sync-claude-extensions.sh.tmpl"

	run chezmoi execute-template --file "$script_file"
	[ "$status" -eq 0 ]

	[[ "$output" == *"bin/sync-claude-extensions"* ]]
}

@test "embeds hashes so it re-runs when reconciler, base, or extras change" {
	local script_file="home/run_onchange_sync-claude-extensions.sh.tmpl"

	run chezmoi execute-template --file "$script_file"
	[ "$status" -eq 0 ]

	[[ "$output" == *"reconciler hash:"* ]]
	[[ "$output" == *"base data hash:"* ]]
	[[ "$output" == *"extras hash:"* ]]
}
