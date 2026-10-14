# Codebase Memory

The `codebase-memory` MCP tools query a code graph over every repository under `~/src`. They locate code; they don't explain it. Every answer is a pointer — `Read` the file it names before concluding anything about behavior.

## When to use it

Reach for it when the answer is outside the repository you're in, or you don't know where to look:

- A symbol, gem, client, or service comes from another repository and you need its definition — `search_graph` across the likely owners beats guessing a path.
- You're about to change a function and need to know what depends on it — `trace_path` gives the blast radius in one call instead of a chain of greps.
- You've landed in an unfamiliar repository and need its shape before reading files — `get_architecture` names the packages and entry points.
- You know roughly what code does but not what it's called — `semantic_query` bridges vocabulary that grep can't.

Skip it when plain tools are already precise: a known file, an exact string in the current repository, or a single definition `Grep` will find on the first try. The graph also can't see what isn't under `~/src`, so for installed dependencies resolve the real source with the package manager instead.

## Naming the project

Every tool takes a `project`. Derive it from the checkout path instead of looking it up: drop `~/src/`, then map `.` and `/` to `-`, preserving case. `~/src/github.com/Gusto/glide` is `github-com-Gusto-glide`; lowercasing `Gusto` is a miss.

Don't call `list_projects` to find a name — its output overflows the result budget. The roster embedded in an unknown-project error is partial, so a name missing from it may still be indexed; call `index_status` on the derived name to be sure.

## Picking a tool

- `search_graph` — find a definition. `query` for keywords (BM25), `name_pattern` for a regex on the symbol name, `semantic_query` (an array of keywords) when the vocabulary is unknown. Narrow with `label` (`Function`, `Method`, `Class`) or `file_pattern`.
- `search_code` — grep for a text pattern, with matches grouped by the function that contains them. Use it for strings, config keys, and anything that isn't a symbol.
- `get_code_snippet` — source for a `qualified_name` from `search_graph`.
- `get_file_outline` — the declarations in one file, in source order, for picking what to `Read` in a large file.
- `trace_path` — callers and callees of a function, to a given `depth`. Needs an exact name, so find it with `search_graph` first.
- `detect_changes` — map the working tree's git diff to the symbols it touches and what depends on them.
- `query_graph` — Cypher for anything the others can't express. Methods carry the `Method` label, not `Function`; match unlabeled (`MATCH (f) WHERE f.name = ...`) when unsure. Call `get_graph_schema` for the labels and edge types a project actually has.
- `get_architecture` — packages, entry points, and clusters, for orienting in an unfamiliar repository.
- `index_status` — whether a project exists, its root path, and when it was indexed.
- `check_index_coverage` — whether the index recorded gaps for specific files or directories. See below.

## Claims of absence

Finding something is cheap and self-verifying: the source either matches or it doesn't. Claiming something _isn't_ there — no callers, dead code, a complete list of impact — is where the graph misleads, and it needs more:

- **Follow references, not just calls.** `trace_path` follows only `CALLS` edges by default. A function stored in a map, handed to a router, or registered as a callback is linked by a `USAGE` edge instead, so pass `edge_types: ["CALLS", "USAGE"]`. Dispatch by string — `send`, reflection, config-driven lookups — has no edge at all; grep for the name.
- **Read every page.** `search_graph` returns 50 results per page by default and `search_code` 10. Both report `has_more`; page `search_graph` with `offset` and `search_code` with `result_offset`.
- **Check coverage.** Once you have the paths your answer rests on, call `check_index_coverage` once with all of them, adding the directories in `scopes` for a negative claim. Any status other than `no_recorded_issue` — partial, skipped, stale, unavailable — means read or grep that source before relying on the graph. A clean result means no recorded gap, not proof of completeness.

## Delegating

A subagent doesn't inherit this conversation's graph results. Before delegating, pass along the exact project name, qualified names, file paths, and what coverage reported, so the child starts from evidence instead of re-deriving it.
