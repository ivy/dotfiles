---
name: handoff
description: Write a handoff brief summarizing the current conversation so a fresh agent can pick up the work. Writes to a file if given, otherwise copies to the clipboard.
argument-hint: "[filename]"
disable-model-invocation: true
allowed-tools:
  - Bash(pbcopy)
  - Bash(pwd)
  - Bash(git status:*)
  - Bash(git log:*)
  - Bash(git diff --stat:*)
  - Bash(git rev-parse:*)
---

# Handoff Brief

Write a compact, actionable brief that lets a fresh agent (with empty context) resume where this conversation left off.

## Arguments

```
$ARGUMENTS
```

If a filename is given, write the brief there. Otherwise pipe it to `pbcopy`.

## Instructions

### 1. Gather lightweight repo state

Run only what's relevant — don't dump everything. Typical:

```bash
pwd
git rev-parse --abbrev-ref HEAD
git status --short
git log --oneline -5
git diff --stat
```

Skip git commands entirely if the work isn't in a repo or the state is irrelevant (e.g. pure research conversation).

### 2. Synthesize the brief

Use the structure below. Keep it dense — a fresh agent reads this cold and should be able to continue within a minute. Omit sections that don't apply; don't pad.

```markdown
# Handoff: <one-line task title>

## Mission
<1–3 sentences: what the user is trying to accomplish and why it matters.>

## State
- **Cwd:** <path>
- **Branch:** <branch>  (omit if not in a repo)
- **Uncommitted:** <short summary of dirty files, or "clean">
- **Last commit:** <sha — subject>

## Done
- <Completed step> — `path/to/file:line` if relevant
- ...

## In progress
- <What's actively being worked on; include the specific file/line and what's half-finished>

## Next steps
1. <First concrete action>
2. <Next>
3. ...

## Decisions made
- **<decision>** — <why>. Rejected: <what was considered and discarded>.

## Don't redo
- <Approach already tried that failed> — <why it didn't work>

## Open questions
- <Question for the user or new agent to resolve>

## Key files
- `path/to/file:line` — <why it matters>

## Useful commands
- `command` — <what it does in this context>
```

### 3. Deliver

**If `$ARGUMENTS` is non-empty** → treat it as the filename and write the brief there with the `Write` tool. Report the absolute path.

**If `$ARGUMENTS` is empty** → pipe the brief to `pbcopy`:

```bash
pbcopy << 'HANDOFF_EOF'
<the brief>
HANDOFF_EOF
```

Confirm "Handoff copied to clipboard" with a one-line summary of what's in it.

## Principles

- **Cold-read test:** assume the next agent sees nothing but this brief. No "as discussed above" or pronouns without antecedents.
- **Specific over comprehensive:** include file paths, line numbers, command names. Don't restate code; point to it.
- **Capture the *why*:** decisions and dead-ends save more time than re-explaining what's done.
- **No filler:** drop sections that are empty. A short brief beats a padded one.
- **Don't leak secrets:** scrub tokens, passwords, or private endpoints before writing.

## Examples

```
/handoff                              → copy brief to clipboard
/handoff HANDOFF.md                   → write brief to ./HANDOFF.md
/handoff /tmp/auth-refactor.md        → write brief to absolute path
/handoff notes/today.md               → write brief to nested path (create dirs as needed)
```
