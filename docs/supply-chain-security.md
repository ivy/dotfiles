# Supply Chain Security

In my spare time, I'm building towards the future of trusted agentic computing. When agents manage your entire developer environment — installing tools, applying configs, building images, deploying containers — every link in the supply chain becomes an attack surface. Trust can't be assumed. It must be proven, cryptographically, at every step.

A few months ago, I decided to set up an agent-first homelab and evaluate the security risks myself. With a single prompt, an agent deployed a 6-year-old Samba container with known RCE vulnerabilities because no supply chain policy existed. The agent optimized for speed — found a popular image, deployed it, done. When confronted, it suggested a *different* unvetted third-party image. Agents will take the path of least resistance unless every link in the chain has verifiable, enforceable constraints.

It seems like every week now there's a major supply chain attack. We're shipping faster than ever and the mistakes are compounding. Trust in maintainers to catch every vulnerable contribution was already limited, now it's compounding.

Dreaming big: every image ships with a verifiable, machine-readable provenance graph — from source commit to running container — where every link is cryptographically attested by the entity that performed it, reproducible by anyone, and queryable as part of a fleet-wide dependency graph.

## Why This Matters for Agent Autonomy

Today, agents operate semi-autonomously: I direct the [`/reflect`](../home/dot_claude/skills/reflect/README.md) phase, review improvement proposals, and approve changes. The roadmap is full autonomy — agents building what they need to perform their tasks more effectively, including feedback loops where session friction becomes filed issues becomes merged fixes, without human shepherding.

That autonomy requires trust infrastructure. An agent that can install tools, build images, and deploy services needs guardrails that are structural, not advisory. You can't tell an agent "be careful about supply chain security" and expect it to work — you need signature verification that rejects unsigned artifacts, scanners that block vulnerable images, and provenance that traces every artifact to its source. The constraints must be in the tooling, not the prompt.

## What We Have Today

### Version Pinning

Every dependency has an exact version. Renovate opens PRs to update them.

| Layer | How | Where |
|---|---|---|
| **Mise tools** | Exact versions + lockfile with per-platform SHA256 checksums | `home/dot_config/mise/config.toml`, `mise.lock` |
| **GitHub Actions** | Commit SHA pins | `.github/workflows/*.yml` |
| **Shell plugins** | Commit SHA pins | `home/.chezmoiexternal.toml.tmpl` |
| **Tmux plugins** | Commit SHA pins | `home/.chezmoidata/tmux-plugins.yaml` |
| **Docker Compose images** | Tag + `@sha256:` digest | `home/dot_config/docker-compose/*.yml` |
| **Devcontainer** | `@sha256:` digest pins | `.devcontainer/devcontainer.json` |
| **Cosign** | Pinned in `cli-versions.toml` | `home/dot_config/dotfiles/cli-versions.toml` |

Mise lockfiles (`lockfile = true`) resolve download URLs and checksums at lock time, preventing API calls to GitHub/aqua during install. Strict mode is the goal but blocked on #181 (self-hosted Renovate with lockfile support).

### Automated Updates

Renovate runs weekly (Monday mornings), opens labeled PRs, groups by risk, and automerges safe changes (action digests, container digests, minor/patch bumps). See [docs/renovate.md](renovate.md).

### Package Manager Hardening

| Manager | Hardening | Where |
|---|---|---|
| **npm** | `NPM_CONFIG_IGNORE_SCRIPTS=1` — disables postinstall scripts globally | `home/dot_zshenv.tmpl` |
| **npm** | `NPM_CONFIG_AUDIT=false`, `NPM_CONFIG_FUND=false` — no noise | `home/dot_zshenv.tmpl` |
| **Mise** | GitHub backend preferred over aqua — verifies checksums, GitHub Artifact Attestations, and SLSA provenance natively (ADR-005) | `home/dot_config/mise/config.toml` |

### Git Commit Signing

All commits signed with SSH ed25519 keys via 1Password agent. Allowed signers file at `~/.config/git/allowed_signers`.

```
[commit]
  gpgsign = true
[gpg]
  format = ssh
```

### Bootstrap Verification

The `install.sh` bootstrap script installs cosign first, then uses it to verify chezmoi and mise binaries before installation. Supports `VERIFY_SIGNATURES=true` (default) to enforce verification.

### Container Build Pipeline

| Capability | Status |
|---|---|
| Multi-arch builds (amd64 + arm64) | Done |
| Build attestation (`actions/attest-build-provenance`) | Done |
| Pinned Actions (commit SHAs) | Done |
| Minimal workflow permissions | Done |
| Cosign installed in image | Done (not yet used in CI) |

## What's Missing

The Containerfile uses `fedora:latest` (unpinned base), `curl | sh` (unverified downloads in the image build — `install.sh` verifies but the Containerfile doesn't), and `dnf install` (unversioned packages). The workflow builds and attests but doesn't sign, scan, or produce an SBOM. Consumers can't verify the image came from this repo without trusting GHCR.

Homebrew has no hardening (`HOMEBREW_NO_INSECURE_REDIRECT`, `HOMEBREW_NO_ANALYTICS`, etc.). pip has no hardening. Hadolint is documented in the hk Docker stack guide but not configured in `hk.pkl`.

## Milestones

Work is tracked in [GitHub milestones](https://github.com/ivy/dotfiles/milestones), ordered by effort vs. impact.

### 1. Verifiable Images

Anyone pulling our image can cryptographically verify it was built by this repo's CI, inspect every package inside it, and know which vulnerabilities have been assessed. Table-stakes trust — without it, the image is just bytes from a registry.

### 2. Assessed Vulnerabilities

Every vulnerability in our image has a disposition — affected, not affected, under investigation — machine-readable and attached to the image itself. Scanners consume this automatically. No more alert fatigue from CVEs in code paths we never execute.

### 3. Provenance You Can Prove

The image provenance is non-forgeable. A compromised workflow in a different repo cannot produce attestations that claim to be ours. The build system itself is part of the verified chain.

### 4. Reproducible Builds

Build the image twice from the same commit and get the same bytes. Reproducibility is the ultimate proof that the build process is trustworthy — anyone can verify the image by rebuilding it and comparing digests.

### 5. Supply Chain Intelligence

The image isn't an isolated artifact — it's a node in a queryable supply chain graph. When the next log4j happens, we answer "am I affected?" in seconds, not hours. Patch without rebuilding. Know the security posture of every transitive dependency.

### 6. Zero-Trust Builds

Trust no one — not the CI provider, not the registry, not the network. The build runs in hardware-attested isolation, signed with post-quantum algorithms. Even a compromised GitHub Actions runner can't tamper with the output. This is the theoretical ceiling — 5-10 years from mainstream adoption.

## Further Reading

- [Sigstore](https://www.sigstore.dev/) — Keyless signing, transparency logs, policy enforcement
- [SLSA](https://slsa.dev/) — Supply-chain Levels for Software Artifacts
- [OpenVEX](https://openvex.dev/) — Vulnerability Exploitability eXchange
- [Chainguard apko](https://github.com/chainguard-dev/apko) — Declarative, reproducible OCI images
- [Project Copacetic](https://project-copacetic.github.io/copacetic/) — Patch container images without rebuilding
- [GUAC](https://guac.sh/) — Graph for Understanding Artifact Composition
- [OCI 1.1 Referrers](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#listing-referrers) — Attach arbitrary attestations to images
- [in-toto](https://in-toto.io/) — Supply chain layout verification
