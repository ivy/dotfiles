#!/usr/bin/env bats

load test_helper

UNIT="home/dot_config/systemd/user/moshi-notify@.service"

@test "reindex units notify Moshi when they fail" {
	local unit
	for unit in qmd-reindex cbm-reindex; do
		grep -qx 'OnFailure=moshi-notify@%n.service' "home/dot_config/systemd/user/${unit}.service"
	done
}

# Best effort by design: a machine without Moshi must not turn a failed timer
# into a second failure.
@test "notifies through moshi-hook's best-effort notify, not --strict" {
	grep -q 'moshi-hook notify --error' "$UNIT"
	! grep -q -- '--strict' "$UNIT"
}

# A source or label that reads as an agent name is rejected by moshi-hook.
@test "names the card after the host's timers, not an agent" {
	grep -q -- '--source systemd' "$UNIT"
	grep -q -- '--label "%H timers"' "$UNIT"
}
