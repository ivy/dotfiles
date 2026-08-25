#!/usr/bin/env bats

load test_helper

# pget's only external dependency is ssh, so a stub that discards the options
# and host and runs the command string locally exercises the real transfer,
# resume and verification paths without needing a second machine.
#
# Setting FAIL_SKIP makes the stub drop the first request for one piece, which
# is what a stream dying mid-transfer looks like from pget's side.
setup_pget() {
	STUB_BIN="$TEST_TMPDIR/bin"
	mkdir -p "$STUB_BIN"

	cat >"$STUB_BIN/ssh" <<'STUB'
#!/usr/bin/env bash
while (($# > 0)); do
	case "$1" in
	-o) shift 2 ;;
	-*) shift ;;
	*) break ;;
	esac
done
shift # host
cmd="$*"
if [[ -n "${FAIL_SKIP:-}" && "$cmd" == *"skip=$FAIL_SKIP "* && ! -e "$TEST_TMPDIR/dropped" ]]; then
	touch "$TEST_TMPDIR/dropped"
	exit 255
fi
exec sh -c "$cmd"
STUB
	chmod +x "$STUB_BIN/ssh"
	PATH="$STUB_BIN:$PATH"
	export PATH

	# chezmoi grants the executable bit at apply time, so the source file is
	# mode 644; pget re-runs itself per piece and needs it here.
	PGET="$TEST_TMPDIR/pget"
	cp "$REPO_ROOT/home/dot_local/bin/executable_pget" "$PGET"
	chmod +x "$PGET"
}

# A size that is not a whole number of pieces, so the short final piece is
# covered rather than only the aligned case.
make_source() {
	SRC="$TEST_TMPDIR/source.bin"
	dd if=/dev/urandom of="$SRC" bs=1024 count=5121 2>/dev/null
	DEST="$TEST_TMPDIR/dest.bin"
}

@test "prints usage and exits zero for --help" {
	setup_pget

	run "$PGET" --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Usage: pget"* ]]
}

@test "rejects a target without a host" {
	setup_pget

	run "$PGET" /just/a/path /tmp/out
	[ "$status" -ne 0 ]
	[[ "$output" == *"[user@]host:path"* ]]
}

@test "rejects a non-numeric stream count" {
	setup_pget

	run "$PGET" --streams abc host:/tmp/x /tmp/y
	[ "$status" -ne 0 ]
	[[ "$output" == *"positive integer"* ]]
}

@test "transfers a file byte-for-byte including a short final piece" {
	setup_pget
	make_source

	run "$PGET" --piece 1 --streams 4 "host:$SRC" "$DEST"
	[ "$status" -eq 0 ]
	cmp "$SRC" "$DEST"
}

@test "verifies the copy and removes its state directory on success" {
	setup_pget
	make_source

	run "$PGET" --piece 1 --streams 4 "host:$SRC" "$DEST"
	[ "$status" -eq 0 ]
	[[ "$output" == *"verified"* ]]
	[ ! -d "$DEST.pget" ]
}

@test "resumes after a dropped stream and still lands byte-for-byte" {
	setup_pget
	make_source

	FAIL_SKIP=2 run "$PGET" --piece 1 --streams 4 "host:$SRC" "$DEST"
	[ "$status" -eq 0 ]
	[ -e "$TEST_TMPDIR/dropped" ] # the failure actually happened
	cmp "$SRC" "$DEST"
}

@test "resolves a directory destination to the source basename" {
	setup_pget
	make_source
	mkdir -p "$TEST_TMPDIR/into"

	run "$PGET" --piece 1 --streams 4 "host:$SRC" "$TEST_TMPDIR/into"
	[ "$status" -eq 0 ]
	cmp "$SRC" "$TEST_TMPDIR/into/source.bin"
}

@test "check passes on an intact copy" {
	setup_pget
	make_source
	cp "$SRC" "$DEST"

	run "$PGET" --check --piece 1 --streams 4 "host:$SRC" "$DEST"
	[ "$status" -eq 0 ]
	[[ "$output" == *"verified"* ]]
}

@test "check names the specific piece that differs" {
	setup_pget
	make_source
	cp "$SRC" "$DEST"
	# Flip a byte inside piece 3 (1 MiB pieces).
	printf 'X' | dd of="$DEST" bs=1 seek=$((3 * 1048576 + 100)) conv=notrunc 2>/dev/null

	run "$PGET" --check --piece 1 --streams 4 "host:$SRC" "$DEST"
	[ "$status" -ne 0 ]
	[[ "$output" == *"mismatched pieces: 3"* ]]
}

@test "check rejects a copy whose size differs from the source" {
	setup_pget
	make_source
	head -c 1000 "$SRC" >"$DEST"

	run "$PGET" --check --piece 1 "host:$SRC" "$DEST"
	[ "$status" -ne 0 ]
	[[ "$output" == *"size differs"* ]]
}
