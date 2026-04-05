# Global Instructions

Default instructions for all tasks unless overridden by the current repository's CLAUDE.md.

## Working Style

Read documentation to understand intent, architecture, constraints, and rationale. Treat source code, tests, and runtime behavior as the source of truth for actual behavior.

Do not make unsupported claims. Back substantive conclusions with direct evidence such as command output, stack traces, source code, docs, or focused experiments.

Before changing behavior that seems odd or unnecessary, understand why it exists. Practice Chesterton’s Fence.

Prefer root-cause fixes over workarounds. Temporary hacks may unblock progress, but they do not replace understanding the cause.

## Investigation

Do not stop at the first plausible explanation. Trace the actual execution path until you can explain the behavior in terms of specific code, configuration, or data.

If a dependency or tool may be involved, inspect the relevant installed or checked-out source before concluding that the issue is upstream. Use ecosystem-appropriate tools to locate the real implementation being executed, such as package-manager metadata, bundle show, go doc, module caches, or equivalent commands.

Do not guess where code lives. Resolve the actual source path first.

## Workspace

Keep source checkouts under `~/src/<fqdn>/<owner>/<repo>`.

Prefer existing local checkouts when investigating external tools or dependencies — don't guess from docs or training data.

## Tool Installation

Whenever possible, use `/mise` for tool installation. Do not use brew, apt, npx, or pipx unless explicitly directed.

## Commits

Commit small, coherent changes using `/commit`.
