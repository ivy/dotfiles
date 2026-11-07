#!/usr/bin/env bats

load test_helper

# ~/.bashrc is what Claude Code's Bash tool snapshots (CLAUDE_CODE_SHELL), so it
# must give agents the same environment as zsh on both platforms.
render_bashrc() {
	local os="$1"

	chezmoi execute-template --config "$(chezmoi_config "$os")" \
		--file "$REPO_ROOT/home/dot_bashrc.tmpl"
}

@test "bashrc renders as valid bash on linux and darwin" {
	for os in linux darwin; do
		run render_bashrc "$os"
		[ "$status" -eq 0 ]
		printf '%s\n' "$output" >"$TEST_TMPDIR/bashrc.$os"
		bash -n "$TEST_TMPDIR/bashrc.$os"
	done
}

@test "bashrc shares the zshenv exports, including npm hardening" {
	for os in linux darwin; do
		run render_bashrc "$os"
		[ "$status" -eq 0 ]
		[[ "$output" == *'export NPM_CONFIG_IGNORE_SCRIPTS=1'* ]]
		[[ "$output" == *'export XDG_CONFIG_HOME='* ]]
	done
}

@test "bashrc activates mise in shim mode" {
	run render_bashrc linux
	[ "$status" -eq 0 ]
	[[ "$output" == *'mise activate bash --shims'* ]]
}

@test "bashrc leaves no duplicate PATH entries" {
	run render_bashrc linux
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" >"$TEST_TMPDIR/bashrc"

	run env -i HOME="$TEST_HOME_DIR" PATH="/usr/bin:/bin:/usr/bin" \
		bash -c '. "$1" >/dev/null 2>&1; . "$1" >/dev/null 2>&1; tr : "\n" <<<"$PATH" | sort | uniq -d' _ "$TEST_TMPDIR/bashrc"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
