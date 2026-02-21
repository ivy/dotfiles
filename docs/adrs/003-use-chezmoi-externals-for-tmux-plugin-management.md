---
status: "proposed"
date: 2026-02-20
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Use Chezmoi Externals for Tmux Plugin Management Instead of a Plugin Manager

## Context and Problem Statement

The tmux configuration is being rebuilt from scratch to replace the gpakosz/.tmux
framework. Tmux plugins need a management approach that pins exact versions,
supports automated updates via Renovate, produces reproducible installs, and works
cleanly in Docker-based dev containers. How should tmux plugin dependencies be
managed?

## Decision Drivers

* **Exact version pinning**: Every plugin MUST be locked to a specific commit SHA
  in a file committed to the dotfiles repo, enabling `git bisect` when things break
* **Renovate automation**: Plugin updates MUST be detectable by Renovate without
  custom tooling — Renovate opens PRs, human reviews and merges
* **Reproducibility**: A fresh machine (or container) with the same dotfiles commit
  MUST produce an identical tmux environment — no runtime resolution, no floating
  refs
* **Docker image efficiency**: Dotfiles are packaged in Docker images for throwaway
  dev containers — plugin installation SHOULD NOT bloat images with git metadata
* **Transparency**: Every line of config SHOULD be explainable — no opaque plugin
  manager internals mediating the relationship between config and installed code

## Considered Options

1. **TPM (tmux plugin manager)**: The ecosystem standard
2. **tpack**: A modern Go rewrite of TPM with TUI
3. **Git submodules**: Native git dependency pinning
4. **Chezmoi externals**: Archive downloads via `.chezmoiexternal.toml`

## Decision Outcome

Chosen option: **Chezmoi externals**, because they satisfy all decision drivers
using infrastructure the dotfiles repo already has. The pattern is proven — zsh
plugins are already managed this way.

### Consequences

* **Good**: Exact SHA pinning via commit hash in archive URL
* **Good**: Renovate already parses these URLs with existing custom `git-refs`
  managers — zero new tooling
* **Good**: Tarballs contain only source files — no `.git` metadata in Docker images
* **Good**: No plugin manager binary to install, version, or understand — chezmoi is
  already a dependency
* **Good**: `git bisect` works on the `.chezmoiexternal.toml` file to isolate which
  plugin update caused a regression
* **Bad**: No TUI for browsing or discovering new plugins — discovery is manual via
  GitHub
* **Bad**: Adding a new plugin requires manually constructing the TOML stanza and
  finding the current commit SHA
* **Neutral**: `chezmoi apply` handles installation — no `prefix+I` keybinding, but
  also no extra process to understand

## Pros and Cons of the Options

### TPM (tmux plugin manager)

The de facto standard. ~500 lines of bash, 14.2k GitHub stars, 10 years old.
Plugins declared as `set -g @plugin 'user/repo'` in tmux.conf.

* **Good**: Massive ecosystem — nearly every tmux plugin targets TPM conventions
* **Good**: Pure bash, fully auditable, excellent documentation
* **Good**: Battle-tested over a decade
* **Bad**: No lockfile — `git pull` fetches branch tip, versions float
* **Bad**: No commit SHA pinning — `git clone -b` accepts branches and tags only
* **Bad**: No Renovate support — plugin specs are freeform strings in tmux.conf
* **Bad**: Updates (`prefix+U`) ignore any pin and advance to branch tip
* **Bad**: Clones full git repos into plugin directory, bloating Docker images

### tpack

Go rewrite of TPM with Bubble Tea TUI, plugin registry browser, 100% TPM backward
compatibility. Six weeks old, pre-v1.0, single active maintainer.

* **Good**: Best-in-class console DX — vim keybindings, commit preview, registry
  browser
* **Good**: Drop-in TPM replacement, zero config migration
* **Good**: Active development, responsive maintainer
* **Bad**: Same `git clone -b` limitation as TPM — no commit SHA pinning without
  patching
* **Bad**: No lockfile, no Renovate support
* **Bad**: 15.8k lines of Go — substantially harder to audit than 500 lines of bash
* **Bad**: Pre-v1.0 with single maintainer — uncertain long-term viability
* **Bad**: Full git clones in plugin directory

### Git submodules

Native git mechanism for pinning dependencies to exact commit SHAs. Renovate has
built-in submodule support.

* **Good**: Exact SHA pinning in `.gitmodules`, committed to repo
* **Good**: Native Renovate support — no custom managers needed
* **Good**: `git bisect` works automatically
* **Bad**: Submodule directories include `.git` metadata — requires multi-stage
  Docker builds to strip
* **Bad**: Awkward ergonomics — `git submodule update --init --recursive`, detached
  HEAD state
* **Bad**: Adds git plumbing complexity to the dotfiles repo
* **Neutral**: Chezmoi can manage submodules but it's not the idiomatic path

### Chezmoi externals

Archive downloads declared in `.chezmoiexternal.toml` with pinned commit SHAs in
GitHub archive URLs. Already used in this repo for zsh plugins and Ghostty themes.

* **Good**: Exact SHA pinning in archive URL
* **Good**: Renovate integration already working via existing `git-refs` custom
  managers
* **Good**: Tarballs — no git metadata, Docker-friendly
* **Good**: Already proven in this repo for zsh-autosuggestions,
  zsh-syntax-highlighting, oh-my-zsh, and Ghostty themes
* **Good**: `chezmoi apply` is the only install command — no separate plugin manager
* **Bad**: No plugin discovery TUI — finding new plugins is manual
* **Bad**: Manual TOML stanza construction when adding new plugins

## More Information

### Implementation Pattern

Each tmux plugin gets a stanza in `.chezmoiexternal.toml`:

```toml
[".tmux/plugins/tmux-sensible"]
    type = "archive"
    url = "https://github.com/tmux-plugins/tmux-sensible/archive/<sha>.tar.gz"
    exact = true
    stripComponents = 1
```

Renovate detects the SHA in the URL, checks for newer commits on the upstream
default branch, and opens a PR updating the SHA. The PR diff shows exactly which
plugin changed and to which commit.

### Plugin Loading Without a Plugin Manager

Plugins following TPM conventions expose a `*.tmux` entry point. These can be
sourced directly in `tmux.conf` without TPM:

```bash
run-shell ~/.tmux/plugins/tmux-sensible/sensible.tmux
```

This is more explicit than TPM's glob-based sourcing and aligns with the
"understand everything" principle.

### Research Context

Three plugin managers were evaluated as part of a research spike
([docs/plugin-management.md](../../2026-02-20-tmux-overhaul/docs/plugin-management.md)).
All three share the same `git clone -b` architecture that prevents commit SHA
pinning and lacks lockfile support. The existing chezmoi externals pattern emerged
as a better fit after reviewing how zsh plugins are already managed in this repo.

### Revisit When

* Chezmoi externals develop limitations at scale (unlikely with <20 plugins)
* A tmux plugin manager ships native lockfile support with Renovate integration
* The `type = "archive"` approach causes issues with plugins that depend on git
  metadata at runtime
