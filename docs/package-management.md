# Package Management Guide

This guide explains how to add, update, and manage packages in this dotfiles repository. The system prioritizes reproducibility through version pinning and automated updates via Renovate.

## Quick Reference: Where to Add Packages

| Package Type | Location | Example | Renovate Updates |
|-------------|----------|---------|------------------|
| **Development Runtimes** | `home/dot_config/mise/config.toml` | `python = "3.14.2"` | ✅ Yes |
| **CLI Tools (aqua)** | `home/dot_config/mise/config.toml` | `"aqua:dandavison/delta" = "0.18.2"` | ✅ Yes |
| **CLI Tools (GitHub)** | `home/dot_config/mise/config.toml` | `"github:sst/opencode" = "1.1.14"` | ✅ Yes |
| **Python Tools** | `home/dot_config/mise/config.toml` | `"pipx:gitingest" = "0.3.1"` | ✅ Yes |
| **Node.js Tools** | `home/dot_config/mise/config.toml` | `"npm:@anthropic-ai/claude-code" = "2.1.19"` | ✅ Yes |
| **System Utilities** | `home/.chezmoidata/packages.yaml` | `brews: [ripgrep]` | ❌ Manual |
| **GUI Applications** | `home/.chezmoidata/packages.yaml` | `casks: [ghostty]` | ❌ Manual |
| **Neovim Plugins** | `home/dot_config/nvim/lua/plugins/*.lua` | LazyVim specs | ⚙️ Via LazyVim |
| **Shell Plugins** | `home/.chezmoiexternal.toml.tmpl` | Pinned to SHA | ✅ Yes |

## Core Philosophy

1. **Immutable Pins Over Latest**: Every package specifies an exact version/digest/SHA
2. **Renovate-Driven Updates**: Automated PRs keep versions current without drift
3. **Mise-First for Development**: All versioned dev tools use mise backends—no separate package managers
4. **System Utilities via Homebrew**: Only non-versioned system tools use Homebrew

## Mise Backends (Preferred Order)

Mise supports multiple backends for installing tools. Use them in this priority:

| Backend | Syntax | Use Case |
|---------|--------|----------|
| **aqua** | `"aqua:owner/repo" = "version"` | Preferred for most CLI tools—security features, no plugins |
| **github** | `"github:owner/repo" = "version"` | Tools not in aqua registry but available on GitHub |
| **gitlab** | `"gitlab:owner/repo" = "version"` | Tools hosted on GitLab |
| **pipx** | `"pipx:package" = "version"` | Python CLI tools (requires Python runtime) |
| **npm** | `"npm:package" = "version"` | Node.js CLI tools (requires Node runtime) |
| **go** | `"go:module" = "version"` | Go tools (prefer aqua/github if binary available) |
| **cargo** | `"cargo:crate" = "version"` | Rust tools (prefer aqua/github if binary available) |

Native mise tools (e.g., `python`, `node`, `shfmt`) don't need a backend prefix.

## Adding Packages: Decision Tree

```
Is it a development runtime or CLI tool?
├─ YES → Use mise with the appropriate backend:
│  ├─ In aqua registry? → aqua:owner/repo
│  ├─ GitHub release? → github:owner/repo
│  ├─ Python package? → pipx:package
│  ├─ Node package? → npm:package
│  └─ Native mise tool? → toolname (no prefix)
└─ NO → Is it a GUI app or system utility?
   ├─ GUI App → packages.yaml (casks)
   └─ System Tool → packages.yaml (brews)
```

## Step-by-Step: Adding a New Package

### 1. Development Runtimes

Add native mise tools to `home/dot_config/mise/config.toml`:

```toml
[tools]
python = "3.14.2"
node = "24.13.0"
pkl = "0.30.2"
```

**Finding versions:**
```bash
mise ls-remote python
mise ls-remote node
```

### 2. CLI Tools via Mise Backends

All CLI tools go in `home/dot_config/mise/config.toml` using the appropriate backend prefix:

```toml
[tools]
# Aqua registry (preferred for most tools)
"aqua:dandavison/delta" = "0.18.2"
"aqua:jqlang/jq" = "1.7.1"
"aqua:koalaman/shellcheck" = "v0.11.0"

# GitHub releases (for tools not in aqua)
"github:sst/opencode" = "1.1.14"

# Python tools via pipx
"pipx:gitingest" = "0.3.1"

# Node.js tools via npm
"npm:@anthropic-ai/claude-code" = "2.1.19"
"npm:@openai/codex" = "0.91.0"
```

**Finding versions:**
```bash
# GitHub releases
gh api repos/owner/repo/releases/latest --jq .tag_name

# npm packages
npm view @anthropic-ai/claude-code version

# PyPI packages
pip index versions gitingest 2>/dev/null | head -1
```

### 3. System Utilities & GUI Applications

Add to `home/.chezmoidata/packages.yaml`:

```yaml
packages:
  darwin:
    brews:
      - ripgrep     # Command-line tools
      - bat
    casks:
      - ghostty     # GUI applications
      - cursor
    mas:
      - 1532419400  # Mac App Store apps (MeetingBar)
```

**Note**: These don't have Renovate automation yet. Consider adding version comments for manual tracking.

