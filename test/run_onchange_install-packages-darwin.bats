#!/usr/bin/env bats

load test_helper

@test "packages.yaml file is valid YAML" {
  # Test that our actual packages.yaml file is valid YAML
  local packages_file="home/.chezmoidata/packages.yaml"

  # Check if the file exists
  [ -f "$packages_file" ]

  # Test YAML syntax validity
  assert_valid_yaml "$packages_file"
}

@test "packages.yaml has the structure our script expects" {
  # Test that our packages.yaml has the structure our script needs
  local packages_file="home/.chezmoidata/packages.yaml"

  # Check if the file exists
  [ -f "$packages_file" ]

  # Test that it has the structure our script expects
  # Should have packages.darwin structure (our script references .packages.darwin.brews)
  run yq '.packages.darwin' "$packages_file"
  [ "$status" -eq 0 ]

  # Should have brews array (our script references .packages.darwin.brews)
  run yq '.packages.darwin.brews' "$packages_file"
  [ "$status" -eq 0 ]

  # Should have casks array (our script references .packages.darwin.casks)
  run yq '.packages.darwin.casks' "$packages_file"
  [ "$status" -eq 0 ]

  # Should have mas array (our script references .packages.darwin.mas)
  run yq '.packages.darwin.mas' "$packages_file"
  [ "$status" -eq 0 ]
}

@test "renders correctly on darwin with packages" {
  # Test our ACTUAL script with our ACTUAL packages data
  local script_file="home/run_onchange_install-packages-darwin.sh.tmpl"

  # Create config with our actual data
  cat >"$TEST_TMPDIR/real-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { darwin = { brews = [], casks = ["font-fira-code-nerd-font"], mas = ["409183694"] } }
EOF

  # Render our actual script
  run chezmoi execute-template --config "$TEST_TMPDIR/real-config.toml" --file "$script_file"
  [ "$status" -eq 0 ]

  # Test our script's behavior:
  # 1. Should be a valid shell script
  assert_script_structure "$output"

  # 2. Should check for Homebrew availability
  [[ "$output" == *"command -v brew"* ]]

  # 3. Should use brew bundle to install packages
  [[ "$output" == *"brew bundle"* ]]

  # 4. Should contain our actual package
  [[ "$output" == *"font-fira-code-nerd-font"* ]]

  # 5. Should handle missing Homebrew gracefully
  [[ "$output" == *"Homebrew not found"* ]]
  [[ "$output" == *"exit 0"* ]]

  # 6. Should install Mac App Store apps
  [[ "$output" == *"Installing Mac App Store apps"* ]]
  [[ "$output" == *"mas install 409183694"* ]]
}

@test "does not render on non-darwin systems" {
  # Test our ACTUAL script on non-darwin systems
  local script_file="home/run_onchange_install-packages-darwin.sh.tmpl"

  # Create config with linux OS
  cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { darwin = { brews = [], casks = ["font-fira-code-nerd-font"], mas = ["409183694"] } }
EOF

  # Render our actual script on linux
  run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$script_file"
  [ "$status" -eq 0 ]

  # Should be empty on non-darwin
  [ "$output" = "" ]
}

@test "produces valid shell syntax" {
  # Test that our ACTUAL script renders to valid shell syntax
  local script_file="home/run_onchange_install-packages-darwin.sh.tmpl"

  # Create config with our actual data
  cat >"$TEST_TMPDIR/syntax-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

  # Add our actual packages data
  cat >>"$TEST_TMPDIR/syntax-config.toml" <<EOF
    packages = { darwin = { brews = [], casks = ["font-fira-code-nerd-font"], mas = ["409183694"] } }
EOF

  # Render our actual script
  run chezmoi execute-template --config "$TEST_TMPDIR/syntax-config.toml" --file "$script_file"
  [ "$status" -eq 0 ]

  # Test that the rendered script has valid shell syntax
  assert_valid_shell "$output"
}

@test "handles empty mas section gracefully" {
  # Test that the script handles empty mas section without errors
  local script_file="home/run_onchange_install-packages-darwin.sh.tmpl"

  # Create config with empty mas section
  cat >"$TEST_TMPDIR/empty-mas-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { darwin = { brews = [], casks = [], mas = [] } }
EOF

  # Render our actual script
  run chezmoi execute-template --config "$TEST_TMPDIR/empty-mas-config.toml" --file "$script_file"
  [ "$status" -eq 0 ]

  # Should still be valid shell syntax
  assert_valid_shell "$output"

  # Should not contain mas install commands when empty
  [[ "$output" != *"mas install"* ]]
}
