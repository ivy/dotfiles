---
status: "accepted"
date: 2026-02-28
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Replace Aqua Backend with GitHub Releases for Mise CLI Tools

## Context and Problem Statement

Mise manages CLI tool installations using multiple backends. The aqua backend was
chosen early on for its curated registry of tool metadata — download URLs, archive
layouts, platform mappings. In practice, aqua has become a source of friction:
attestation checks block installs when the registry falls behind upstream releases,
the registry's complexity makes contribution impractical for a dotfiles maintainer,
and the indirection adds a failure mode between mise and the tools it installs.

The `github:` backend resolves releases directly from GitHub without an
intermediary registry. How should CLI tool backends be chosen going forward?

## Decision Drivers

* **Reliability**: `chezmoi apply` MUST NOT fail because a registry intermediary
  is out of sync with upstream releases
* **Timeliness**: New tool versions SHOULD be installable immediately after the
  upstream project publishes a GitHub release
* **Simplicity**: The number of moving parts between "tool publishes release" and
  "tool is installed" SHOULD be minimized
* **Supply chain integrity**: Installation SHOULD verify release artifacts using
  mechanisms the upstream project provides (checksums, attestations, SLSA provenance)
* **Maintainability**: The dotfiles maintainer SHOULD be able to understand and
  debug installation failures without learning a registry's internal tooling

## Considered Options

1. **Keep aqua backend**: Continue using the aqua registry for all CLI tools
2. **GitHub releases backend**: Switch to `github:` for tools with standard
   release artifacts
3. **Hybrid approach**: Use aqua where it adds value, `github:` elsewhere

## Decision Outcome

Chosen option: **GitHub releases backend**, because it removes the intermediary
that has been the source of repeated installation failures while preserving the
supply chain verification that matters.

### Implementation

Migrate all `aqua:` entries in `home/dot_config/mise/config.toml` to `github:`
with pinned versions. Renovate manages version updates. Tools with non-standard
release artifacts may need the `github:` backend's `match` or `bin` overrides.

### Consequences

* **Good**: New upstream releases are installable immediately — no waiting for
  registry updates
* **Good**: Fewer moving parts — mise talks directly to GitHub Releases API
* **Good**: `github:` backend performs its own checksum, attestation, and SLSA
  provenance verification when available (as demonstrated by `cli/cli@2.87.3`)
* **Good**: Installation failures are debuggable with `gh release view` — no
  registry internals to understand
* **Good**: One fewer implicit trust relationship (the registry maintainer)
* **Bad**: Pinned versions required — `latest` resolution depends on GitHub API,
  adding an implicit floating dependency. Renovate handles this, but it's more
  PR churn than `latest` with aqua
* **Bad**: No curated platform mappings — if an upstream project uses unusual
  asset naming conventions, `github:` may not find the right artifact without
  manual `match` configuration
* **Neutral**: Same upstream trust model either way — see analysis below

## Pros and Cons of the Options

### Keep aqua backend

Continue using `aqua:owner/repo` for all CLI tool installations, relying on the
aqua-registry for metadata, platform mappings, and verification configuration.

* **Good**: Curated metadata handles unusual release artifact layouts automatically
* **Good**: Registry configures checksum and attestation verification per-tool
* **Good**: `latest` version resolution works without Renovate
* **Bad**: Registry lags behind upstream releases — new versions are unavailable
  until a registry PR merges
* **Bad**: Attestation configuration mismatches block installs entirely (observed
  with `cli/cli@2.87.3` where the registry expected attestations the release
  didn't provide)
* **Bad**: Contributing to the registry requires learning `cmdx`, container-based
  testing, and registry-specific YAML conventions
* **Bad**: Adds an intermediary trust relationship — the registry maintainer's
  judgment on package inclusion and configuration

### GitHub releases backend

Use `github:owner/repo` for CLI tools, resolving releases directly from the
GitHub Releases API. Mise handles archive detection, extraction, and binary
discovery using GitHub's asset naming conventions.

* **Good**: Zero intermediary — releases are available the moment upstream
  publishes them
* **Good**: Mise's `github:` backend verifies checksums, GitHub Artifact
  Attestations, and SLSA provenance natively
* **Good**: Failure modes are simple: either the release exists with matching
  assets or it doesn't
* **Good**: Debuggable with standard GitHub tooling (`gh release view`)
* **Bad**: Requires explicit version pins (no curated `latest` resolution)
* **Bad**: Tools with non-standard asset naming need manual configuration
* **Bad**: No curated per-tool verification configuration — relies on mise's
  automatic detection

### Hybrid approach

Use aqua for tools where its registry adds genuine value (complex extraction,
multiple binaries, unusual platforms), `github:` for everything else.

* **Good**: Best-of-both — curated metadata where needed, direct access elsewhere
* **Bad**: Two mental models for tool installation — unclear decision boundary
* **Bad**: Same aqua failure modes for tools that remain on aqua
* **Bad**: Inconsistent configuration style in `config.toml`

## More Information

### Aqua Registry Trust Model

Investigation of the [aqua-registry](https://github.com/aquaproj/aqua-registry)
governance revealed a trust model worth understanding:

**New package submissions** receive human review from the project maintainer,
including technical feedback on registry YAML structure. Commit signing is
enforced, and CI tests installation across platforms in containers.

**Version updates** (~96% of registry PRs) are fully automated: a bot detects
upstream releases, creates a PR, CI verifies the new version installs
successfully, and the PR auto-merges with no human review. The verification is
"does it extract and run" — there is no binary analysis or code audit.

**The Standard Registry is implicitly trusted** by aqua's Policy-as-Code system.
Every package in the registry is allowed by default on every aqua installation.

This means the aqua registry's security value is primarily *organizational* — it
curates which tools are available and configures verification metadata — rather
than *analytical*. It does not perform deeper verification than what the `github:`
backend achieves by checking upstream-provided checksums and attestations directly.

The project is maintained by a single dedicated developer who is responsive and
thoughtful. The friction this ADR addresses is structural (registry lag, implicit
trust, contribution complexity), not a reflection of maintainer quality.

### Migration Scope

13 tools currently use the aqua backend. All 13 were tested with the `github:`
backend on Linux x86_64 and installed successfully — including edge cases the
aqua registry specifically curates for:

* **Bare executables** (jq ships raw binaries, no archives) — handled automatically
* **Capitalized OS names** (glow uses `Linux`/`Darwin`) — matched correctly
* **musl-only builds** (ripgrep dropped gnu for x86_64) — selected automatically
* **Mixed asset types** (yq ships both bare executables and archives) — archive
  preferred automatically
* **Multi-binary releases** (atuin ships client and server) — client selected
  correctly

One quirk: jq uses non-standard release tags (`jq-1.7.1` instead of `1.7.1`),
requiring the `jq-` prefix in the version pin. This is a one-time configuration
detail, not an ongoing maintenance burden.

### Revisit When

* A tool's release artifacts don't follow GitHub conventions and `github:` can't
  resolve them — consider `ubi:` backend or manual `match` configuration
* Mise adds a backend that combines direct GitHub access with curated verification
  metadata
* The aqua registry addresses the lag and attestation mismatch issues
