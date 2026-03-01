#!/usr/bin/env bats

# Tests for global git hooks via core.hooksPath + hk global config.
# Verifies that secrets are blocked in ANY repo without per-repo setup.

setup() {
	TEST_TMPDIR=$(mktemp -d)
	export TEST_TMPDIR
}

teardown() {
	rm -rf "$TEST_TMPDIR"
}

# --- Static: git config sets core.hooksPath ---

@test "git config template includes core.hooksPath" {
	run chezmoi execute-template --file home/dot_config/git/config.tmpl
	[ "$status" -eq 0 ]
	[[ "$output" == *"hooksPath = ~/.config/git/hooks"* ]]
}

# --- Static: pre-commit hook is valid and invokes hk ---

@test "pre-commit hook has a shebang" {
	run head -1 home/dot_config/git/hooks/executable_pre-commit
	[[ "$output" == "#!/bin/sh" ]]
}

@test "pre-commit hook invokes hk via hardcoded path" {
	run grep -c '.local/bin/hk.*run pre-commit' home/dot_config/git/hooks/executable_pre-commit
	[ "$status" -eq 0 ]
}

@test "pre-commit hook passes through arguments" {
	run cat home/dot_config/git/hooks/executable_pre-commit
	[[ "$output" == *'"$@"'* ]]
}

# --- Static: hk global config defines gitleaks step ---

@test "hk config.pkl evaluates without errors" {
	run pkl eval -f json home/dot_config/hk/config.pkl
	[ "$status" -eq 0 ]
}

@test "hk config.pkl has a pre-commit hook" {
	run pkl eval -f json home/dot_config/hk/config.pkl
	[ "$status" -eq 0 ]
	echo "$output" | jq -e '.hooks["pre-commit"]'
}

@test "hk config.pkl has a gitleaks step in pre-commit" {
	run pkl eval -f json home/dot_config/hk/config.pkl
	[ "$status" -eq 0 ]
	echo "$output" | jq -e '.hooks["pre-commit"].steps.gitleaks'
}

@test "gitleaks step runs 'gitleaks protect --staged'" {
	run pkl eval -f json home/dot_config/hk/config.pkl
	[ "$status" -eq 0 ]
	local check
	check=$(echo "$output" | jq -r '.hooks["pre-commit"].steps.gitleaks.check')
	[ "$check" = "gitleaks protect --staged" ]
}

# --- Integration: secrets are blocked in a fresh repo ---

@test "committing a private key is blocked" {
	# Create an isolated git repo with no per-repo hk setup
	local repo="$TEST_TMPDIR/repo"
	git init "$repo"
	git -C "$repo" config user.email "test@test.com"
	git -C "$repo" config user.name "Test"
	git -C "$repo" config core.hooksPath "$HOME/.config/git/hooks"

	# Generate a private key and stage it
	ssh-keygen -t rsa -N '' -f "$repo/id_rsa" -q
	git -C "$repo" add .

	# Commit must fail — hk should block it
	run git -C "$repo" commit -m "oops"
	[ "$status" -ne 0 ]
}

@test "committing normal files succeeds" {
	# Ensure we haven't broken normal commits
	local repo="$TEST_TMPDIR/repo"
	git init "$repo"
	git -C "$repo" config user.email "test@test.com"
	git -C "$repo" config user.name "Test"
	git -C "$repo" config core.hooksPath "$HOME/.config/git/hooks"

	echo "hello world" >"$repo/readme.txt"
	git -C "$repo" add .

	run git -C "$repo" commit -m "normal file"
	[ "$status" -eq 0 ]
}
