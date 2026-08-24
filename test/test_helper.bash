#!/usr/bin/env bats

# Test helper for chezmoi brew bundle tests
# This file is automatically loaded by bats

# Setup function that runs before each test
setup() {
	# Create temporary directories for testing
	TEST_TMPDIR=$(mktemp -d)
	export TEST_TMPDIR
	export TEST_SOURCE_DIR="$TEST_TMPDIR/source"
	export TEST_HOME_DIR="$TEST_TMPDIR/home"

	mkdir -p "$TEST_SOURCE_DIR"
	mkdir -p "$TEST_HOME_DIR"

	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export REPO_ROOT

	# Set up test environment variables
	export CHEZMOI_SOURCE_DIR="$TEST_SOURCE_DIR"
	export CHEZMOI_HOME_DIR="$TEST_HOME_DIR"
}

# Teardown function that runs after each test
teardown() {
	# Clean up temporary directories
	rm -rf "$TEST_TMPDIR"
}

# Write a chezmoi config for `execute-template --config` and echo its path.
#
# sourceDir belongs at the top level, not under [data]. Templates that `include`
# a sibling source resolve it against chezmoi's real source directory; a
# .data.chezmoi.sourceDir override does not influence that, so a config without
# this key sends `include` to the default ~/.local/share/chezmoi and fails.
chezmoi_config() {
	local os="$1"
	local path="$TEST_TMPDIR/${os}-config.toml"

	cat >"$path" <<EOF
sourceDir = "$REPO_ROOT"

[data]
    chezmoi = { os = "$os", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF
	printf '%s' "$path"
}

# Helper function to assert valid YAML
assert_valid_yaml() {
	local file="$1"

	yq '.' "$file" >/dev/null
}

# Helper function to assert valid shell syntax
assert_valid_shell() {
	local script="$1"

	# Write script to temporary file for shellcheck
	local temp_script="$TEST_TMPDIR/temp_script.sh"
	echo "$script" >"$temp_script"

	# Test basic syntax with bash -n
	bash -n "$temp_script"

	# Test with shellcheck if available
	if command -v shellcheck >/dev/null 2>&1; then
		shellcheck "$temp_script"
	fi
}

# Helper function to assert script has proper structure
assert_script_structure() {
	local script="$1"

	# Should start with shebang
	[[ "$script" == *"#!/bin/bash"* || "$script" == *"#!/bin/sh"* ]]

	# Should be syntactically valid
	echo "$script" >"$TEST_TMPDIR/temp.sh"
	bash -n "$TEST_TMPDIR/temp.sh"
}