### 4. External Dependencies (Shell Plugins)

Add to `home/.chezmoiexternal.toml.tmpl` with SHA pinning:

```toml
[".config/zsh/plugins/new-plugin"]
  type = "archive"
  url = "https://github.com/owner/repo/archive/{{ SHA }}.tar.gz"
  stripComponents = 1
```

Then add a Renovate rule in `renovate.json5`:
```json5
{
  customManagers: [{
    fileMatch: ["home/\\.chezmoiexternal\\.toml\\.tmpl"],
    matchStrings: [
      "owner/repo/archive/(?<currentDigest>[a-f0-9]{7,40})\\.tar\\.gz"
    ],
    datasourceTemplate: "git-refs",
    depNameTemplate: "owner/repo",
    currentValueTemplate: "master"
  }]
}
```

## Updating Packages

### Manual Updates (Before Renovate PR)

1. **Find the new version:**
   ```bash
   # GitHub releases
   gh api repos/owner/repo/releases/latest --jq .tag_name
   
   # Mise tools
   mise ls-remote python
   
   # NPM packages
   npm view package-name version
   ```

2. **Update the manifest file** with exact version
3. **Test locally:**
   ```bash
   chezmoi apply
   ```

### Automated Updates (Via Renovate)

Renovate runs weekly (Monday mornings) and will:
- Open PRs with version bumps
- Group related updates
- Auto-merge low-risk updates (digests, patch versions for actions/containers)
- Label PRs with `deps` and `automated`

## Installation Scripts & Triggers

Scripts in `home/` execute when their trigger conditions change:

| Script | Triggers On | Installs |
|--------|------------|----------|
| `run_onchange_00-install-mise-tools.sh.tmpl` | mise config changes | All mise-managed tools (runtimes + backend tools) |
| `run_onchange_install-packages-darwin.sh.tmpl` | packages.yaml changes | Homebrew packages |
| `run_onchange_install-nvim-plugins.sh.tmpl` | Neovim plugin specs | LazyVim plugins |

The `00-` prefix ensures mise tools install first. All Python/Node tools are now installed via mise backends (`pipx:`, `npm:`) in a single script.

## Best Practices

### DO:
- ✅ Pin exact versions (never use `latest` or `*`)
- ✅ Use mise backends for all dev tools (`aqua:`, `pipx:`, `npm:`, `github:`)
- ✅ Prefer `aqua:` backend when available (best security/features)
- ✅ Test changes with `chezmoi diff` before applying
- ✅ Check `mise registry` before adding new tools

### DON'T:
- ❌ Use `brew install`, `pipx install`, or `npm install -g` directly
- ❌ Add version ranges or wildcards
- ❌ Install development tools via Homebrew (use mise instead)
- ❌ Create separate manifest files for language-specific tools
- ❌ Mix package managers for the same tool

## Validation

After changes:
```bash
# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Verify mise tools install correctly
mise install

# Validate Renovate config
renovate-config-validator renovate.json5
```

## Examples

### Adding a Python CLI Tool

Add to `home/dot_config/mise/config.toml`:
```toml
[tools]
"pipx:ruff" = "0.9.6"
```

Renovate will automatically update this version via the mise manager.

### Adding a Node.js CLI Tool

Add to `home/dot_config/mise/config.toml`:
```toml
[tools]
"npm:prettier" = "3.5.3"
```

### Adding a CLI Tool from GitHub

1. Check if it's in the aqua registry first:
   ```bash
   mise registry | grep toolname
   ```

2. If available via aqua (preferred):
   ```toml
   [tools]
   "aqua:goreleaser/goreleaser" = "v2.5.1"
   ```

3. If not in aqua, use the github backend:
   ```toml
   [tools]
   "github:owner/repo" = "v1.2.3"
   ```

### Adding a System Utility (Homebrew)

Only use Homebrew for system utilities that don't need version management:

```yaml
# home/.chezmoidata/packages.yaml
brews:
  - tmux
```

Always check `mise registry` first—prefer mise when available.

## Troubleshooting

**Package not installing?**
- Check the `run_onchange_00-install-mise-tools.sh.tmpl` script executed: `chezmoi status`
- Verify the backend prefix is correct (`aqua:`, `pipx:`, `npm:`, `github:`)
- Run `mise install` manually to see detailed errors
- Check if the tool exists: `mise registry | grep toolname`

**Version not updating?**
- Ensure exact version is specified (not a range)
- Verify Renovate's mise manager recognizes the file
- Check Renovate PR for any errors

**Backend-specific issues?**
- `pipx:` requires Python runtime in mise config
- `npm:` requires Node runtime in mise config
- `aqua:` tools may need version prefix (`v1.2.3` vs `1.2.3`)

**Conflicts between managers?**
- Mise takes precedence for all development tools
- Remove from Homebrew if adding to mise
- Check PATH ordering in `.zshrc.tmpl`

## Further Reading

- [ADR: Use Mise for Global Tool Management](ADRs/0001-use-mise-for-global-tool-management.md) - Rationale for mise-first approach
- [Mise Backends Documentation](https://mise.jdx.dev/dev-tools/backends/) - All available backends
- [Mise Registry](https://mise.jdx.dev/registry.html) - Searchable tool registry