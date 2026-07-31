---
status: "accepted"
date: 2026-07-31
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Index All of ~/src with codebase-memory-mcp as a Wayfinding Layer

## Context and Problem Statement

Multi-repository context gathering is the most expensive manual step left in this
environment. There are hundreds of git repositories under `~/src` holding hundreds
of thousands of tracked files. An agent asked about code it hasn't seen falls back
to `rg`/`find` sweeps scoped by whatever paths the human types, and the workaround
has been to run a separate session whose only output is a handoff document for the
next agent. Both costs land on the human: naming the paths, and shepherding
the handoff.

The payoff is not in the repositories worked in daily — those are navigable
already. It is in the ones that are not known: shared libraries, generated
clients, services owned by other teams, third-party checkouts kept for reference.
Those are exactly the repositories where an agent cannot guess a path and the
human cannot supply one.

A landscape survey evaluated ten-plus candidates. Its framing targeted "hundreds
of private repositories" as an organizational service, which loaded the
requirements with repository ACL filtering, tenancy, permission-aware retrieval,
branch overlays, and index sharing across developers. Under those requirements it
recommended assembling a centralized control plane — Zoekt for corpus search,
SCIP for symbols, a Semble-like vector and reranking layer — and treated
`codebase-memory-mcp` as the best *pilot* rather than the answer.

This decision does not carry those requirements. It is one user, one machine, one
account, no tenancy, no ACL boundary, no cross-developer index sharing. Removing
the fleet control plane removes the entire reason the survey preferred assembly
over adoption, and the survey's top-ranked integrated candidate becomes the
outright answer.

## Decision Drivers

- **Coverage beats curation.** The value is concentrated in unknown repositories,
  so any scheme that starts with a curated list of familiar repositories inverts
  the payoff.
- **Source Truth (principle 4).** Agent infrastructure teaches agents *where to
  look*, not *what to know*. A code graph is structurally a pre-digested summary,
  and a summary agents trust is worse than a stale document. Whatever is adopted
  must locate primary sources rather than substitute for them.
- **Pinned supply chain (principle 3).** Exact version pin, Renovate-managed
  updates, verified artifacts. A tool installable only through its own bespoke
  installer is a liability.
- **Observable (principle 2).** The decision must rest on measurements taken on
  this machine against these repositories, not on vendor benchmarks.
- **Cost of being wrong is low.** The index is a disposable cache under
  `~/.cache/`. Nothing is committed, no working tree is modified, and reverting is
  `rm -rf` plus removing one line of config.

## Considered Options

1. **`codebase-memory-mcp` over all of `~/src`** — Tree-sitter across 158
   languages, LSP-assisted resolution, FTS5/BM25, bundled local embeddings, graph
   traversal, per-repo SQLite projects, stdio MCP
2. **`code-review-graph`** — explicit multi-repo registry, watcher daemon, stdio
   or HTTP, per-repo child processes and databases
3. **`codesearch`** — best operational architecture on paper: HTTP multi-repo,
   groups, lazy watchers, idle eviction, federated peers
4. **Zoekt + SCIP + Semble behind a minimal MCP gateway** — the survey's
   production recommendation
5. **Status quo** — `rg`/`find` plus hand-written handoff documents
6. **GitNexus** — technically near the top of the survey

## Decision Outcome

