#!/usr/bin/env bats

# Test helper for chezmoi brew bundle tests
# This file is automatically loaded by bats

# Setup function that runs before each test
setup() {
  # Create temporary directories for testing
  export TEST_TMPDIR=$(mktemp -d)
  export TEST_SOURCE_DIR="$TEST_TMPDIR/source"
  export TEST_HOME_DIR="$TEST_TMPDIR/home"

  mkdir -p "$TEST_SOURCE_DIR"
  mkdir -p "$TEST_HOME_DIR"

  # Set up test environment variables
  export CHEZMOI_SOURCE_DIR="$TEST_SOURCE_DIR"
  export CHEZMOI_HOME_DIR="$TEST_HOME_DIR"
}

# Teardown function that runs after each test
teardown() {
  # Clean up temporary directories
  rm -rf "$TEST_TMPDIR"
}

# Helper function to assert valid YAML
assert_valid_yaml() {
  local file="$1"

  yq '.' "$file" >/dev/null
  [ $? -eq 0 ]
}

# Helper function to assert valid shell syntax
assert_valid_shell() {
  local script="$1"

  # Write script to temporary file for shellcheck
  local temp_script="$TEST_TMPDIR/temp_script.sh"
  echo "$script" >"$temp_script"

  # Test basic syntax with bash -n
  bash -n "$temp_script"
  [ $? -eq 0 ]

  # Test with shellcheck if available
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$temp_script"
    [ $? -eq 0 ]
  fi
}

# Helper function to assert script has proper structure
assert_script_structure() {
  local script="$1"

  # Should start with shebang
  [[ "$script" == *"#!/bin/bash"* ]]

  # Should be syntactically valid
  echo "$script" >"$TEST_TMPDIR/temp.sh"
  bash -n "$TEST_TMPDIR/temp.sh"
  [ $? -eq 0 ]
}
