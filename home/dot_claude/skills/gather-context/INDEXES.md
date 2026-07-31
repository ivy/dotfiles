# Querying the local indexes

Correct call patterns for the two MCP indexes `/gather-context` draws on. Read this
when a query returns nothing useful — the usual cause is the wrong tool or the wrong
argument shape, not a missing fact.

Both indexes **locate**. Neither is authoritative about behaviour: a hit is a pointer
to `Read`, never the finding itself. A stale index answers confidently and gives no
signal that it is out of date.

## codebase-memory — structure across every repo in `~/src`

### Project names are derived, not looked up

`~/src/<host>/<owner>/<repo>` → `<host>-<owner>-<repo>`, every `.` and `/` replaced
by `-`. **Case is preserved** — the lookup is exact, so an owner or repo with
capitals keeps them:

```
~/src/github.com/backstage/backstage  →  github-com-backstage-backstage
~/src/github.com/Gusto/glide          →  github-com-Gusto-glide      ← not "gusto"
```

Lowercasing an owner is a hard miss, not a fuzzy one: `github-com-gusto-glide`
returns "project not found or not indexed".

**Do not call `list_projects`.** It returns roughly 66,000 characters here and
overruns the per-result budget. If the full roster is genuinely needed, call
`index_status` with a deliberately bogus project name — the error payload carries
every indexed name in about four kilobytes.

### Picking a tool

| Question | Tool |
|---|---|
| Where is this defined? What handles this concept? | `search_graph` |
| Every occurrence of a literal, grouped by containing function | `search_code` |
| Who calls this? What would a change here reach? | `trace_path` |
| Read one symbol I already have the name of | `get_code_snippet` |
| Aggregates, multi-hop patterns, complexity hunting | `query_graph` |
| Shape of a repo I have never opened | `get_architecture` |
| Is this indexed, and how big is it? | `index_status` |

### Argument shapes that bite

- **`search_graph`** has three independent modes. `query` is BM25 over natural
  language and splits camelCase (`updateCloudClient` → update, cloud, client),
  boosting Functions/Methods over Classes over noise. `name_pattern` is a regex and
  is **ignored when `query` is present**. `semantic_query` **must be an array of
  keyword strings**, not one string, and its hits come back in a separate
  `semantic_results` field. Check `has_more`; page with `offset`.
- **`search_code`** dedupes grep hits into containing functions. Compare
  `total_results` against your `limit` to detect truncation — there is no `offset`,
  so narrow with `file_pattern` or `path_filter` instead.
- **`trace_path`** takes `mode` of `calls`, `data_flow`, or `cross_service`, and a
  `direction` of `inbound` (callers), `outbound` (callees), or `both`. Test files
  are excluded unless `include_tests` is set.
- **`get_code_snippet`** is a read, not a search. Get the exact `qualified_name`
  from `search_graph` first; a bare name returns ambiguous suggestions.
- **`get_architecture`** is large unscoped. Pass `aspects` — `clusters` gives the
  de-facto modules with cohesion scores and often reveals seams that cut across the
  folder layout. `path` scopes it to a subtree.
- **`query_graph`** is Cypher with a 100k row ceiling; add `LIMIT`. Call
  `get_graph_schema` first if you are unsure which node labels and edge types a
  project actually has — they vary by language mix. Function and
  Method nodes carry `complexity`, `cognitive`, `loop_count`, `loop_depth`,
  `transitive_loop_depth`, and `linear_scan_in_loop`, so hot-path questions are one
  query rather than a reading exercise. Treat `transitive_loop_depth` as a
  worst-case bound propagated along call edges, not a measured nesting depth.

## qmd — knowledge in the markdown vault

Notes, decisions, meeting records, prior research. The question it answers is "what
do I already know about this?"

- `query` takes sub-queries: `lex` (BM25, exact terms), `vec` (semantic), and `hyde`
  (write what the answer would look like). Combining `lex` and `vec` beats either
  alone. **Always pass `intent`** — it disambiguates and improves snippets.
- `minScore: 0.5` filters low-confidence hits.
- `get` retrieves one document by path or `#docid`, and accepts a line offset
  (`file.md:100`). `multi_get` takes a glob or comma-separated list.
- `status` lists collections and document counts.

Two qmd servers may both be connected — the chezmoi-managed `qmd` and a
plugin-provided duplicate. They index the same vault, but only the `mcp__qmd__*`
tools are pre-approved; reach for those, never `mcp__plugin_qmd_qmd__*`.

## When the indexes are the wrong tool

- The change is in an uncommitted working tree — the index reflects the last
  reindex, so read the files.
- The question is about behaviour under specific inputs — that is a test or a run,
  not a graph query.
- The repo is not under `~/src`, so it is not indexed at all. Check with
  `index_status` before assuming absence means the code does not exist.