Chosen option:
**[`codebase-memory-mcp`](https://github.com/DeusData/codebase-memory-mcp),
indexing every repository under `~/src` as its own project**, installed through
mise's `github:` backend, refreshed by a periodic incremental job, and used as a
*locator* rather than an oracle.

Scope is everything, not a pilot subset, because measured cost does not justify
staging and because a curated subset would exclude the repositories that motivate
the work.

### Measured Evidence

Taken on this machine (M-series, 48 GB RAM) against these repositories at
version 0.9.0, `--mode full`:

The corpus contains one large Ruby monolith that dominates it — more tracked files
than the Linux kernel, and the large majority of the corpus by source bytes — plus
a long tail of small-to-medium repositories. Below, "the monolith" means that
repository and "the corpus" means every repository under `~/src`.

| Measurement | Result |
|---|---|
| Monolith, full index | 191s, 9.88 GiB peak RSS, 1.24M nodes / 2.97M edges |
| Monolith, incremental with no changes | 16.7s, 75 MB peak RSS |
| A repo with 12 GB of untracked build output | 1.5s — `target/` excluded by default |
| Monolith cache DB | ~3.5× its tracked source |
| **Bulk index, entire corpus, `--mode full`** | **387s, every repository succeeded, zero failures** (monolith warm at 18s; ~560s fully cold) |
| **Total cache after bulk index** | **7.3 GB, one DB per repository** |
| Slowest repositories in the bulk run | 62s and 36s for the two largest after the monolith; `backstage` 15s |
| `cross-repo-intelligence`, `target_projects=["*"]` | 42s, 122 projects scanned, 2 `CROSS_HTTP_CALLS` edges |
| Free disk | 68 GiB |

Upstream claims the Linux kernel (28M LOC, 75K files) in 3 minutes. A Ruby
monolith with more files than that, in 3m11s, is consistent with the claim — so it
holds on a workload materially unlike the one it was published against.

Two cautions raised before measurement did not survive it. The `~520s on
kubernetes` figure in `src/pipeline/pipeline.c:1063-1070` describes the *old*
sequential cross-file LSP pass that the current fused resolver replaced, not
present-day cost. And the concern that filesystem-based discovery would walk a
12 GB tree of untracked build output was wrong: default exclusions handled
`target/` without configuration.

Note that `--mode` does not gate cross-file LSP — every mode runs per-file and
cross-file resolution. Mode selects file filtering and similarity/semantic edges
only. `full` is affordable, so the ability to skip cross-file LSP via
`CBM_DISABLE_LSP_CROSS=1` is a crash workaround, not a tuning knob.

### Implementation

- Installation MUST use `github:DeusData/codebase-memory-mcp` in
  `home/dot_config/mise/config.toml` with an exact version pin, per ADR-005.
  Verified: mise selects the correct asset unaided, verifies the checksum, and
  reports `✓ GitHub artifact attestations verified`.
- Installation MUST NOT use `install.sh`, npm, or Homebrew. All three verify
  SHA-256 against a `checksums.txt` fetched from the same release as the artifact
  — integrity against a corrupted transfer, not authenticity. The cosign bundles
  and SLSA provenance the release process produces are checked by none of them.
  The mise path is strictly stronger here, not merely conventional.
- `auto_watch` SHOULD stay at its default of `true`. It registers a watcher for
  the *session's* project only — `register_watcher_if_enabled` uses
  `srv->session_project` (`mcp.c:11047-11057`) — so the cost is one watcher per
  concurrent session, not one per indexed repository. That gives live change
  detection on whichever
  repository is actively open, which the periodic job then backstops for
  everything else.
- `auto_index` MUST be `false`. Indexing on session start would block work behind
  a cold index of whatever directory the agent happened to launch in.
- The bulk index MUST run serially. Peak RSS is 9.88 GiB on the largest
  repository.
- `--persistence` MUST NOT be used. It writes `.codebase-memory/graph.db.zst`
  *into* the repository for team sharing; across every working tree in the corpus
  that is litter and a commit accident.
- The reindex job MUST run in `cli` mode, which never starts the coordination
  daemon, and MUST continue past a failing repository rather than aborting the
  cycle.
- `chezmoi apply` MUST stop the daemon before mise installs or prunes. All
  processes share one build fingerprint enforced by an admission barrier, and
  `home/run_onchange_00-install-mise-tools.sh.tmpl` runs `mise prune --yes`,
  which deletes the old version directory out from under a warm daemon.
- Projects MUST be named explicitly via `--name`, derived as the path under `~/src`
  with every byte outside `[A-Za-z0-9_-]` mapped to `-`
  (`github.com/owner/repo` → `github-com-owner-repo`). CBM's default derived name
  embeds the absolute path and preserves dots, and it reads a node's top-level
  package as the second dot-delimited segment of its qualified name
  (`cbm_qn_to_top_package`, `store.c:4852`) — so a dotted project name makes every
  cluster label and `packages` entry a fragment of the project name. This `$HOME`
  contains a dot and so does `github.com`, so the default is wrong here. Dot-free
  names also shorten the identifier agents pass on every call.
- `cross-repo-intelligence` MAY be run manually with `target_projects=["*"]`; it is
  deliberately *not* wired into the periodic job. The pass costs ~42s over the
  corpus and yields 2 edges here, and because `--name` is ignored in that mode it
  also leaves a 0-node project behind under the path-derived source name. Not worth
  paying every 30 minutes for that; revisit if cross-repo edges become numerous.
  Edges are written bidirectionally — `pass_cross_repo.c:514` emits "forward
  into source, reverse into target", `:830` writes into the target store, and
  `:1271` opens targets read-write for exactly this — so one pass makes each link
  visible from both sides and no per-project mesh is required. It MUST be invoked
  through the raw-JSON args form or the MCP tool, never the `--target-projects`
  flag; see the Consequences below.
- Agents SHOULD use the index to identify which repository, file, and symbol are
  relevant, and MUST read the actual source before asserting how it behaves.

## Consequences

- **Good**: Every repository is searchable, including the unknown ones that
  motivated this. Coverage is the whole point and it is achieved on day one.
- **Good**: Cost is measured rather than assumed — 387s to index the entire
  corpus with zero failures, ~17s per cycle for the monolith incrementally,
  7.3 GB of disposable cache against 68 GiB free.
- **Good**: Install is version-pinned, lockfile-tracked, Renovate-updatable, and
  attestation-verified. Fully inside the existing supply-chain posture.
- **Good**: Indexing, semantic analysis, and queries run locally. Embeddings ship
  as a vendored blob (`vendored/nomic/code_vectors.bin`) with no runtime model
  download. `pass_envscan.c` filters secret-looking bindings, values, and files,
  recording only URL-valued env bindings. Source code does not leave the machine.
- **Good**: Reverting costs one config line and an `rm -rf`.
- **Bad**: A third-party binary parses all source, including proprietary payroll
  code, using roughly 43,750 lines of hand-written tree-sitter `scanner.c` plus a
  locally patched runtime. The realistic threat is a memory-safety fault on
  hostile or unusual input, not exfiltration — the git history carries
  heap-buffer-overflow fixes, and fuzzing plus sanitizers mitigate without
  eliminating. This is why the reindex loop must survive a single repository
  crashing.
- **Bad**: Governance is thin. Solo maintainer on a personal email address,
  repository created 2026-02-24, drive-by contributors, individual commits
  unsigned. Only the newest release is supported and security fixes are not
  backported, so sitting on a pin is not an option — prompt Renovate merges are a
  requirement of adoption, not a nicety.
- **Bad**: The Source Truth tension is real and unresolved by tooling. Nothing
  mechanically prevents an agent from answering from the graph instead of reading
  the code, which is precisely the stale-summary failure principle 4 rejects. The
  mitigation is documented discipline, and documented discipline is weaker than a
  structural guarantee.
- **Bad**: The resident cache is an expansion of the source it indexes, not a
  compression of it — 7.3 GB of cache, roughly 6.7× the corpus's tracked source.
  The monolith alone is the best case at ~3.5×, so smaller repositories expand
  worse than the headline ratio. LZ4 applies to the in-memory pipeline and
  Zstandard to the optional shareable artifact; neither shrinks what sits in
  `~/.cache`.
- **Neutral**: Cross-repository edges are sparse. A wildcard pass scanned 122
  projects in 42s and produced 2 `CROSS_HTTP_CALLS` edges — unsurprising for a
  corpus of largely unrelated checkouts, given the detector recognises only
  HTTP/gRPC/GraphQL/tRPC/channel contracts rather than arbitrary calls. The
  capability works; there is little here for it to find.
- **Bad**: The `cli --target-projects` flag does not parse the JSON array its own
  `--help` documents. It takes the raw string as a single target name, returns a
  plausible-looking `projects_scanned: 1` / `total_cross_edges: 0` / `success`, and
  creates a cache database named after the raw string — a name
  `cbm_validate_project_name` would reject. Use the raw-JSON args form (or the MCP
  tool, where `target_projects` is a real array) instead; see
  [docs/codebase-memory-mcp.md](../codebase-memory-mcp.md).
- **Bad**: `list_projects` is slow at this corpus size — one invocation enumerated
  the corpus successfully, a second exceeded four minutes and had to be killed.
  Agent-facing latency at this scale needs watching.
- **Bad**: Stale-root pruning deletes a *watched* project's cached DB after three
  consecutive missed polls plus a ten-minute grace period
  (`watcher.c:113-119`). Keeping `auto_watch` on means actively-used repositories
  are the watched ones, so a root that disappears — worktree removed, checkout
  relocated — silently loses its index. Recovery is a reindex, which for the
  monolith is 191 seconds.
- **Neutral**: Per-repository projects mean there is no single unified graph.
  Cross-repository structure comes from `CROSS_*` edges produced by the
  `cross-repo-intelligence` pass, which detects HTTP, gRPC, GraphQL, tRPC, and
  async channel links rather than arbitrary call edges. Cross-repository *search*
  works regardless, by querying across projects.
- **Neutral**: mise verifies the repository-level attestation, not the
  `--signer-workflow` constraint upstream recommends. A compromised sibling
  workflow in the same repository could mint a valid attestation. That is the
  existing gap tracked as the "Provenance You Can Prove" milestone in
  `docs/supply-chain-security.md`, not a new exposure.

## Pros and Cons of the Options

### [code-review-graph](https://github.com/tirth8205/code-review-graph)

Registry, watcher daemon, cross-repo search, stdio and HTTP, and unusually candid
published benchmarks.

- **Good**: The most explicit multi-repository agent surface of any candidate
- **Good**: Transparent benchmarks, including a realistic grep baseline rather
  than only the unrealistic read-everything comparison
- **Bad**: Reported retrieval MRR of 0.35 and flow-detection recall of 33%;
  impact-analysis ground truth is partly derived from its own graph, making that
  figure circular by the authors' own admission
- **Bad**: One child process and database per repository. At this corpus size the
  process, memory, and lifecycle overhead is the dominant design question
- **Bad**: Cross-repo search appears to fan out over per-repo indexes rather than
  maintaining unified cross-repo identity

### [codesearch](https://github.com/flupkede/codesearch)

The architecture most worth borrowing: stdio for one repo, HTTP for many, groups,
lazy watchers, idle eviction, federated peers with allowlists.

- **Good**: Best operational design of any candidate, and the only one that
  addresses index lifecycle at fleet scale directly
- **Good**: SHA-256 incremental processing, Tantivy BM25, RRF, SCIP integration
- **Bad**: Roughly 59 stars. Adopting it is closer to becoming a contributor than
  to consuming a tool
- **Bad**: No published relevance benchmark, and its indexing time estimates are
  not attached to a specified corpus
- **Bad**: Its central advantage — the control plane — is the exact capability
  this single-user, single-machine decision does not need

### [Zoekt](https://github.com/sourcegraph/zoekt) + [SCIP](https://github.com/scip-code/scip) + [Semble](https://github.com/MinishLab/semble) behind an MCP gateway

The survey's production recommendation: mature exact/regex search, precise
symbols, and a strong hybrid retrieval layer, assembled behind a thin gateway.

- **Good**: The only option with a credible track record at genuinely large scale
- **Good**: Component maturity is far ahead of every integrated candidate
- **Good**: Zoekt publishes capacity-planning figures (index ~3–3.5× corpus,
  memory ~1.2× corpus)
- **Bad**: Requires building the vector layer, graph storage, result fusion, and
  the entire MCP surface. That is a project, not an adoption
- **Bad**: Every capability justifying the assembly cost — ACL-filtered
  retrieval, tenancy, branch overlays, shared indexes — is a requirement this
  decision does not have
- **Bad**: Directly contradicts the vision. The human's role is intent and taste,
  not maintenance; hand-assembling a search control plane is the yak shave the
  vision exists to eliminate

### Status quo (`rg`/`find` plus handoff documents)

- **Good**: Zero adoption cost, zero supply-chain exposure, always current
- **Good**: Reads primary sources by construction — perfect Source Truth
  compliance
- **Bad**: The cost falls on the human, who must know which paths matter before
  the agent can look. For unknown repositories that knowledge does not exist
- **Bad**: Handoff documents are exactly the pre-digested, already-stale
  summaries principle 4 rejects. The status quo violates Source Truth in practice
  while satisfying it in theory

### [GitNexus](https://github.com/abhigyanpatwari/GitNexus)

Technically would rank near the top: Tree-sitter, language-aware resolution,
BM25, vectors, RRF, graph retrieval, global registry, repository groups, contract
synchronization, one MCP server across every indexed repository.

- **Good**: The most complete integrated feature set found, including a genuine
  global registry
- **Bad**: [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/).
  These repositories include employer work,
  so commercial use applies and would require separate licensing. Decisive on its
  own
- **Bad**: Incremental indexing is still roadmap work

## More Information

Upstream reports 83% answer quality against a 92% file-exploration baseline while
using roughly 10× fewer tokens and 2.1× fewer tool calls, across 31 repositories
([arXiv:2603.27277](https://arxiv.org/abs/2603.27277)). The evaluation is
project-associated rather than independently reproduced, and the token reduction
is the figure most relevant here.

A source-level review of the release found: zero outbound network calls in
first-party C beyond a loopback-bound HTTP server for the graph UI and a
Unix-domain IPC socket; read-only `git` subprocessing; shell arguments validated
by `cbm_validate_shell_arg` before interpolation; zero external Go dependencies;
SHA-pinned third-party GitHub Actions; SLSA build provenance, SBOM, and
`cosign sign-blob` on releases; and a vendored-checksum tamper gate alongside
ASAN/UBSAN, CodeQL, and fuzz harnesses in CI. The 38M-line repository line count
is 98.4% machine-generated tree-sitter grammars, structurally uniform and free of
dangerous constructs. `SECURITY.md` additionally documents one best-effort update
check to `api.github.com` after MCP `initialize`, carrying no project data; the
`cli` mode used by the reindex job never reaches it.

### Follow-Up Work

**OS-level sandboxing.** Everything this ADR relies on regarding runtime
behaviour — no network egress during indexing, writes confined to the cache DB —
is a *claim* about a binary that parses untrusted source with memory-unsafe C.
The claims are well-supported: `SECURITY.md` documents them, CI enforces a
dangerous-call allowlist and monitors egress under strace, and a source review
found no outbound calls in first-party C. But support is not enforcement, and
`docs/supply-chain-security.md` takes the position that constraints belong in the
tooling rather than in prose.

A sandbox profile would make them structural: deny network, permit reads under
`~/src`, permit writes only under `~/.cache/codebase-memory-mcp`. The periodic
reindex job is the natural enforcement point, being the unattended path. Two
details make this less trivial than it sounds — the graph UI binds a loopback
HTTP socket and the coordination daemon uses Unix-domain sockets, so a blanket
network deny would break both, and macOS `sandbox-exec` is deprecated though
still functional with no Linux counterpart wired up here yet. Worth scoping as
its own change rather than folding into adoption.

### Revisit When

- **Query results prove misleading or stale enough to cost more than they save.**
  This is the primary reassessment trigger and the reason scope was not staged.
- Reindex cycle cost becomes noticeable in practice rather than in projection.
- A repository's index crashes repeatedly — a memory-safety signal worth
  reporting upstream and excluding locally.
- Cross-repository edges become numerous enough to be worth querying deliberately,
  rather than the handful a sparse corpus yields today.
- The maintainer or governance posture changes materially: archived, transferred,
  or a bus-factor event.
- Indexes need to be shared across machines or people, or retrieval needs to
  become permission-aware. At that point the centralized architecture rejected
  above becomes the right shape and this ADR should be superseded rather than
  amended.
