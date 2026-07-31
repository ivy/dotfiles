# Codebase Memory

A code knowledge graph over every repository under `~/src`, queryable from any
Claude Code session. Adopted in
[ADR-008](adrs/008-adopt-codebase-memory-mcp-for-multi-repo-wayfinding.md).

## Overview

[`codebase-memory-mcp`](https://github.com/DeusData/codebase-memory-mcp) (CBM)
parses source with tree-sitter across 158 languages, adds language-server-assisted
symbol resolution, and stores the result as a graph in SQLite. On top of that it
offers BM25 lexical search, on-device embeddings, structural search, and graph
traversal through an MCP tool surface.

It exists here to solve one problem: finding things in the repositories that
*aren't* the ones worked in daily. Shared libraries, generated clients, services
owned by other teams, third-party checkouts kept for reference — the cases where
an agent can't guess a path and a human can't supply one.

Everything runs on-device. The embedding model is vendored into the binary, so
there is no model download and no API key. Source code does not leave the machine.

## Use it as a locator, not an oracle

This is the constraint that matters most, and nothing in the tooling enforces it.

Core principle 4 (Source Truth) says agent infrastructure teaches agents *where to
look*, not *what to know*. A code graph is structurally a pre-digested summary of
the code, and a summary an agent trusts is worse than a stale document — the agent
has no signal that it's out of date.

So:

- **Do** use CBM to answer *which repository, which file, which symbol*, then
  `Read` the actual source.
- **Don't** answer questions about how code behaves from graph contents. The graph
  says a call edge exists; only the source says what the call does.

The index is a routing table. Treat a graph answer as a pointer to verify, never
as the finding itself.

## Architecture

### One project per repository

Each repository is indexed as its own project with its own SQLite database at
`~/.cache/codebase-memory-mcp/<project>.db`.

Project names are set explicitly by `cbm-reindex` as the path under `~/src` with
every byte outside `[A-Za-z0-9_-]` mapped to `-`, so
`github.com/owner/repo` becomes **`github-com-owner-repo`**. That is the name to
pass as `project` to every MCP tool.

The explicit naming is not cosmetic. CBM's own default derives the name from the
absolute path and *preserves dots*, while it reads a node's top-level package as the
second dot-delimited segment of its qualified name (`cbm_qn_to_top_package`,
`store.c:4852`). A dotted project name therefore makes every cluster label and
`packages` entry a fragment of the project name rather than a real package. This
`$HOME` contains a dot and so does `github.com`, so the default is wrong here —
verified by indexing one repository both ways and diffing
`get_architecture(aspects=['clusters'])`. Dot-free names are also much shorter for
an agent to pass.

Indexing `~/src` as a single mega-project was rejected: `~/src` is not a git
repository, so change detection loses its basis, and nested `.gitignore` handling
is one level deep per subtree — every repository's root ignore file would apply but
deeper ones would silently not.

Reserved siblings in that directory: `_config.db` (CLI settings) and `logs/`.

### Sessions, the daemon, and why a periodic job is required

CBM runs a thin stdio frontend per session, with one per-account coordination
daemon owning watchers and index jobs. The first session spawns it; the last one
tears it down.

The important gap: **watches are per-session, reference-counted subscriptions.**
When the last session referencing a watch disconnects, the physical watch is
unregistered, and the watcher-driven index then declines to run because it requires
a live watch. There *is* a permanent daemon (`daemon start`) that survives zero
clients, but it holds no watches — its own help text calls it what it is, a way to
"skip the per-command startup cost." It is a warm-start cache, not a background
indexer.

Consequence: with no session attached, nothing reindexes. Hence the launchd agent
below.

### The reindex agent

| Piece | Path |
|---|---|
| Script | `home/dot_local/bin/executable_cbm-reindex` |
| Agent | `home/private_Library/LaunchAgents/net.ivyevans.cbm-reindex.plist.tmpl` |
| Loader | `home/run_onchange_after_bootstrap-launchd-agents.sh.tmpl` |
| Log | `~/Library/Logs/cbm-reindex.log` |

Every 30 minutes it walks each repository under `~/src` serially and runs
`cli index_repository`. `cli` mode never starts the coordination daemon or
registers watchers — it takes only the admission barrier and per-project mutation
locks, which is what makes it safe to run unattended alongside live sessions.

Incremental passes are cheap per repository because the incremental-vs-full gate is
content-hash based rather than git based, so it also works for non-git trees. The
largest repository in the corpus costs about 17 seconds with nothing changed.

Across the whole corpus, though, an all-quiet cycle measures around **190
seconds** — it is I/O bound, re-hashing file contents everywhere. At a 30-minute
interval that is roughly a 10% duty cycle, which `ProcessType=Background` and
`LowPriorityIO` keep out of the way. If it ever becomes noticeable, raise
`StartInterval` before reaching for anything cleverer; the active repository is
covered by the per-session watcher regardless.

The script stays silent unless node or edge counts moved somewhere, or something
failed. It compares a digest of the whole corpus's counts against the previous
cycle — a job this frequent would otherwise bury the cycles that did real work.

Whatever repository is actively open is already covered by CBM's own per-session
watcher (`auto_watch` defaults to on and registers the *session's* project only).
This job is the backstop for everything else.

## Operations

```bash
# Index one repository (never starts the daemon). Always pass --name; see
# "One project per repository" above for why the derived default is wrong here.
codebase-memory-mcp cli index_repository --repo-path <path> --mode full \
  --name github-com-owner-repo

# Runtime settings and daemon state
codebase-memory-mcp config list
codebase-memory-mcp daemon status

# Reload the agent after a plist change
launchctl bootout gui/$(id -u)/net.ivyevans.cbm-reindex
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/net.ivyevans.cbm-reindex.plist
```

A cold index of the whole corpus takes a few minutes. Run it **serially** — peak
RSS on the largest repository is close to 10 GiB, so two concurrent full indexes
will hurt.

### Configuration

Four keys live in `_config.db` via `codebase-memory-mcp config set`:

| Key | Default | Notes |
|---|---|---|
| `auto_index` | `false` | Leave off. Indexing on session start blocks work behind a cold index of wherever the agent launched. |
| `auto_index_limit` | `50000` | Only consulted on the auto-index path; explicit `index_repository` has no file cap. |
| `auto_watch` | `true` | Leave on. Registers a watcher for the session's project only, not one per indexed repository. |
| `ui-lang` | `auto` | |

Both settings that matter are already the upstream defaults, so `_config.db` is
deliberately **not** managed by chezmoi and a fresh machine converges without
intervention. The tradeoff: if upstream changes a default, machines diverge until
it's set explicitly.

## Why stdio rather than HTTP

CBM ships no HTTP or SSE MCP transport — `main.c` is an MCP stdio server plus a
CLI. The resident-service pattern used for qmd (a single `--http` daemon behind
localhost so concurrent sessions share warm models) does not apply and isn't
needed: CBM already solves warm-process sharing with its own coordination daemon.

The MCP entry is declared in `home/.chezmoidata/claude-extensions.yaml` with a bare
`codebase-memory-mcp` command rather than an absolute path. mise runs in shim mode
here and `dot_zshenv` prepends the shims directory for non-login shells
specifically so agent subprocesses resolve tools, which keeps the entry portable.

## Constraints worth knowing

### A version bump can wedge the daemon

Every CBM process must share one build fingerprint, enforced by an OS admission
barrier. `run_onchange_00-install-mise-tools.sh.tmpl` runs `mise prune --yes` after
installing, which deletes the old version directory out from under a warm daemon —
after which it rejects work, presenting as "the MCP server stopped responding" with
no obvious cause.

Two mitigations are in place: that script stops the daemon before making tool
changes, and `cbm-reindex` stops it and retries once on the first failure of a
cycle. The retry deliberately triggers on *any* first failure rather than matching
an error string, so it keeps working when the message changes.

### Stale-root pruning deletes cached databases

A *watched* project whose root stays missing for three consecutive polls plus a
ten-minute grace period has its cached database deleted. Since `auto_watch` is on,
actively-used repositories are the watched ones — so a checkout that gets relocated
or removed silently loses its index. Recovery is a full reindex.

### The `--target-projects` flag is broken; use the raw-JSON form

`cli ... --target-projects '["*"]'` — the syntax the tool's own `--help` documents —
does **not** parse the JSON. It treats the raw string as a single target name,
returns a plausible `projects_scanned: 1` / `total_cross_edges: 0` / `success`, and
creates a cache database literally named `["*"].db`. Every answer from that form is
an artifact of argument handling.

Pass a real array instead, via piped stdin or the MCP tool:

```bash
printf '%s' '{"repo_path":"<repo>","mode":"cross-repo-intelligence",
              "target_projects":["*"]}' |
  codebase-memory-mcp cli index_repository
```

That scans the whole corpus properly — 117 projects here. Passing the same JSON as a
positional argument also works but is deprecated upstream and warns; stdin and
`--args-file` are the supported forms.

The tell is duration: a real wildcard pass takes tens of seconds, so sub-second
completion means it did nothing. Cross-repo edges are sparse regardless (2 `CROSS_HTTP_CALLS` across
this corpus), since the detector recognises only HTTP/gRPC/GraphQL/tRPC/channel
contracts and most checkouts here are unrelated.

To confirm the junk-project symptom on any machine:
`ls ~/.cache/codebase-memory-mcp/ | grep '^\['` — anything listed was created by the
flag form and can be deleted.

### Don't use `--persistence`

It writes a compressed `.codebase-memory/graph.db.zst` *into* the repository so
teammates can bootstrap from the artifact. For a single-user local index it buys
nothing and litters every working tree with an untracked file that a broad
`git add` would commit.

### The threat model is memory safety, not exfiltration

CBM parses untrusted source using roughly 43,750 lines of hand-written tree-sitter
`scanner.c` plus a locally patched runtime. The git history carries
heap-buffer-overflow fixes; fuzzing and sanitizers mitigate without eliminating.
The realistic failure is an abort on an unusual tree, which is why the reindex loop
continues past a failing repository. Hardening this further with OS-level
sandboxing is noted as follow-up work in ADR-008.

Upstream also documents one best-effort update check to `api.github.com` after MCP
`initialize`, carrying no project data. `cli` mode never reaches it.

### Don't use `list_projects` for discovery — derive the name instead

It is the obvious entry point and it does not work at this scale. The response is
~67,000 characters for this corpus, which overruns an MCP client's per-result token
budget and gets spilled to a file rather than returned inline. Latency is erratic
too: one invocation enumerated the corpus fine, a second exceeded four minutes and
had to be killed.

None of that matters, because the project name is derivable and never needs looking
up. A repository at `~/src/<host>/<owner>/<repo>` is always:

```
<host>-<owner>-<repo>       with every . and / replaced by -
```

So `~/src/github.com/backstage/backstage` → `github-com-backstage-backstage`. Build
the name and pass it straight to `search_graph` / `search_code` / `query_graph`.

Guessing wrong is cheap and self-correcting: an unknown project returns an immediate
error whose payload is the complete list of indexed project names — a few kilobytes,
versus ~67,000 characters for `list_projects`. So if you ever do need the full
roster, deliberately querying a bogus project name is the faster way to get it.

Reserve `list_projects` for when you actually need the per-project node/edge/size
stats, and expect to read the result from a file.

## Troubleshooting

**MCP tools missing from a session** — check the server is registered with
`claude mcp list`, then that the shim resolves: `command -v codebase-memory-mcp`.

**Indexes look stale** — check the agent is loaded and the log:

```bash
launchctl print gui/$(id -u)/net.ivyevans.cbm-reindex | head -20
tail -50 ~/Library/Logs/cbm-reindex.log
```

Silence in the log is expected — the script only writes when counts moved or
something failed.

**"stopped responding" after an update** — the fingerprint case above. Run
`codebase-memory-mcp daemon stop` and start a new session.

**Start over for one repository** — delete its database from
`~/.cache/codebase-memory-mcp/` and reindex. The whole cache is disposable.

## References

- [Upstream repository](https://github.com/DeusData/codebase-memory-mcp)
- [`SECURITY.md`](https://github.com/DeusData/codebase-memory-mcp/blob/main/SECURITY.md)
  — runtime network behaviour, release verification
- [arXiv:2603.27277](https://arxiv.org/abs/2603.27277) — the project's own
  evaluation across 31 repositories
- [ADR-008](adrs/008-adopt-codebase-memory-mcp-for-multi-repo-wayfinding.md) —
  why this tool, why the whole corpus, and the alternatives rejected
- [docs/qmd.md](qmd.md) — the launchd agent pattern this setup is modelled on
