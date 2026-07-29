# Claude Code Integration

How this repo manages [Claude Code](https://code.claude.com): its settings,
plugins, MCP servers, and the guardrails that keep tooling reproducible.

The design rationale lives in
[ADR-006](adrs/006-declarative-claude-code-extensions.md). This doc is the
operational reference.

## Who owns `~/.claude/settings.json`

`settings.json` has three writers. Knowing which owns a key prevents the drift
that ADR-006 exists to fix — never hand-edit a key another writer owns.

| Owner | Keys | Where |
|-------|------|-------|
| **`bin/sync-claude-settings`** (jq, run on apply) | `permissions`, `model`, `env`, `statusLine`, `includeCoAuthoredBy`, feature flags, and the `hooks` guard entry | this repo |
| **the `claude` CLI** (driven by `bin/sync-claude-extensions`) | `extraKnownMarketplaces`, `enabledPlugins`, and `~/.claude.json` `mcpServers` | declarative data → CLI |
| **Claude Code UI / runtime** | `theme`, `editorMode`, `preferredNotifChannel`, … | left alone |

## Extensions: plugins and MCP servers

Declared state is realized by an idempotent reconciler, not hand-installed.

- **Declared in** [`home/.chezmoidata/claude-extensions.yaml`](../home/.chezmoidata/claude-extensions.yaml)
  under `claudeExtensions` (`marketplaces`, `plugins`, `mcpServers`).
- **Realized by** `bin/sync-claude-extensions`, which calls
  `claude plugin marketplace add` / `claude plugin install` / `claude mcp add`.
  It is additive (only adds what's missing), reports installed-but-undeclared
  items as drift (`--prune` to remove), skips `managed` scope, and `--check`
  is a dry run.
- **Triggered by** `run_onchange_sync-claude-extensions.sh.tmpl` on `chezmoi apply`
  — it re-runs when the reconciler, the committed base set, or the machine-local
  extras change.

The committed file is **public OSS only** — this repo is public. The `claude` CLI
is the single writer of the plugin/MCP keys; `sync-claude-settings` deliberately
does not touch them.

### Scope is the source of truth

| Scope | Source of truth | Reproducible via |
|-------|-----------------|------------------|
| **user** | the dotfiles repo (`chezmoi source-path`) | `chezmoi apply` |
| **project** | the current repo (`.mcp.json`, `.claude/settings.json`) | that repo |
| **local** | machine + project local | nothing (ephemeral) |

**Reach-in invariant:** a user-scope change edits the chezmoi *source* and applies
it — it never runs a tool's native `--scope user`/`--global` command from a foreign
cwd (that writes the live file out-of-band from chezmoi). The `/install` skill
encodes this, so adding an extension is one command from any directory.

### Adding an extension

Use the `/install` skill — it classifies type and scope and routes correctly,
including the exact `claude mcp add` / `.mcp.json` forms. Don't run installers by
hand (the guard hook blocks them).

### MCP server fields

Each `mcpServers` entry — in the committed base or in machine-local extras —
accepts:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Server name; the reconciler's identity key |
| `transport` | no | `stdio` (default), `http`, or `sse` |
| `command` | `stdio` | Executable, resolved from `PATH` at launch |
| `args` | no | Arguments passed after `command` |
| `url` | `http`/`sse` | Endpoint URL |
| `env` | no | Map of environment variables for the server process |
| `headers` | no | Map of HTTP headers |

```yaml
mcpServers:
  - name: qmd          # stdio
    transport: stdio
    command: qmd
    args: [mcp]
  - name: internal-wiki   # http
    transport: http
    url: https://mcp.internal.example/mcp
```

The reconciler emits
`claude mcp add <name> [url] --scope user --transport <t> [--env K=V …] [--header "K: V" …] [-- <command> <args…>]`.
Positionals precede the flags because `--env` and `--header` are variadic.

### Machine-local extras (private / employer-internal)

Anything that must not be committed to this public repo — private marketplaces,
internal MCP endpoints, secrets — goes in machine-local
`~/.config/chezmoi/chezmoi.toml` under `[data.claudeExtensionsExtra]`, which the
reconciler merges with the committed base. Example:

```toml
[data.claudeExtensionsExtra]
plugins = ["internal-plugin@private-marketplace"]

[[data.claudeExtensionsExtra.marketplaces]]
name = "private-marketplace"
repo = "your-org/claude-plugins"   # private; needs gh auth / GITHUB_TOKEN

[[data.claudeExtensionsExtra.mcpServers]]
name = "internal-wiki"
transport = "http"
url = "https://mcp.internal.example/mcp"
```

Never put a bearer token or API key in plaintext — use a 1Password reference
(below). Private marketplaces authenticate via your git credential helper
(`gh auth`); the reconciler exports `GITHUB_TOKEN` from `gh auth token` when `gh`
is present.

### Secrets: 1Password references

Any `env` or `headers` value may embed one or more
`${op://<vault>/<item>/<field>}` references. `bin/sync-claude-extensions` resolves
them with `op read` at apply time and hands the literal value to `claude mcp add`;
only the reference lives in chezmoi data.

```toml
[[data.claudeExtensionsExtra.mcpServers]]
name = "internal-wiki"
transport = "http"
url = "https://mcp.internal.example/mcp"

[data.claudeExtensionsExtra.mcpServers.headers]
Authorization = "Bearer ${op://Private/Internal Wiki/credential}"
```

| Property | Behavior |
|----------|----------|
| Scope | `env` and `headers` values only — not `url`, `command`, or `args` |
| Timing | Resolved on `chezmoi apply`, immediately before `claude mcp add` |
| Requires | `op` on `PATH` and an authenticated 1Password session |
| `--check` | References are left unresolved — a dry run never resolves or prints a secret |
| Logging | `--env` / `--header` values are masked as `<redacted>` in reconciler output |
| On failure | Missing `op`, unreadable reference, or empty value → warning, that one server is skipped, the run continues |
| Limit | Multiple references per value are allowed; at most 16 substitutions per value |

Resolved values land in `~/.claude.json` in plaintext. That file is not managed by
chezmoi and must never be committed.

**Rotation.** The reconciler only adds servers that are *missing*, so changing a
value in 1Password does not update a server already present in `~/.claude.json`.
Run `claude mcp remove <name>`, then `chezmoi apply`, to re-resolve.

**`DEBUG=1`** enables `set -o xtrace`, which prints resolved secrets to stderr and
bypasses the masking above. Do not use it in a shared terminal or a captured log.

Sync-time resolution is deliberate: the alternative — leaving a `${VAR}` for Claude
Code to expand at runtime — would place the secret in the environment of every
subprocess an agent spawns. See
[ADR-006](adrs/006-declarative-claude-code-extensions.md).

### Versioning: plugins float

Plugins are **not** version-pinned — a scoped exception to the
[pinned supply chain](supply-chain-security.md) policy, because the marketplaces
used version plugins by commit SHA and publish no tags, so `claude plugin install`
cannot pin them. Updates are agent-driven via `claude plugin update`
(e.g. during `/update`). See [ADR-006](adrs/006-declarative-claude-code-extensions.md)
for the full reasoning and revisit conditions.

## Guard hook: no ad-hoc installers

A global `PreToolUse`/`Bash` hook
([`home/dot_local/libexec/executable_block-adhoc-installers`](../home/dot_local/libexec/executable_block-adhoc-installers),
registered by `sync-claude-settings`' `set_hooks()`) denies `npx`, `pipx run`,
`pip install`, `npm i -g`, `gem install`, `brew install`, `cargo install`,
`go install`, and friends, redirecting to `/install`. This keeps tools captured in
mise / the dotfiles instead of drifting in ad hoc. It leaves normal usage
(`npm test`, `pip show`, `mise install`) alone.

**Bypass (humans only):** set `CLAUDE_ALLOW_ADHOC_INSTALL=1` in the environment and
the hook defers to the normal permission classifier. An agent cannot set this for
itself — an inline `FOO=1 npx …` prefix doesn't reach the hook's process, and
per-Bash-call environment doesn't persist.

## Where things live

| Path | Purpose |
|------|---------|
| `bin/sync-claude-settings` | writes the script-owned `settings.json` keys + guard hook |
| `bin/sync-claude-extensions` | reconciles marketplaces / plugins / MCP servers |
| `home/.chezmoidata/claude-extensions.yaml` | committed public base set |
| `home/run_onchange_sync-claude-extensions.sh.tmpl` | apply-time trigger |
| `home/dot_local/libexec/executable_block-adhoc-installers` | the guard hook |
| `home/dot_claude/skills/install/` | the `/install` router skill |
| `~/.config/chezmoi/chezmoi.toml` `[data.claudeExtensionsExtra]` | machine-local private extras (uncommitted) |
