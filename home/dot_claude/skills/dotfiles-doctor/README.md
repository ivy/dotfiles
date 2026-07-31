# `/dotfiles-doctor` — Health Check for the Background Machinery

Probes the launchd jobs, MCP servers, and local indexes that this environment quietly
depends on, repairs what is safely repairable, and reports a verdict per subsystem.

```
/dotfiles-doctor
/dotfiles-doctor codebase-memory
/dotfiles-doctor launchd
```

## Why this exists

Everything this checks fails **silently**. That is the whole problem.

- **A reindex job stops firing.** Nothing announces it. Search keeps working, just
  against a frozen index, and the answers stay confidently wrong until someone
  notices a file that should obviously have matched.
- **A tool upgrade wedges a daemon.** Every codebase-memory process must share one
  build fingerprint, and `mise prune` deletes the old build from under a warm
  daemon. The symptom surfaces hours later as "the MCP server stopped responding,"
  with nothing linking it to the upgrade that caused it.
- **A node ABI bump breaks qmd's native addon.** Global `NPM_CONFIG_IGNORE_SCRIPTS`
  blocks the postinstall that would fetch it, so the rebuild has to happen on
  purpose. Until it does, every qmd invocation dies at `require`.
- **A repo never gets indexed.** A linked worktree's `.git` is a file rather than a
  directory, so a `-type d` filter skips it and the repo is simply absent — with no
  error anywhere, because nothing tried and failed.

Each is cheap to detect and cheap to fix. None is discoverable by waiting. The
absence of an error message is the failure mode, so the check has to be deliberate.

## What it repairs on its own

Convergence back to declared state, and nothing else: reloading a launchd agent
that should be running, rerunning an index that has fallen behind, stopping a
daemon holding a stale build fingerprint. These are idempotent and cost seconds.

It will not delete an index, run `chezmoi apply` over destination drift, or
reinstall a tool. Those are minutes-to-hours to undo and depend on context the
check cannot see — it prints the command and stops.

## Known regressions it watches for

Two failure signatures specific to codebase-memory, both invisible from the outside
and both diagnosed the hard way. Background lives in `docs/codebase-memory-mcp.md`
in the dotfiles repo — named rather than linked, since this file is read both from
the repo and from `~/.claude/skills/`, and no relative path is correct in both.

| Signature | Cause |
|---|---|
| Project names beginning `Users-` | Something indexed without `--name`, taking CBM's path-derived default. Dots in the derived name break package attribution, so every cluster label collapses to a fragment of the path. |
| Project names beginning `[` | A `cli --target-projects '["*"]'` call. The flag does not parse its JSON, so the raw string becomes a project name and a database is created under it. |

Neither raises an error. Both just quietly degrade what the graph can answer.

## Scope

macOS-specific — the scheduled jobs are launchd agents and there is no Linux
equivalent wired up yet. On Linux the MCP, qmd, mise, and chezmoi checks still
apply; the launchd section reports as not applicable rather than broken.
