#!/usr/bin/env bats

# Tests for .claude/hooks/enforce-source-dir.sh
# Uses controlled HOME and CLAUDE_PROJECT_DIR with temp directories.

setup() {
  TEST_TMPDIR=$(mktemp -d)
  export HOME="$TEST_TMPDIR/fakehome"
  export CLAUDE_PROJECT_DIR="$TEST_TMPDIR/fakehome/src/dotfiles"
  HOOK_SCRIPT="$BATS_TEST_DIRNAME/../.claude/hooks/enforce-source-dir.sh"
  mkdir -p "$HOME/.config/ghostty"
  mkdir -p "$CLAUDE_PROJECT_DIR/home"
  touch "$HOME/.zshrc"
  touch "$HOME/.config/ghostty/config"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Helper: run the hook with a JSON payload
run_hook() {
  run "$HOOK_SCRIPT" <<< "$1"
}

# --- Write/Edit/MultiEdit: deny when targeting ~/ ---

@test "Edit to ~/file is denied" {
  run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"'
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecisionReason | contains("chezmoi source-path")'
}

@test "Write to ~/.config/ is denied" {
  run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.config/ghostty/config\"}}"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"'
}

@test "MultiEdit to ~/file is denied" {
  run_hook "{\"tool_name\":\"MultiEdit\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"'
}

# --- Write/Edit: allow when targeting project dir ---

@test "Edit to project file is allowed" {
  run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$CLAUDE_PROJECT_DIR/home/dot_zshrc\"}}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Write/Edit: allow when targeting outside $HOME ---

@test "Edit to /tmp file is allowed" {
  run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"/tmp/scratch.txt\"}}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Read: soft warn when targeting ~/ ---

@test "Read ~/file returns additionalContext warning" {
  run_hook "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.additionalContext | contains("chezmoi source-path")'
  # Should NOT contain a deny decision
  ! echo "$output" | jq -e '.hookSpecificOutput' 2>/dev/null
}

# --- Read: allow when targeting project dir ---

@test "Read project file is allowed" {
  run_hook "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$CLAUDE_PROJECT_DIR/home/dot_zshrc\"}}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Bash: soft warn when referencing ~/ ---

@test "Bash with home reference returns additionalContext warning" {
  run_hook "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"cat $HOME/.zshrc\"}}"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.additionalContext | contains("chezmoi source-path")'
}

# --- Bash: chezmoi commands are exempt ---

@test "Bash chezmoi command is exempt" {
  run_hook '{"tool_name":"Bash","tool_input":{"command":"chezmoi diff"}}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Bash chezmoi with env vars is exempt" {
  run_hook '{"tool_name":"Bash","tool_input":{"command":"DEBUG=1 chezmoi apply"}}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "Bash chezmoi with multiple env vars is exempt" {
  run_hook '{"tool_name":"Bash","tool_input":{"command":"DEBUG=1 VERBOSE=1 chezmoi status"}}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Bash: no home reference is allowed ---

@test "Bash with no home reference is allowed" {
  run_hook '{"tool_name":"Bash","tool_input":{"command":"ls /tmp"}}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Deny message includes target path ---

@test "Deny message includes the target path" {
  run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
  [ "$status" -eq 0 ]
  echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q '.zshrc'
}
