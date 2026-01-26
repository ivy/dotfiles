# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository that uses Chezmoi to manage configuration files across macOS, Linux, and containerized environments. The repository follows a pragmatic philosophy prioritizing stability, portability, and reliability over customization.

## Installation and Setup

### Initial Installation
```bash
# Clone and install dotfiles
git clone https://github.com/ivy/dotfiles.git && cd dotfiles && ./install.sh

# Force reinstall tools if needed
REINSTALL_TOOLS=true ./install.sh

# Pass arguments to chezmoi init
./install.sh -- --force          # Force overwrite existing files
./install.sh -- --one-shot       # Use chezmoi one-shot mode
```

### Environment Variables
- `REINSTALL_TOOLS=true` - Force reinstallation of tools
- `BIN_DIR=/custom/path` - Custom binary installation directory (default: `~/.local/bin`)
- `DEBUG=1` - Enable debug output
- `VERIFY_SIGNATURES=false` - Disable signature verification

## Package Installation

**For installing new packages, tools, or CLIs**: Use the `/install` skill. It handles package type detection, version discovery, manifest updates, and commits.

```
/install <package-name>
```

The skill prefers mise over Homebrew, pins exact versions, and follows the repository's conventions automatically.

## Package Manager Subagent: Complex Changes

Use the Package Manager subagent (not `/install`) only for:
- **Version conflicts** or upgrade decisions
- **Container images** (Docker Compose, devcontainer)
- **Security-sensitive changes** requiring review
- **Bulk updates** or Renovate configuration
- **GitHub Actions** version/digest updates

Files requiring subagent review:
- Docker Compose files (image tags/digests)
- Devcontainer images and features
- Chezmoi externals (home/.chezmoiexternal.toml.tmpl)
- GitHub Actions versions/digests in workflows

Why: The subagent enforces immutable pins (versions/digests/SHAs) and ensures Renovate can update them safely.

For background and exact conventions, see doc/renovate.md.

## Architecture

### Chezmoi Structure
- **Source Directory**: Repository root (configured via `sourceDir = "{{ .chezmoi.workingTree }}"`)
- **Templates**: Files ending in `.tmpl` are processed by Chezmoi's template engine
- **Scripts**: `run_onchange_*` scripts execute when their content changes
- **Dotfiles**: Files prefixed with `dot_` become dotfiles (e.g., `dot_zshrc` → `.zshrc`)

### Key Directories
- `home/` - Contains all managed dotfiles and configuration
- `home/dot_config/` - XDG config directory contents
- `home/dot_local/bin/` - User binaries
- `home/private_Library/` - Private macOS Library files (Cursor settings, etc.)
- `test/` - BATS test suite for validation
- `bin/` - Repository utility scripts

### Template System
Chezmoi templates use Go's text/template syntax. Key template variables:
- `.chezmoi.os` - Operating system (darwin, linux, etc.)
- `.chezmoi.workingTree` - Repository path
- `.packages.darwin.brews`, `.packages.darwin.casks`, `.packages.darwin.mas` - Package definitions

## Testing

### Running Tests
```bash
# Run all tests
bats test/

# Run specific test file
bats test/run_onchange_install-mise-tools.bats

# Run tests with verbose output
bats -t test/
```

### Test Structure
- Uses BATS (Bash Automated Testing System)
- `test_helper.bash` provides common test utilities
- Tests validate template rendering and script syntax
- Helper functions: `assert_valid_shell()`, `assert_script_structure()`

## Development Workflow

### Critical: Source Directory Only

**NEVER edit files directly in `~` or `~/.config/`.** Chezmoi manages the home directory; all edits must be made in the project's `home/` directory. Changes to destination files will be overwritten on next apply.

| To modify this destination... | Edit this source file |
|-------------------------------|----------------------|
| `~/.zshrc` | `home/dot_zshrc` |
| `~/.config/mise/config.toml` | `home/dot_config/mise/config.toml` |
| `~/.config/ghostty/config` | `home/dot_config/ghostty/config` |

### Chezmoi Workflow

Follow this sequence for every change:

1. **Edit source files** in `home/` (never destination)
2. **Preview changes** with `chezmoi diff`
   - Review output carefully—ensure only intended changes appear
   - If unrelated changes appear, investigate before proceeding
3. **Apply changes**
   - Full apply: `chezmoi apply`
   - Partial apply (when diff shows unrelated changes): `chezmoi apply ~/.zshrc ~/.config/mise/config.toml`
4. **Validate** with `chezmoi status`
   - Clean status means destination matches source
   - Any remaining differences indicate incomplete apply or external modifications

```bash
# Example workflow
vim home/dot_zshrc                     # 1. Edit source
chezmoi diff                           # 2. Preview all changes
chezmoi apply ~/.zshrc                 # 3. Apply specific target
chezmoi status                         # 4. Confirm clean state
```

### Claude Code Workflow

When making configuration changes:
1. **For package installs**: Use `/install <package>` (not manual edits)
2. **Edit only in `home/`**—never touch `~` or `~/.config` directly
3. **Run `chezmoi diff`** and verify only your intended changes appear
4. **Apply selectively** if diff shows unrelated changes: `chezmoi apply [target ...]`
5. **Run `chezmoi status`** to confirm destination matches source
6. **Commit** with Conventional Commit message after each logical change

### Adding New Dotfiles
1. Add file to appropriate location in `home/` with `dot_` prefix
2. For directories, use `dot_config/` structure
3. For private files (containing secrets), use `private_` prefix

### Script Guidelines
- Installation scripts should be idempotent
- Use proper error handling (`set -o errexit -o nounset`)
- Support DEBUG environment variable for verbose output
- Check tool availability before attempting operations

## Security Considerations

### Signature Verification
The installer uses cosign for signature verification by default:
- Verifies GitHub release signatures
- Can be disabled with `VERIFY_SIGNATURES=false` (not recommended)
- Falls back to checksum verification if cosign unavailable

### Private Files
- Files with `private_` prefix are not tracked publicly
- Contains sensitive configuration like API keys or personal data
- Chezmoi encrypts these files in the source state

## Troubleshooting

### Common Issues
- **Tools not in PATH**: Ensure `~/.local/bin` is in your PATH
- **Template rendering errors**: Check template syntax and variable availability
- **Permission issues**: May need to run installer with appropriate permissions
- **Signature verification failures**: Check internet connectivity or disable verification

### Debug Mode
Enable debug output for troubleshooting:
```bash
DEBUG=1 ./install.sh
DEBUG=1 chezmoi apply -v
```
