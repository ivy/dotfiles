---
status: "accepted"
date: 2026-01-31
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Use envsense for Agent-Optimized Shell Configuration

## Context and Problem Statement

AI coding agents (Claude Code, Codex, Cursor, Cline) shell out to standard Unix commands (`ls`, `grep`, `cat`, `find`). Our zsh config aliases these to enhanced alternatives (ls→eza, cat→bat, grep→grep -Hn) which changes output format and breaks agent expectations. Agents also pay the startup cost of interactive plugins (oh-my-zsh, atuin, syntax highlighting) they don't benefit from.

How should `.zshrc` detect agent contexts and conditionally disable human-centric features while preserving essential tooling (PATH, mise, env vars)?

See: [GitHub Issue #104](https://github.com/ivy/dotfiles/issues/104)

## Decision Drivers

- **Correctness**: Detection MUST distinguish agents from humans accurately — false positives strip features from human shells, false negatives break agent output parsing
- **Maintainability**: New agents appear regularly; detection logic SHOULD have a single source of truth
- **Startup performance**: Detection SHOULD add negligible latency to shell startup
- **No bootstrap fragility**: Detection MUST work in the environments where it matters (agent shells have mise available)

## Considered Options

1. **Inline env var checks** — hardcode agent env var detection directly in `.zshrc`
2. **envsense integration** — delegate detection to the envsense CLI tool
3. **Hybrid approach** — use envsense when available, fall back to inline checks

## Decision Outcome

Chosen option: **envsense integration**, because it provides a single source of truth for environment detection with proven correctness, override mechanisms, and zero maintenance burden in `.zshrc`.

### Consequences

- **Good**: Single source of truth — agent detection logic lives in envsense, not duplicated in shell config
- **Good**: Correct out of the box — envsense already distinguishes Cursor from VS Code (requires `CURSOR_TRACE_ID`, not just `TERM_PROGRAM=vscode`), detects 8 agents, 4 IDEs, and 13 CI systems
- **Good**: Built-in overrides — `ENVSENSE_ASSUME_HUMAN=1` forces full interactive shell when needed, no `.zshrc` changes required
- **Good**: New agents are supported by updating envsense, not editing dotfiles
- **Bad**: Adds a runtime dependency on the envsense binary
- **Neutral**: Subprocess cost on every shell startup (~2.6ms mean, negligible vs. plugin load times)
- **Neutral**: envsense is installed via mise, which is already required for agent shells

### Confirmation

Implementation success will be confirmed by:
- `envsense -q check agent` returns exit 0 in Claude Code, Codex, and Cursor agent shells
- `envsense -q check agent` returns exit 1 in interactive human terminals (including Cursor's integrated terminal when used by a human)
- Aliases (`ls`, `cat`, `grep`) produce standard POSIX output in agent shells
- Shell startup time in agent contexts is measurably faster than the unguarded baseline
- Human shells retain all interactive features unchanged

## Rejected Options

### Inline env var checks

Hardcode detection in `.zshrc` using known agent environment variables (`CLAUDECODE`, `CODEX_CLI`, `CI`, etc.).

- **Good**: Zero dependencies — pure shell, no external tools
- **Good**: Zero startup cost — env var reads are free
- **Bad**: Duplicates logic that envsense already implements correctly
- **Bad**: Error-prone — the original issue proposal already contained two detection bugs (wrong env var name for Claude Code; `TERM_PROGRAM=vscode` catches human Cursor terminal users)
- **Bad**: Every new agent requires editing `.zshrc` and redeploying dotfiles
- **Bad**: No override mechanism without adding more ad-hoc env var checks

### Hybrid approach

Use envsense when available, fall back to inline env var checks otherwise.

- **Good**: Works even if envsense isn't installed
- **Bad**: Two code paths to maintain and test
- **Bad**: The fallback path has the same correctness problems as pure inline checks
- **Bad**: Unnecessary complexity — agent shells require mise, and mise provides envsense

## More Information

### Why Not the Hybrid Approach

The bootstrap concern ("what if envsense isn't installed?") doesn't apply because:
1. Agent shells require mise for tool version management
2. mise provides envsense
3. A shell without mise is already broken for agents — missing envsense doesn't make it worse
4. On a fresh machine before first provisioning, the user is human and gets the correct default (full interactive shell)

### Revisit When

- envsense startup cost regresses beyond 20ms (currently ~2.6ms; consider caching or a shell-native fast path)
- A significant agent doesn't set any detectable env vars (would require process ancestry detection)
