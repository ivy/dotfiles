#!/usr/bin/env bats

load test_helper

SCRIPT="home/run_onchange_after_00-pull-qmd-models.sh.tmpl"

@test "renders valid shell syntax" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
	assert_valid_shell "$output"
}

@test "pulls the models" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"qmd pull"* ]]
}

# The image build runs `chezmoi init --apply`; without this guard it would bake
# ~2.2GB of GGUF models into the container.
@test "skips in containers" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *'${CONTAINER:-}'* ]]
	[[ "$output" == *"/.dockerenv"* ]]
	[[ "$output" == *"skipping qmd model download"* ]]
	[[ "$output" == *"exit 0"* ]]
}

# Resolved at runtime rather than with lookPath, because mise installs qmd during
# the same apply and the shim may not exist when this template is rendered.
@test "skips gracefully when qmd is not installed" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"command -v qmd"* ]]
	[[ "$output" == *"qmd not found"* ]]
}

@test "re-runs when the mise config changes" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"mise config hash:"* ]]
}

@test "renders on linux too — models are not darwin-specific" {
	cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"qmd pull"* ]]
}
