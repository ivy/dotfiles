#!/usr/bin/env bats

# Tests for .claude/hooks/encourage-source-dir.sh
# Uses controlled HOME and CLAUDE_PROJECT_DIR with temp directories.

setup() {
	TEST_TMPDIR=$(mktemp -d)
	export HOME="$TEST_TMPDIR/fakehome"
	export CLAUDE_PROJECT_DIR="$TEST_TMPDIR/fakehome/src/dotfiles"
	HOOK_SCRIPT="$BATS_TEST_DIRNAME/../.claude/hooks/encourage-source-dir.sh"
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
	run "$HOOK_SCRIPT" <<<"$1"
}

# --- Write/Edit/MultiEdit: warn when targeting ~/ ---

@test "Edit to ~/file warns with additionalContext" {
	run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
	[ "$status" -eq 0 ]
	echo "$output" | jq -e '.additionalContext | contains("chezmoi source-path")'
	# Should NOT contain a deny decision
	! echo "$output" | jq -e '.hookSpecificOutput' 2>/dev/null
}

@test "Write to ~/.config/ warns with additionalContext" {
	run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.config/ghostty/config\"}}"
	[ "$status" -eq 0 ]
	echo "$output" | jq -e '.additionalContext | contains("chezmoi source-path")'
	! echo "$output" | jq -e '.hookSpecificOutput' 2>/dev/null
}

@test "MultiEdit to ~/file warns with additionalContext" {
	run_hook "{\"tool_name\":\"MultiEdit\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
	[ "$status" -eq 0 ]
	echo "$output" | jq -e '.additionalContext | contains("chezmoi source-path")'
	! echo "$output" | jq -e '.hookSpecificOutput' 2>/dev/null
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

# --- ~/.claude/ is exempt (Claude Code workspace) ---

@test "Write to ~/.claude/plans/ is allowed" {
	mkdir -p "$HOME/.claude/plans"
	run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.claude/plans/some-plan.md\"}}"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Edit to ~/.claude/memory/ is allowed" {
	mkdir -p "$HOME/.claude/memory"
	run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$HOME/.claude/memory/MEMORY.md\"}}"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Read ~/.claude/ file has no warning" {
	mkdir -p "$HOME/.claude"
	touch "$HOME/.claude/settings.json"
	run_hook "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$HOME/.claude/settings.json\"}}"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# --- Warning message includes target path ---

@test "Warning message includes the target path" {
	run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$HOME/.zshrc\"}}"
	[ "$status" -eq 0 ]
	echo "$output" | jq -r '.additionalContext' | grep -q '.zshrc'
}
