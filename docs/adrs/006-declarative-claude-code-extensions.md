---
status: "accepted"
date: 2026-06-03
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Manage Claude Code Extensions Declaratively via a Scope-Aware Reconciler

## Context and Problem Statement

Claude Code plugins and MCP servers had no reproducible management path, and the
configuration that existed had drifted three ways: `set_plugins()` in
`bin/sync-claude-settings` declared one marketplace and one plugin; the live
`~/.claude/settings.json` had grown by hand to three marketplaces and six enabled
plugins; and the machine actually had five marketplaces and ten plugins installed.
None of it reproduced on a fresh machine.

The root cause is a layering confusion. **Registration/enable** —
`extraKnownMarketplaces` and `enabledPlugins` in `settings.json` — is not the same
as **installation**. The clone into `~/.claude/plugins/cache/` plus the
`installed_plugins.json` record is performed only by the `claude plugin` CLI.
Writing `enabledPlugins` from a jq script enables plugins that may not be installed
and fights the CLI, which writes those same keys at `--scope user`. MCP servers have
the identical gap (`claude mcp add`, writing the app-owned `~/.claude.json`).

Two further forces shape the decision: this dotfiles repo is **public** (so
employer-internal references must not be committed), and the project's pinning
policy (ADR-005, `docs/supply-chain-security.md`) says every dependency gets an
exact version pin managed by Renovate — which the Claude Code plugin ecosystem
cannot satisfy for third-party marketplaces.

How should Claude Code extensions be installed, kept reproducible, and updated?

## Decision Drivers

* **Reproducibility**: A fresh machine MUST converge to the same extensions from
  version-controlled source, not from interactive `/plugin` clicks
* **Single source of truth**: One writer per settings key — no script-vs-CLI drift
* **Agent-first (Principle 1)**: Adding an extension MUST be a one-command,
  scope-aware operation an agent can drive from any directory
* **Supply chain (Principle 3)**: Versions SHOULD be pinned and Renovate-managed —
  but the mechanism MUST degrade honestly where the ecosystem cannot support it
* **Security**: A public repo MUST NOT leak employer-internal infrastructure
  (private marketplace names, MCP proxy endpoints)
* **No silent blocks**: Guardrails against ad-hoc installs SHOULD explain and
  redirect, not fail opaquely (consistent with the project's allowlist-not-denylist
  permissions stance)

## Considered Options

1. **Settings-declaration only**: Extend `set_plugins()` to write
   `extraKnownMarketplaces`/`enabledPlugins`, relying on Claude Code's startup
   plugin-sync to clone and install
2. **CLI-driven reconciler from declarative data**: A version-controlled data file
   drives an idempotent script that realizes state through the `claude` CLI
3. **Container seed directory**: Pre-populate `CLAUDE_CODE_PLUGIN_SEED_DIR` at
   build time

## Decision Outcome

Chosen option: **CLI-driven reconciler from declarative data**, because it
deterministically produces the on-disk install state, makes the `claude` CLI the
single writer of plugin/MCP keys, and reproduces on a fresh machine — while the
settings-declaration approach is interactive-prompt-gated and not reliably headless,
and the seed directory targets containers, not a workstation.

Five sub-decisions follow from this:

* **CLI as realizer, single writer.** `bin/sync-claude-extensions` reads declarative
  data and calls `claude plugin marketplace add` / `claude plugin install` /
  `claude mcp add`. The CLI owns `extraKnownMarketplaces`, `enabledPlugins`, and
  `~/.claude.json` `mcpServers`. `set_plugins()` is removed.
* **Scope → source-of-truth routing.** A single global `/install` skill routes by
  scope: **user** → edit the chezmoi *source* manifest (resolved via
  `chezmoi source-path`) then `chezmoi apply` — the **reach-in invariant**: never run
  a tool's native `--global`/`--scope user` command from a foreign cwd, because that
  writes the live file out-of-band from chezmoi; **project** → run the CLI in the cwd
  repo, writing that repo's committed `.mcp.json` / `.claude/settings.json`; **local**
  → ephemeral.
* **Float, not pin (a scoped exception to Principle 3).** Plugins track their
  marketplace's default branch. See the dedicated analysis below.
* **Public-repo split.** The committed data file holds public OSS entries only;
  employer-internal refs live in machine-local `[data.claude_extensions_extra]`
  (uncommitted) and are merged by the reconciler at runtime.
* **Guard hook.** A global `PreToolUse`/`Bash` hook denies ad-hoc installers
  (`npx`, `pipx run`, `pip install`, `npm i -g`, …) with a message redirecting to
  `/install`, with a process-env bypass (`CLAUDE_ALLOW_ADHOC_INSTALL=1`) the agent
  cannot set itself.

### Implementation

