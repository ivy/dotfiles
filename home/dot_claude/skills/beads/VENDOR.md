# Vendored skill — provenance

This skill is a partial copy of the `beads` Claude Code plugin's skill tree. It is not
installed as a plugin; the files are vendored so the hook contract and the command
surface stay under local control.

| | |
|---|---|
| Upstream | https://github.com/gastownhall/beads |
| Vendored version | plugin `1.2.2` (= `bd` 1.2.2) |
| Upstream path | `plugins/beads/skills/beads/` |

## What was copied

- `SKILL.md` — with local edits, see below
- `resources/` — 15 files, verbatim
- `adr/0001-bd-prime-as-source-of-truth.md` — verbatim, linked from `SKILL.md`

## What was deliberately excluded

- **`commands/`** (29 slash commands) — 10 of them instruct the model to call `beads`
  MCP tools. The plugin ships no MCP server and `SKILL.md` grants `Bash(bd:*)` only, so
  those commands point at tools the model can neither see nor call. The rest are a thin
  veneer over `bd` subcommands the model can already run.
- **`agents/task-agent.md`** — its entire workflow is MCP calls, and it is not declared
  in the upstream `plugin.json`, so it is unreachable even upstream.
- **`README.md`, `CLAUDE.md`, `agents/openai.yaml`** — plugin-maintainer material.
- **The plugin's hooks** — upstream registers `PreCompact: bd prime`. `PreCompact`
  stdout is appended as *custom compact instructions*, so that hook injects ~4.8KB of
  command reference into the prompt that decides what survives compaction. The
  `SessionStart` hook is provided locally instead, via `bin/sync-claude-settings`.

## Local edits to `SKILL.md`

- Version markers `0.60.0` → `1.2.2`. Upstream shipped a skill claiming to target bd
  0.60.0 inside a 1.2.2 plugin, so its own staleness check ("if `bd --version` reports
  newer than 0.60.0, this skill may be stale") fired on every session.
- Added a **Workspace Location** section. The workspace is external, reached via
  `.beads/redirect`, so bare `.beads/<path>` references in the resources would otherwise
  send an agent looking inside the checkout.

## Re-syncing

See [docs/beads.md](../../../../docs/beads.md) for the upgrade and removal procedures.
