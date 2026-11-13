#!/usr/bin/env bats

load test_helper

SCRIPT="home/run_onchange_after_install-gh-extensions.sh.tmpl"
DATA="home/.chezmoidata/gh-extensions.yaml"

@test "renders valid shell syntax" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	assert_script_structure "$output"
	assert_valid_shell "$output"
}

@test "declares every extension with a repo and a release tag" {
	assert_valid_yaml "$DATA"

	run yq -r '.ghExtensions[] | select((.repo | test("^[^/]+/gh-[^/]+$")) and (.version | test("^v[0-9]")) | not) | .repo' "$DATA"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "installs each declared extension at its pinned tag" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	while IFS=$'\t' read -r repo version; do
		[[ "$output" == *"ensure_extension \"$repo\" \"$version\""* ]]
	done < <(yq -r '.ghExtensions[] | [.repo, .version] | @tsv' "$DATA")
}

# `install --force` records the new tag as unpinned, so a version change must
# remove and reinstall to stay pinned.
@test "replaces a changed version by removing and reinstalling" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *'gh extension remove'* ]]
	[[ "$output" == *'gh extension install "$repo" --pin "$version"'* ]]
	! grep -v '^[[:space:]]*#' <<<"$output" | grep -q -- '--force'
}

@test "re-runs when the extension list changes" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"gh-extensions hash:"* ]]
}

# Resolved at runtime rather than with lookPath, because mise installs gh during
# the same apply and the shim may not exist when this template is rendered.
@test "skips gracefully when gh is not installed" {
	run chezmoi execute-template --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"command -v gh"* ]]
	[[ "$output" == *"gh not found"* ]]
}

@test "renders on darwin too — extensions are not linux-specific" {
	run chezmoi execute-template --config "$(chezmoi_config darwin)" --file "$SCRIPT"
	[ "$status" -eq 0 ]

	[[ "$output" == *"ensure_extension"* ]]
}
