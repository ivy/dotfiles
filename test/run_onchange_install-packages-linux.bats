#!/usr/bin/env bats

load test_helper

@test "packages.yaml has linux.dnf structure" {
	local packages_file="home/.chezmoidata/packages.yaml"

	[ -f "$packages_file" ]

	# Should have packages.linux structure
	run yq '.packages.linux' "$packages_file"
	[ "$status" -eq 0 ]

	# Should have dnf array
	run yq '.packages.linux.dnf' "$packages_file"
	[ "$status" -eq 0 ]
}

@test "renders correctly on linux with packages" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh", "htop"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should be a valid shell script
	assert_script_structure "$output"

	# Should check for dnf availability
	[[ "$output" == *"command -v dnf"* ]]

	# Should use dnf install
	[[ "$output" == *"dnf install"* ]]

	# Should contain our test packages
	[[ "$output" == *"git"* ]]
	[[ "$output" == *"zsh"* ]]
	[[ "$output" == *"htop"* ]]
}

@test "does not render on non-linux systems" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should be empty on non-linux
	[ "$output" = "" ]
}

@test "produces valid shell syntax" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/syntax-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh", "htop"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/syntax-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	assert_valid_shell "$output"
}

@test "handles empty dnf section gracefully" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/empty-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = [] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/empty-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should still produce valid shell syntax
	assert_valid_shell "$output"

	# Should not contain any package names in the dnf install line
	# (the dnf install command should have no packages listed)
}
