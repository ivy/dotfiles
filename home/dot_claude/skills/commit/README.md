# `/commit` — Intentional, Conventional Commits

Commit changes with deliberate file selection, a conventional commit message, and a focus on *why* rather than *what*.

```
/commit
/commit fix the session expiry off-by-one
/commit home/dot_zshrc.tmpl home/dot_config/starship.toml
```

## Why this exists

Agent-driven development has a git history problem. Agents generate code quickly and tend to batch everything into one large commit at the end of a session. The result is a history full of "implement the feature" commits with diffs spanning a dozen files — unreviable, unrevertable, and unhelpful for future engineers trying to understand why a change was made.

[`/commit`](../commit/README.md) enforces three things that fix this:

**Intentional file selection.** Never `git add -A`. Every file in a commit is staged deliberately. The agent reviews what changed, connects it to the current task, and stages only what belongs together. Unrelated changes stay unstaged.

**Conventional commit format.** `type(scope): subject :emoji:` — consistent across every commit. This makes the history scannable, enables changelog generation, and signals intent (a `feat` vs a `fix` vs a `chore` means something).

**Why-focused messages.** The subject describes what changed; the body explains why. Future engineers don't need `git diff` to know what changed — they need to know what problem it solved.

## In the [`/work-on`](../work-on/README.md) workflow

[`/commit`](../commit/README.md) is the heartbeat of the execution phase. The design principle is "commit small and often": each logical unit of work gets committed before moving to the next. This creates:

- **Recoverable states** — if something goes wrong, there's a rollback point
- **Readable history** — the PR's commit log tells the implementation story
- **Reviewable diffs** — each commit is small enough to actually review

For agent-driven work specifically, incremental commits matter more than in human development. An agent can generate hundreds of lines of change in a single turn. Without checkpoints, a failure mid-session loses everything. With small commits, the work is preserved incrementally.

## Standalone usage

[`/commit`](../commit/README.md) is useful any time you need a commit with more care than `git add . && git commit -m "wip"` — which is basically always.
