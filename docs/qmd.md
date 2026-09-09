# QMD Vault Search

On-device hybrid search over the Obsidian vault, exposed to Claude Code as an MCP
server. Two scheduled jobs keep it fresh and warm — launchd agents on darwin,
systemd user units on linux.

## Overview

[QMD](https://github.com/tobi/qmd) indexes markdown and answers queries three ways:
BM25 full text (`qmd search`), vector similarity (`qmd vsearch`), and a hybrid mode
with LLM reranking (`qmd query`). Everything runs locally against GGUF models — no
API keys, no network at query time.

Agents reach it through the `qmd` MCP server, which exposes `query`, `get`,
`multi_get`, and `status`.

## Architecture

| Concern | Source | Target |
|---|---|---|
| MCP server declaration | `home/.chezmoidata/claude-extensions.yaml` | `~/.claude.json` via `bin/sync-claude-extensions` |
| Reindex job (darwin) | `home/private_Library/LaunchAgents/net.ivyevans.qmd-reindex.plist.tmpl` | `~/Library/LaunchAgents/` |
| MCP daemon (darwin) | `home/private_Library/LaunchAgents/net.ivyevans.qmd-mcp.plist.tmpl` | `~/Library/LaunchAgents/` |
| Reindex job (linux) | `home/dot_config/systemd/user/qmd-reindex.{service,timer}` | `~/.config/systemd/user/` |
| MCP daemon (linux) | `home/dot_config/systemd/user/qmd-mcp.service` | `~/.config/systemd/user/` |
| Reindex + maintenance script | `home/dot_local/bin/executable_qmd-reindex` | `~/.local/bin/qmd-reindex` |
| Loader (darwin) | `home/run_onchange_after_bootstrap-launchd-agents.sh.tmpl` | — |
| Loader (linux) | `home/run_onchange_after_bootstrap-systemd-units.sh.tmpl` | — |
| Model fetch | `home/run_onchange_after_00-pull-qmd-models.sh.tmpl` | — |
| Native addon rebuild | `rebuild_qmd_sqlite_addon()` in `home/run_onchange_00-install-mise-tools.sh.tmpl` | — |

Each platform gets exactly one set: `.chezmoiignore` excludes `Library/**` on
non-darwin and `.config/systemd/**` on non-linux, and each loader template is
wrapped in the matching OS guard. The reindex script itself is shared.

### The two jobs

| | reindex | mcp daemon |
|---|---|---|
| Command | `~/.local/bin/qmd-reindex` | `qmd mcp --http --port 8181` |
| Schedule (darwin) | `StartInterval` 300s | `RunAtLoad` + `KeepAlive` |
| Schedule (linux) | `OnUnitInactiveSec` 5min | `Restart=always` |
| Priority | background / throttled I/O | default (interactive) |
| Log (darwin) | `~/Library/Logs/qmd-reindex.log` | `~/Library/Logs/qmd-mcp.log` |
| Log (linux) | journal, `qmd-reindex` | journal, `qmd-mcp` |

Both invoke qmd by absolute shim path. Neither launchd nor a systemd user unit
puts the mise shims on `PATH`; the shim is a standalone binary that resolves the
mise-active node itself.

The daemon runs `--http` in the **foreground**. `--daemon` re-spawns itself
detached and unrefs the child — the fork-and-exit behaviour `launchd.plist(5)`
forbids of a managed job, and which would leave systemd supervising a process that
exits the moment it has handed off.

Two schedule details differ by design. launchd's `StartInterval` fires on a fixed
period whether or not the previous run finished; systemd's `OnUnitInactiveSec`
measures from the *end* of the last run, so a slow cycle delays the next rather
than stacking on it. And a systemd timer with only `OnUnitInactiveSec` has nothing
to measure from until the service has run once, so `OnStartupSec` seeds the first
tick.

On linux the timers only run while the user manager is alive. Without lingering
that means "while logged in", which defeats an unattended reindex — the loader
warns when `loginctl show-user $USER --property=Linger` is not `yes` rather than
enabling it, because `enable-linger` can raise a polkit prompt and a `chezmoi
apply` blocked on an auth dialog is worse than a line of output.

### Index and collections

The index lives at `~/.cache/qmd/index.sqlite` in WAL mode. Collections, ignore
globs, and per-directory context descriptions are configured in
`~/.config/qmd/index.yml`.

That file is deliberately **not** chezmoi-managed — vault paths differ per machine.
Adding it would mean either a machine-local template or a broken path on the next
host.

Per-directory *context* is the highest-leverage part of the config: QMD returns a
directory's description alongside every hit, so an agent can tell a 1-1 note from a
web clipping from a skill definition. Contexts inherit down the tree.

## Operations

Check the daemon — the health endpoint is the platform-independent answer:

```bash
curl -s localhost:8181/health

# darwin
launchctl print "gui/$(id -u)/net.ivyevans.qmd-mcp" | grep -E 'state =|last exit'
# linux
systemctl --user status qmd-mcp.service
```

Force a reindex instead of waiting for the next 5-minute tick:

```bash
# darwin
launchctl kickstart -p "gui/$(id -u)/net.ivyevans.qmd-reindex"
tail -20 ~/Library/Logs/qmd-reindex.log
# linux
systemctl --user start qmd-reindex.service
journalctl --user -u qmd-reindex.service -n 20
```

Restart the daemon (drops resident models; the next query reloads them):

```bash
# darwin
launchctl kickstart -k "gui/$(id -u)/net.ivyevans.qmd-mcp"
# linux
systemctl --user restart qmd-mcp.service
```

Diagnose the install — runtime, sqlite-vec, model cache, GPU probe, and embedding
fingerprint integrity:

```bash
qmd doctor
```

After changing a unit or the reindex script, `chezmoi apply` re-runs the matching
loader, which boots each job out and back in. No logout required.

### Logging and maintenance

`qmd-reindex` is silent when a cycle finds nothing to change — at 288 runs a day,
logging every no-op would bury the runs that mattered. The check fails open, so
summaries reworded by a qmd upgrade get logged rather than silently swallowed.

On darwin it also caps both logs at 1 MiB. The daemon logs a line per HTTP request
and serves every session at once, so it grows faster than the reindex log; the
reindex job is the only thing on a schedule, so it does the capping for both.
launchd never rotates a `StandardOutPath` — journald does, so on linux both jobs
log to the journal and the script caps nothing.

`qmd update` prunes orphaned content hashes inline, but only `qmd cleanup` clears
cached LLM responses, drops inactive document records, and VACUUMs the file back
down. `qmd-reindex` runs it at most once a day, tracked by the mtime of
`~/.cache/qmd/.last-cleanup`. A stamp file rather than a calendar
agent means a window missed because the laptop was asleep self-heals on the next
tick, which neither `StartCalendarInterval` nor an `OnCalendar` timer would.

### Models

Three GGUF models cache in `~/.cache/qmd/models` — embedding (~318 MB), query
expansion (~1.2 GB), and reranking (~610 MB). `qmd pull` fetches whatever is
missing and reports the rest as `cached/checked`; only `--refresh` refetches.

`run_onchange_after_00-pull-qmd-models.sh.tmpl` runs it so a fresh machine
converges instead of discovering a multi-gigabyte download inside the daemon on the
first query, where the only sign of it is a log file. It skips inside containers —
the image build runs `chezmoi init --apply`, and no container workload needs ~2.2 GB
of models baked in.

## Why HTTP rather than stdio

An stdio MCP server is spawned per Claude Code session, and each process loads its
own models. Measured on this machine:

| | stdio | http daemon |
|---|---|---|
| Processes | one per session | one, shared |
| Cold hybrid query | ~26.5s, per session | ~26.5s, once |
| Idle footprint | ~54 MB per session | ~54 MB total |

Model *memory* mostly does not multiply — the GGUF files are mmap'd, so four
concurrent processes raised system-wide used memory by only ~0.9 GB despite each
reporting ~1.9 GB RSS. Per-process RSS double-counts shared pages. The marginal
cost of an extra process is roughly 225 MB.

Model *load time* multiplies completely. With ~20 concurrent sessions that is the
whole argument: ~20 cold starts of ~26.5s each, versus one.

The daemon lazy-loads, so it sits at ~54 MB until the first query rather than
reserving memory at login. `QMD_METAL_KEEP_RESIDENCY=1` is set on the job because
qmd's launcher otherwise disables Metal residency sets for a clean process exit
(ggml-org/llama.cpp#22593), and `qmd doctor` recommends opting back in for
long-lived processes.

**Trade-off:** stdio self-healed per session. One shared daemon means a failure
takes out search everywhere at once, mitigated by `KeepAlive`, `RunAtLoad`, and the
`/health` endpoint.

A long-lived reader coexists with the 5-minute writer because the index is in WAL
mode: readers do not block the writer, and freshly committed notes are visible
without restarting the daemon. `qmd cleanup`'s VACUUM also succeeds with the daemon
connected.

## Constraints worth knowing

### The native addon breaks on upgrade unless rebuilt

`better-sqlite3` ships C++ source and relies on a postinstall script to obtain a
binary. `NPM_CONFIG_IGNORE_SCRIPTS=1` (see
[supply-chain-security.md](supply-chain-security.md)) blocks that, so a fresh qmd
install has no native addon and every invocation dies with `ERR_DLOPEN_FAILED`.

`rebuild_qmd_sqlite_addon()` in `run_onchange_00-install-mise-tools.sh.tmpl` fixes
this by compiling from the source vendored in the tarball, and only when the current
interpreter cannot load the addon. Do **not** "fix" it with `prebuild-install` —
that downloads a third-party release blob, which is exactly what the hardening
exists to avoid. The addon is bound to one Node ABI, so a node upgrade invalidates
it and triggers a rebuild.

### The loader's filename controls when it runs

chezmoi applies entries in case-sensitive name order, and each loader must run
after the directory it loads from is written: `~/Library/LaunchAgents/` on darwin,
`~/.config/systemd/user/` on linux. `bootstrap` sorts after both — after `Library`
because `b` > `L`, and after `.config` because `b` > `.`. A numeric prefix sorts
*before* either, so the script would run first, find no unit, and skip — leaving
the job unloaded with only a log line to show it.
`test/run_onchange_bootstrap-launchd-agents.bats` and
`test/run_onchange_bootstrap-systemd-units.bats` guard this.

### Transport changes need in-place reconciliation

`bin/sync-claude-extensions` is additive for marketplaces and plugins, but MCP
servers are reconciled in place: a declared server whose transport, command, args,
url, or env/header *keys* differ from what is installed gets removed and re-added,
because `claude mcp add` will not overwrite.

env and header *values* are excluded from that comparison on purpose. They may hold
`${op://…}` references resolved at sync time, so the installed value never equals
the declared one — diffing values would re-add every server on every run and force
needless 1Password reads.

Per ADR-006's reach-in invariant, change the declaration and `chezmoi apply`. Never
run `claude mcp add`/`remove` by hand for a user-scope server.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Every `qmd` command dies with `ERR_DLOPEN_FAILED` | Native addon missing after an install or node upgrade | `chezmoi apply` to re-run the mise tools script, or `npm rebuild better-sqlite3` in the package dir |
| MCP tools fail, `/health` refuses connection | Daemon not running | darwin: `launchctl print gui/$(id -u)/net.ivyevans.qmd-mcp` and `~/Library/Logs/qmd-mcp.log`; linux: `systemctl --user status qmd-mcp.service` |
| Job absent from `launchctl list` / `systemctl --user list-timers` | Loader ran before the unit was written | Check the loader's filename still sorts after `Library` (darwin) or `.config` (linux) |
| Timers stop after logging out (linux) | Lingering is off | `loginctl enable-linger $USER` |
| New notes not in results | Reindex failing | darwin: `grep 'reindex failed' ~/Library/Logs/qmd-reindex.log`; linux: `journalctl --user -u qmd-reindex.service` |
| `qmd status` reports 0 documents | No collections configured — `~/.config/qmd/index.yml` is per-machine and unmanaged | `qmd collection add <vault-path> --name <name>` |
| First hybrid query hangs for minutes | Reranker not cached | `qmd pull` |
| `doctor` reports an `invalid` model | `pull` writes `.etag` sidecars that `doctor` mistakes for models | Cosmetic; confirm the `.gguf` files start with `GGUF` |

## References

- [QMD upstream](https://github.com/tobi/qmd)
- [ADR-006: declarative Claude Code extensions](adrs/006-declarative-claude-code-extensions.md)
- [Supply chain security](supply-chain-security.md)
- [Claude Code integration](claude-code.md)
- `launchd.plist(5)` — job keys and the daemonization rules
- `systemd.service(5)`, `systemd.timer(5)` — the linux equivalents
