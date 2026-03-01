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

@test "packages.yaml has linux.apt structure" {
	local packages_file="home/.chezmoidata/packages.yaml"

	[ -f "$packages_file" ]

	# Should have apt array
	run yq '.packages.linux.apt' "$packages_file"
	[ "$status" -eq 0 ]

	# Should be a non-empty array
	run yq '.packages.linux.apt | length' "$packages_file"
	[ "$status" -eq 0 ]
	[ "$output" -gt 0 ]
}

@test "renders correctly on linux with dnf packages" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh", "htop"], apt = ["git", "zsh", "htop"] } }
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

@test "renders correctly on linux with apt packages" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/apt-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh", "htop"], apt = ["git", "zsh", "htop"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/apt-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should be a valid shell script
	assert_script_structure "$output"

	# Should have apt-get install path
	[[ "$output" == *"apt-get install"* ]]

	# Should have apt-get update
	[[ "$output" == *"apt-get update"* ]]

	# Should contain our test packages in the apt section
	[[ "$output" == *"git"* ]]
	[[ "$output" == *"zsh"* ]]
	[[ "$output" == *"htop"* ]]
}

@test "does not render on non-linux systems" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh"], apt = ["git", "zsh"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should be empty on non-linux
	[ "$output" = "" ]
}

@test "produces valid shell syntax (dnf path)" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/syntax-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh", "htop"], apt = ["git", "zsh", "htop"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/syntax-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	assert_valid_shell "$output"
}

@test "produces valid shell syntax (apt path)" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/apt-syntax-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git", "zsh", "htop"], apt = ["git", "zsh", "htop"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/apt-syntax-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	assert_valid_shell "$output"
}

@test "handles empty dnf section gracefully" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/empty-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = [], apt = ["git"] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/empty-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should still produce valid shell syntax
	assert_valid_shell "$output"
}

@test "handles empty apt section gracefully" {
	local script_file="home/run_onchange_install-packages-linux.sh.tmpl"

	cat >"$TEST_TMPDIR/empty-apt-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
    packages = { linux = { dnf = ["git"], apt = [] } }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/empty-apt-config.toml" --file "$script_file"
	[ "$status" -eq 0 ]

	# Should still produce valid shell syntax
	assert_valid_shell "$output"
}
