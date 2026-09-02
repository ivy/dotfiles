# Beads

[beads](https://github.com/gastownhall/beads) (`bd`) is a graph issue tracker that
coding agents read and write as durable memory across sessions and context compaction.

## Overview

This is a **single-user trial** of beads inside repositories shared with people who do
not use it. Two consequences shape the whole setup:

- **No beads metadata is committed, anywhere.** The issue database lives outside every
  checkout. The only file beads puts inside a repository is a one-line pointer, hidden
  from git via `.git/info/exclude`.
- **Nothing is opted in by default.** A repository gets beads only when
  `beads-adopt` is run in it explicitly.

| Piece | Where it lives |
|-------|----------------|
| `bd` binary | `home/dot_config/mise/config.toml` (`github:gastownhall/beads`) |
| Per-repo opt-in/out | `home/dot_local/bin/executable_beads-adopt` |
| SessionStart hook | `home/dot_local/libexec/executable_claude-sessionstart-beads` |
| Hook registration | `bin/sync-claude-settings` (`set_session_start_hook`) |
| Agent skill | `home/dot_claude/skills/beads/` (vendored — see [The vendored skill](#the-vendored-skill)) |
| Issue databases | `~/.local/share/beads/<workspace>/.beads` |

The upstream Claude Code plugin is deliberately **not** installed. See
[Why the plugin is not installed](#why-the-plugin-is-not-installed).

## Operations

### Opt a repository in

```bash
cd ~/src/github.com/example/project
beads-adopt
```

That creates `~/.local/share/beads/github.com-example-project/.beads`, initializes a
Dolt database there, writes `<repo>/.beads/redirect` pointing at it, and adds `.beads/`
to `<repo>/.git/info/exclude`.

Verify the repository is still clean and the workspace resolved:

```bash
git status --porcelain          # must be empty
bd where                        # prints the external path + "(via redirect from ...)"
```

`beads-adopt` is idempotent — re-running it rewrites the redirect and leaves existing
issue data alone.

Options:

```bash
beads-adopt --prefix proj       # override the derived issue prefix
beads-adopt ~/src/other/repo    # act on a repository other than the cwd
```

### Opt a repository out

```bash
beads-adopt --remove            # drop the redirect + exclude entry, KEEP issue data
beads-adopt --remove --purge    # also delete the workspace and its issues
```

`--remove` restores the checkout exactly: it deletes only the marker block it added to
`.git/info/exclude`, leaving unrelated entries intact.

### Daily use

`bd ready`, `bd show <id>`, `bd update <id> --claim`, `bd close <id> --reason "..."`.
Run `bd prime` for the full workflow context, or read the `beads` skill.

## Architecture

### The database lives outside the checkout

By default beads keeps its database at `<repo>/.beads/` — committable state in a shared
repository. Worse, plain `bd init` also scaffolds `AGENTS.md`, `CLAUDE.md`, `.claude/`
and `.codex/` into the checkout and runs `git init` plus a commit.

So the database is held per-repository under `~/.local/share/beads/`, and the checkout
gets only `.beads/redirect` — a single line naming the real workspace. `bd`'s own
discovery follows that pointer, which `bd where` reports explicitly.

Workspace names come from the repository path, not its basename, so two repositories
sharing a name do not collide. Under `~/src` the existing `<host>/<owner>/<repo>`
layout is reused with separators flattened, matching the convention
[codebase-memory](./codebase-memory-mcp.md) uses over the same corpus. Anything outside
`~/src` gets a path digest appended instead.

### Why a redirect and not `BEADS_DIR`

`BEADS_DIR` names exactly one workspace. Exported globally it would collapse every
repository into a single shared database and issue prefix, because it overrides the
directory walk that normally gives each project its own.

Setting it per-repository would work, but only for processes that inherit it. Claude
Code hooks do not load interactive shell functions, so a `bd()` wrapper in `.zshrc`
would resolve correctly in a terminal and not at all in a hook. The redirect file is
resolved by `bd` itself, so terminals, hooks, and subagents all agree.

### Why `.git/info/exclude` and not `.gitignore`

`.gitignore` is tracked. Adding a beads entry to it would be exactly the visible change
this setup exists to avoid. `.git/info/exclude` is per-clone and never committed.

### The SessionStart hook

`claude-sessionstart-beads` emits `bd prime --hook-json` at session start, which injects
the beads session protocol and outstanding work into the agent's context.

SessionStart re-fires after compaction — its source values are
`startup|resume|clear|compact|fork` — so this one hook also covers context recovery.
**No `PreCompact` hook is registered, deliberately.** PreCompact stdout is appended as
*custom compact instructions*, so priming there would push ~5KB of command reference
into the prompt that decides what survives compaction.

The hook is a wrapper rather than a bare `bd prime --hook-json` for two reasons: a
missing `bd` would otherwise fail on every session start (and a nonzero SessionStart
hook shows its stderr to the user), and PATH is not guaranteed to carry mise shims in
every context Claude Code is launched from. The wrapper falls back to the shim path and
exits 0 silently when `bd` is genuinely absent.

In a repository with no workspace, `bd prime` returns an empty envelope and injects
nothing, so the hook is a no-op rather than noise.

### Permissions

`bin/sync-claude-settings` allowlists the read paths and the core write loop
(`bd ready`/`list`/`show`/`create`/`update`/`close`/`dep`/…). Deliberately **not**
allowlisted, so they still prompt: `bd init` (destructive re-init), `bd dolt` (network),
`bd delete`, `bd sql` (raw database), `bd compact` and `bd rename-prefix` (bulk
mutation).

## The vendored skill

`home/dot_claude/skills/beads/` is a partial copy of the upstream plugin's skill tree,
pinned at plugin **1.2.2**. Provenance and the exclusion list also live in
[the skill's own `VENDOR.md`](../home/dot_claude/skills/beads/VENDOR.md).

Copied: `SKILL.md`, `resources/` (15 files, ~4000 lines), and the one `adr/` file
`SKILL.md` links to.

Excluded:

- **`commands/`** (29 slash commands) — 10 instruct the model to call `beads` MCP tools.
  The plugin ships no MCP server and `SKILL.md` grants `Bash(bd:*)` only, so those
  commands point at tools the model can neither see nor call. The rest wrap `bd`
  subcommands the model can already run.
- **`agents/task-agent.md`** — entirely MCP-based, and not declared in the upstream
  `plugin.json`, so it is unreachable even upstream.

### Local edits

These are corrections, not preferences. Re-apply them after any re-sync.

| File | Edit | Why |
|------|------|-----|
| `SKILL.md` | version markers `0.60.0` → `1.2.2` | Upstream shipped a skill claiming to target bd 0.60.0 inside a 1.2.2 plugin, so its own staleness check fired every session |
| `SKILL.md` | Prerequisites point at `bd where` | The workspace is external; nothing should infer it from the cwd |
| `resources/PATTERNS.md` | two `mcp__plugin_beads_beads__*` blocks → `bd` commands | Instructed calls to tools that do not exist |
| `resources/TROUBLESHOOTING.md` | dropped the MCP sections and `v0.15.0` history | Same, plus advice for a version six releases old |

### Re-syncing against upstream

```bash
cd ~/src/github.com/gastownhall/beads && git pull
# diff upstream against the vendored copy
diff -ru home/dot_claude/skills/beads/resources \
         ~/src/github.com/gastownhall/beads/plugins/beads/skills/beads/resources
```

Then copy in what changed, re-apply the [local edits](#local-edits), bump the version
in `VENDOR.md`, and check for new MCP references before trusting anything:

```bash
grep -rn 'mcp__' home/dot_claude/skills/beads/
```

## Why the plugin is not installed

The upstream plugin's `plugin.json` registers a `PreCompact` hook running `bd prime`.
As above, PreCompact stdout becomes *custom compact instructions*, so that hook degrades
every compaction. Because it is baked into the manifest, it cannot be disabled while
keeping the rest of the plugin.

The plugin's value is the skill and its resources — which vendoring captures — so the
only thing given up is the 29 slash commands, most of which are broken or redundant.

Vendoring also avoids a double-fire: there is no once-per-session guard anywhere in
`bd prime`, so the plugin's hook plus a local one would both execute.

## Constraints worth knowing

### Never run `bd setup claude` in a shared repository

It writes the project's **tracked** `.claude/settings.json`. `--stealth` does not change
that — it only changes the hook's command string. It also strips beads hooks out of
`.claude/settings.local.json` as a "legacy migration", so hand-placing them there does
not survive.

`bd setup claude --global` would write `~/.claude/settings.json` out of band from
chezmoi, which `bin/sync-claude-settings` owns. The hook is managed there instead.

### Never export `BEADS_DIR` globally

One workspace, one database, one issue prefix for every repository. See
[Why a redirect and not `BEADS_DIR`](#why-a-redirect-and-not-beads_dir).

### `bd init` has side effects worth suppressing

`beads-adopt` passes `--skip-agents` (no `AGENTS.md`/`CLAUDE.md`/`.claude/`/`.codex/`
scaffolding) and `--skip-hooks` (no git hooks, which would collide with `hk`). Running
`bd init` by hand without those will make a mess.

### The workspace name must end in `.beads`

Several code paths key on that literal basename — project `config.yaml` resolution,
database path resolution, and `bd doctor`'s artifact checks among them. They fail by
returning empty rather than erroring, so a differently-named directory degrades
silently. `beads-adopt` always appends it.

### Upstream's own descriptions are unreliable

Every defect found while setting this up was in a *description* of behavior, never in
behavior: stale help text advertising a code path with no callers, a plugin manifest
five months behind the CLI beside it, command prose calling removed MCP tools, docs
asserting the project ships no skills while shipping one. The code is well tested; the
prose is not. **Read the source, not the docs.**

### `git clean -xdf` is not a threat here, but it was

Because the database is external, a `clean -xdf` in the repository destroys only the
redirect file, which `beads-adopt` recreates. Had the database stayed in-repo and
ignored, `clean -x` would have deleted it.

## Complete removal

Removes every trace. Steps 1–2 are per-repository; the rest are global.

```bash
# 1. Find every adopted repository
ls ~/.local/share/beads/

# 2. Opt each one out, deleting its issue data
beads-adopt --remove --purge ~/src/github.com/example/project
#    ...repeat per repository, then confirm nothing is left:
rm -rf ~/.local/share/beads

# 3. Drop the tool. Both files are edited by hand — removing a tool from the
#    config does not prune its stanza from the lockfile:
#    - home/dot_config/mise/config.toml: delete the "github:gastownhall/beads"
#      entry and its two comment lines
#    - home/dot_config/mise/mise.lock: delete the [[tools."github:gastownhall/beads"]]
#      block and all 11 of its [tools."github:gastownhall/beads"."platforms.*"] blocks

# 4. Drop the skill, the wrapper, and the helper
rm -rf home/dot_claude/skills/beads
rm -f home/dot_local/libexec/executable_claude-sessionstart-beads
rm -f home/dot_local/bin/executable_beads-adopt

# 5. Drop the hook registration and permissions from bin/sync-claude-settings
#    - delete the set_session_start_hook() function
#    - delete its call in main()
#    - delete the 17 "Bash(bd ...)" entries from set_permissions()

# 6. Remove the stale SessionStart hook from live settings, since
#    sync-claude-settings no longer manages that key
jq 'del(.hooks.SessionStart)' ~/.claude/settings.json >/tmp/s.json \
  && mv /tmp/s.json ~/.claude/settings.json

# 7. Apply, which also uninstalls the binary via mise prune
chezmoi apply
rm -rf ~/.local/share/mise/installs/github-gastownhall-beads

# 8. Delete this document and its CLAUDE.md row
rm docs/beads.md
```

Step 6 matters: removing the function stops the hook being *written*, but does not
remove one already in `~/.claude/settings.json`. Left behind, it would point at a
deleted wrapper on every session start.

Verify:

```bash
command -v bd            # nothing
jq '.hooks.SessionStart' ~/.claude/settings.json   # null
ls ~/.local/share/beads  # No such file or directory
```

## Troubleshooting

**`Error: No active beads workspace found.`** — the repository is not opted in. Run
`beads-adopt`, or accept that beads is not wanted there. Note `bd where` exits 0 in this
case, so check the output rather than the exit status.

**Issues appear under the wrong prefix** — the redirect points at another repository's
workspace. Check `bd where`, then re-run `beads-adopt`.

**`.beads/` shows up in `git status`** — the exclude entry is missing. Re-run
`beads-adopt`, which is idempotent, and confirm with
`git check-ignore -v .beads/redirect`.

**No beads context at session start** — run the hook directly to see what it emits:

```bash
~/.local/libexec/claude-sessionstart-beads
```

An empty `additionalContext` means no workspace resolved from that directory. The
wrapper deliberately swallows errors, so check `bd doctor` for the real cause.

**General health** — `bd doctor`. Do not delete or reinitialize a workspace while
diagnosing.
