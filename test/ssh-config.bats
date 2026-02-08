#!/usr/bin/env bats

load test_helper

@test "renders macOS 1Password agent on darwin" {
	local config_file="home/private_dot_ssh/private_config.tmpl"

	cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$config_file"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"* ]]
}

@test "renders Linux 1Password agent on linux" {
	local config_file="home/private_dot_ssh/private_config.tmpl"

	cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$config_file"
	[ "$status" -eq 0 ]
	[[ "$output" == *".1password/agent.sock"* ]]
}

@test "does not leak macOS paths to linux" {
	local config_file="home/private_dot_ssh/private_config.tmpl"

	cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$config_file"
	[ "$status" -eq 0 ]
	[[ "$output" != *"Library/Group Containers"* ]]
}

@test "does not leak Linux paths to darwin" {
	local config_file="home/private_dot_ssh/private_config.tmpl"

	cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

	run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$config_file"
	[ "$status" -eq 0 ]
	[[ "$output" != *".1password/agent.sock"* ]]
}
