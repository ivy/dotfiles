#!/usr/bin/env bats

# Tests for the global git hooks configured in ~/.config/git/config.
# Verifies that secrets are blocked in ANY repo without per-repo setup, and
# that a repository's own .git/hooks still run alongside them.

setup() {
	TEST_TMPDIR=$(mktemp -d)
	export TEST_TMPDIR
}

teardown() {
	rm -rf "$TEST_TMPDIR"
}

render_git_config() {
	chezmoi execute-template --file home/dot_config/git/config.tmpl
}

# --- Static: hooks are configured, not a shared hooks directory ---

@test "git config does not set core.hooksPath" {
	run render_git_config
	[ "$status" -eq 0 ]
	[[ "$output" != *"hooksPath"* ]]
}

@test "git config runs gitleaks on pre-commit" {
	run render_git_config
	[ "$status" -eq 0 ]
	[[ "$output" == *'[hook "gitleaks"]'* ]]
	[[ "$output" == *"event = pre-commit"* ]]
	[[ "$output" == *"shims/gitleaks git --pre-commit --staged"* ]]
}

@test "git config runs the git-lfs hooks when git-lfs is installed" {
	command -v git-lfs >/dev/null || skip "git-lfs not installed"
	run render_git_config
	[ "$status" -eq 0 ]
	local event
	for event in pre-push post-checkout post-commit post-merge; do
		[[ "$output" == *"[hook \"lfs-$event\"]"*"command = git lfs $event"* ]]
	done
}

# --- Integration: secrets are blocked in a fresh repo ---

# Runs git against the rendered global config, so the test does not depend on
# chezmoi having been applied to the developer's (or CI's) real home directory.
use_rendered_git_config() {
	git_version=$(git --version | awk '{print $3}')
	if [ "$(printf '%s\n' 2.54 "$git_version" | sort -V | head -1)" != 2.54 ]; then
		skip "configured hooks need git 2.54+, have $git_version"
	fi
	local gitleaks
	gitleaks=$(render_git_config | sed -n 's/^\tcommand = \(.*gitleaks\) git .*/\1/p')
	[ -x "$gitleaks" ] || skip "gitleaks shim not installed at $gitleaks"

	render_git_config >"$TEST_TMPDIR/gitconfig"
	export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
}

init_repo() {
	local repo="$1"
	git init "$repo"
	git -C "$repo" config user.email "test@test.com"
	git -C "$repo" config user.name "Test"
}

@test "committing a private key is blocked" {
	use_rendered_git_config

	local repo="$TEST_TMPDIR/repo"
	init_repo "$repo"

	ssh-keygen -t rsa -N '' -f "$repo/id_rsa" -q
	git -C "$repo" add .

	run git -C "$repo" commit -m "oops"
	[ "$status" -ne 0 ]
}

@test "committing normal files succeeds" {
	use_rendered_git_config

	local repo="$TEST_TMPDIR/repo"
	init_repo "$repo"

	echo "hello world" >"$repo/readme.txt"
	git -C "$repo" add .

	run git -C "$repo" commit -m "normal file"
	[ "$status" -eq 0 ]
}

@test "a repository's own pre-commit hook still runs" {
	use_rendered_git_config

	local repo="$TEST_TMPDIR/repo"
	init_repo "$repo"
	printf '#!/bin/sh\ntouch "%s"\n' "$TEST_TMPDIR/repo-hook-ran" >"$repo/.git/hooks/pre-commit"
	chmod +x "$repo/.git/hooks/pre-commit"

	echo "hello world" >"$repo/readme.txt"
	git -C "$repo" add .

	run git -C "$repo" commit -m "normal file"
	[ "$status" -eq 0 ]
	[ -f "$TEST_TMPDIR/repo-hook-ran" ]
}

@test "a repository can opt out of the gitleaks hook" {
	use_rendered_git_config

	local repo="$TEST_TMPDIR/repo"
	init_repo "$repo"
	git -C "$repo" config hook.gitleaks.enabled false

	ssh-keygen -t rsa -N '' -f "$repo/id_rsa" -q
	git -C "$repo" add .

	run git -C "$repo" commit -m "fixture key"
	[ "$status" -eq 0 ]
}
