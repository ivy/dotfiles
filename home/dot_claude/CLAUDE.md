# Global Instructions

Default instructions for all tasks unless overridden by the current repository's CLAUDE.md.

## Working Style

Read documentation to understand intent, architecture, constraints, and rationale. Treat source code, tests, and runtime behavior as the source of truth for actual behavior.

Do not make unsupported claims. Back substantive conclusions with direct evidence such as command output, stack traces, source code, docs, or focused experiments.

Before changing behavior that seems odd or unnecessary, understand why it exists. Practice Chesterton’s Fence.

Prefer root-cause fixes over workarounds. Temporary hacks may unblock progress, but they do not replace understanding the cause.

## Writing

Documents and comments state current facts, not their own history. Revision narration ("it was X, now it's Y") belongs in a git commit message, not in the document itself.

Comments stay in scope of the code they annotate. Don't use a comment to explain an external API, library, or system — that documentation rots the moment upstream changes. Link to authoritative docs instead of restating them; if staying in-scope requires more context than a comment can hold, that's a signal to refactor the abstraction, not to narrate around it.

## Context

Start non-trivial work with `/gather-context` instead of reading files ad hoc. Pulling the issue, the relevant code, git history, and linked references together up front is cheaper than discovering a constraint halfway through an implementation.

Two local indexes support that, and they answer different questions:

- **qmd** — knowledge retrieval over the markdown vault: notes, decisions, meeting records, prior research. Use it for "what do I already know about this?"
- **codebase-memory** — a code graph over every repository in `~/src`: which repo defines a symbol, who calls a function, what a change would ripple into. Use it for "where does this live?" and "what depends on this?", especially in repositories you have never worked in. Project names are derivable from the path — `~/src/github.com/owner/repo` is `github-com-owner-repo` — so there is no need to enumerate them.

Both locate; neither is authoritative about behavior. Follow a hit back to the source and read it before concluding anything, because an index can be stale in ways it cannot signal.

## Investigation

Do not stop at the first plausible explanation. Trace the actual execution path until you can explain the behavior in terms of specific code, configuration, or data.

If a dependency or tool may be involved, inspect the relevant installed or checked-out source before concluding that the issue is upstream. Use ecosystem-appropriate tools to locate the real implementation being executed, such as package-manager metadata, bundle show, go doc, module caches, or equivalent commands.

Do not guess where code lives. Resolve the actual source path first.

## Continuous improvement

When something slows you down mid-task, name it in a line or two at the end of your turn. Report only friction you actually hit this turn, not hypotheticals, and list at most one or two. If nothing got in your way, say nothing — don't invent friction, and don't report its absence.

Friction worth naming:
- documentation that was wrong and cost extra debugging steps
- poor errors or diagnostics that don't give enough information to diagnose the problem
- noisy messages that fill the context window
- a workaround for a bad API that makes the code worse
- a step with no shortcuts, done by hand several times

Just name it — don't fix or file it unless asked. Don't pad the reply or restate points already made; surface only what hasn't come up.

## Workspace

Keep source checkouts under `~/src/<fqdn>/<owner>/<repo>`.

Prefer existing local checkouts when investigating external tools or dependencies — don't guess from docs or training data.

## Tool Installation

Whenever possible, use `/mise` for tool installation. Do not use brew, apt, npx, or pipx unless explicitly directed.

## Commits

Commit small, coherent changes using `/commit`.

@RTK.md
