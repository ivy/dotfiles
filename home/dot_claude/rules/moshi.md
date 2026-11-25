# Moshi

This machine is paired with Moshi, a mobile terminal, so the user may be following the session from their phone. Agent hooks already push the session's own events there: session start and end, each prompt, permission requests, `AskUserQuestion`, `ExitPlanMode`, and the end of every turn. Don't repeat those: a "done" notification at the end of a turn arrives twice.

`moshi-hook` reaches the phone for what the hooks can't see, which is anything that happens inside a turn.

## When to use it

- **A long command inside a turn.** Wrap a build, full test suite, ansible play, or large download that will take more than a few minutes in a job, so the phone shows a live row instead of silence.
- **A milestone worth knowing before the turn ends.** In a long autonomous run — a `/loop`, a CI fix loop, a multi-step migration — notify once when CI goes green, when a blocker will need the user's input, or before a destructive step starts.
- **A failure that stops the work.** Send `notify --error`, then carry on or end the turn as usual.

Skip it for routine progress and for anything the turn-end alert will say anyway, and never call it in a loop: notifications share the host's push rate limit with every agent on it.

## Commands

```bash
id=$(moshi-hook job start --source claude-task --label "Claude task" "Full test suite")
moshi-hook job update "$id" --progress 40 --message "212/530 tests"
moshi-hook job end "$id"            # or: --error --message "3 failures"

moshi-hook notify --source claude-task --label "Claude task" --title "CI green" "fix-ci: build 4812 passed after 3 iterations"
moshi-hook notify --error --source claude-task --label "Claude task" "Migration stopped: conflict in mise.lock"
```

- `--source` and `--label` name the card. Neither may be an agent's name, so a bare "Claude" is rejected.
- All of these are best effort: when Moshi can't be reached they print why and exit 0, so they never fail the command around them. Job state is per machine, so `update` and `end` must run where `start` did.

Don't use `moshi-hook ask` for your own questions. `AskUserQuestion` already reaches the phone and keeps the answer in the transcript. `ask` is for scripts the user runs unattended, such as a deploy gate with `--require-remote` so only the phone can approve.

Flags and exit codes: `moshi-hook <command> --help`, or the [Moshi hooks docs](https://getmoshi.app/docs/hooks).
