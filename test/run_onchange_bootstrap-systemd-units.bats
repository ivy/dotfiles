#!/usr/bin/env bats

load test_helper

SCRIPT="home/run_onchange_after_bootstrap-systemd-units.sh.tmpl"

@test "renders valid shell on linux" {
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
	assert_valid_shell "$output"
}

@test "bootstraps every installable unit" {
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"qmd-mcp.service"* ]]
	[[ "$output" == *"qmd-reindex.timer"* ]]
	[[ "$output" == *"cbm-reindex.timer"* ]]
	[[ "$output" == *"systemctl --user daemon-reload"* ]]
	# reenable rewrites the [Install] symlinks; restart is what makes a running
	# unit pick up an edited file.
	[[ "$output" == *"systemctl --user reenable"* ]]
	[[ "$output" == *"systemctl --user restart"* ]]
}

# The oneshot services carry no [Install] section and are pulled in by their
# timers. Enabling them directly would also run them once at every login.
@test "does not enable the timer-driven services directly" {
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" != *"qmd-reindex.service"* ]]
	[[ "$output" != *"cbm-reindex.service"* ]]
}

@test "embeds every unit hash so a change to any of them re-runs it" {
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"qmd mcp unit hash:"* ]]
	[[ "$output" == *"qmd reindex unit hash:"* ]]
	[[ "$output" == *"qmd reindex timer hash:"* ]]
	[[ "$output" == *"cbm reindex unit hash:"* ]]
	[[ "$output" == *"cbm reindex timer hash:"* ]]
}

# A container built with `chezmoi init --apply` has no user manager to talk to,
# and failing here would fail the whole apply.
@test "skips when there is no systemd user instance" {
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"systemctl --user show-environment"* ]]
	[[ "$output" == *"skipping unit bootstrap"* ]]
	[[ "$output" == *"exit 0"* ]]
}

# Without lingering the user manager dies at logout, which is exactly when an
# unattended reindex is wanted. Reported, not enabled: enable-linger can raise a
# polkit prompt and block the apply on an auth dialog.
@test "warns when lingering is off rather than enabling it" {
	run chezmoi execute-template --config "$(chezmoi_config linux)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"Linger"* ]]
	[[ "$output" == *"loginctl enable-linger"* ]]
}

# chezmoi applies entries in case-sensitive name order, so this script's target
# name has to sort after ".config/" — otherwise it runs before the units are
# written and finds nothing to load.
@test "target name sorts after .config so the units exist when it runs" {
	local target first
	target="$(basename "$SCRIPT" .sh.tmpl)"
	target="${target#run_onchange_after_}"

	first="$(printf '%s\n.config/\n' "$target" | LC_ALL=C sort | head -1)"
	[ "$first" = ".config/" ]
}

@test "does not render on darwin" {
	run chezmoi execute-template --config "$(chezmoi_config darwin)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[ "$output" = "" ]
}