`home/.chezmoidata/claude-extensions.yaml` (public base set) + machine-local
`[data.claude_extensions_extra]` → `bin/sync-claude-extensions` (idempotent,
additive, `--prune` opt-in, skips `managed` scope) → `home/run_onchange_sync-claude-extensions.sh.tmpl`.
`set_plugins()` is deleted from `bin/sync-claude-settings`; `set_hooks()` registers
the guard. The consolidated `/install` skill supersedes `install-tool` and the
project-scoped `install`.

### Consequences

* **Good**: Fresh-machine reproducibility — `chezmoi apply` converges plugins + MCP
  servers from source
* **Good**: No more drift — one writer per key; the reconciler reports (not silently
  removes) undeclared installs
* **Good**: Adding an extension is one scope-aware command from anywhere, with the
  exact `claude mcp add` / `.mcp.json` forms encoded in the skill
* **Good**: The public repo leaks no employer-internal topology
* **Good**: The guard hook stops the most common drift source (agents reaching for
  `npx`/`pipx`) with an actionable redirect rather than a silent denial
* **Bad**: Plugins are not version-pinned (see analysis) — a regression in a
  marketplace's default branch can reach the machine on update
* **Bad**: Two data sources (committed base + machine-local extras) — the
  private entries must be set up once per machine, out of band
* **Neutral**: MCP user-scope state lives in app-owned `~/.claude.json`, not a
  chezmoi-managed file; reproducibility comes from re-running the reconciler, not
  from chezmoi owning the file

## Pros and Cons of the Options

### Settings-declaration only

Write `extraKnownMarketplaces`/`enabledPlugins` and let Claude Code's startup
plugin-sync clone and install.

* **Good**: Smallest change; no new script
* **Good**: Declarative in a file chezmoi-adjacent tooling already manages
* **Bad**: Enabling ≠ installing — declares state the startup sync may not realize
  headlessly; project scope is trust-prompt-gated
* **Bad**: Two writers (jq script + `claude` CLI) on the same keys — the drift this
  ADR exists to fix

### CLI-driven reconciler from declarative data

A version-controlled data file drives an idempotent reconciler through the `claude`
CLI.

* **Good**: Deterministic install state; single writer; reproducible
* **Good**: Same model extends cleanly to MCP servers (`claude mcp add`)
* **Good**: Idempotent + drift-report composes with the `/update` routine
* **Bad**: New script + wrapper + tests to maintain
* **Bad**: Depends on the `claude` CLI being present and on network/auth at apply time

### Container seed directory

Pre-populate `CLAUDE_CODE_PLUGIN_SEED_DIR` at image build time.

* **Good**: Zero runtime cloning; ideal for CI/containers
* **Bad**: Read-only, build-time model — wrong fit for an interactive workstation
* **Bad**: Doesn't solve the settings-drift or scope-routing problems

## More Information

### Why float, not pin (the Principle 3 exception)

Principle 3 and ADR-005 require exact version pins managed by Renovate. Claude Code
plugins cannot satisfy this through the public install path:

* A plugin's version is resolved from `plugin.json` → the marketplace entry → the
  git commit SHA. Pinning lives in the **marketplace's** `marketplace.json`, which we
  do not own for third-party marketplaces (`pickled-claude-plugins`, `plannotator`).
* The marketplace *source* supports a `ref` (branch/tag) but not a `sha`; the
  marketplaces we use version plugins by commit SHA and publish no tags, so a Renovate
  ref-bump manager would have nothing stable to track.
* `claude plugin install` tracks the marketplace's default branch; there is no
  flag to pin an installed plugin to a SHA.

Pinning would therefore be theatre — a pinned `ref` that still floats underneath.
The honest design is to **float and make updates agent-driven**: `claude plugin
update` run from the `/update` routine, where a human/agent reviews the change. This
is a deliberate, scoped exception to Principle 3 for one dependency class whose
ecosystem does not support pinning, not a general relaxation. It is revisited if the
marketplaces we depend on begin publishing tags/releases (see below).

### Public-repo handling

`ivy/dotfiles` is public. Committing private marketplaces, internal-only plugins,
or internal MCP endpoint URLs would publish private tool topology — even when those
URLs are OAuth-gated rather than standalone credentials. They are kept out of the
repo as infra hygiene and live in machine-local `[data.claudeExtensionsExtra]` in
`~/.config/chezmoi/chezmoi.toml`, merged by the reconciler at runtime. Any true
secret (a bearer header or API key on an MCP server) must be sourced from 1Password,
never committed.

### Revisit When

* A marketplace we depend on starts publishing tags/releases — add a Renovate
  custom manager to bump a pinned `ref` in `claude-extensions.yaml`, narrowing the
  float exception
* Claude Code adds a first-class way to pin an installed plugin to a SHA
* MCP user-scope configuration moves to a chezmoi-manageable file, letting chezmoi
  own it directly instead of via the reconciler
