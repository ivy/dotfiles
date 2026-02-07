#!/usr/bin/env bats

load test_helper

@test "private_Library is excluded on non-darwin platforms" {
    local ignore_file="home/.chezmoiignore"

    cp "$ignore_file" "$TEST_SOURCE_DIR/.chezmoiignore"

    # Test on linux - should exclude private_Library/**
    cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

    run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$TEST_SOURCE_DIR/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" == *"private_Library/**"* ]]
}

@test "private_Library is not excluded on darwin" {
    local ignore_file="home/.chezmoiignore"

    cp "$ignore_file" "$TEST_SOURCE_DIR/.chezmoiignore"

    cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

    run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$TEST_SOURCE_DIR/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" != *"private_Library"* ]]
}

@test "ghostty directory is not excluded on linux" {
    local ignore_file="home/.chezmoiignore"

    cp "$ignore_file" "$TEST_SOURCE_DIR/.chezmoiignore"

    cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

    run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$TEST_SOURCE_DIR/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" != *".config/ghostty/**"* ]]
}

@test "ghostty directory is excluded on darwin" {
    local ignore_file="home/.chezmoiignore"

    cp "$ignore_file" "$TEST_SOURCE_DIR/.chezmoiignore"

    cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

    run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$TEST_SOURCE_DIR/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" == *".config/ghostty/**"* ]]
}
