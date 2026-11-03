#!/usr/bin/env bats

load test_helper

@test "renders correctly and produces valid shell syntax" {
	# Test our ACTUAL script renders to valid shell syntax
	local script_file="home/run_onchange_before_10-install-mise-tools.sh.tmpl"

	# Render our actual script (no template variables needed for this script)
	run chezmoi execute-template --file "$script_file"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
}

@test "puts the config and lockfile in place before installing" {
	local script_file="home/run_onchange_before_10-install-mise-tools.sh.tmpl"

	run chezmoi execute-template --file "$script_file"
	[ "$status" -eq 0 ]

	local config_line lock_line install_line
	config_line="$(grep -n 'install -m 0644 .*config.toml' <<<"$output" | cut -d: -f1)"
	lock_line="$(grep -n 'ln -sfn .*mise.lock' <<<"$output" | cut -d: -f1)"
	install_line="$(grep -n '^mise install' <<<"$output" | cut -d: -f1)"

	[ -n "$config_line" ]
	[ -n "$lock_line" ]
	[ "$config_line" -lt "$install_line" ]
	[ "$lock_line" -lt "$install_line" ]
}
