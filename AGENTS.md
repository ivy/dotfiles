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

## Tool Management

### Mise (Tool Version Manager)
The repository uses [mise](https://github.com/jdx/mise) for tool version management:
- Configuration: `home/dot_config/mise/config.toml`
- Install tools: `mise install --yes`
- Tools are defined globally and installed via `run_onchange_install-mise-tools.sh.tmpl`

### Package Management (macOS)
- Uses Homebrew for package installation via `run_onchange_install-packages-darwin.sh.tmpl`
- Supports brew packages, casks, and Mac App Store apps through templates
- Package definitions are templated and rendered by Chezmoi
- **Preference**: Install tools through package managers when they are stable and unlikely to diverge in versions across projects (e.g., neovim, lazygit, ripgrep, fd, fzf)

#### Adding New Packages
To add new packages, edit `home/.chezmoidata/packages.yaml`:
- **Brew packages**: Add to `packages.darwin.brews` array
- **Casks**: Add to `packages.darwin.casks` array  
- **Mac App Store**: Add app ID to `packages.darwin.mas` array
Run `chezmoi apply` to install new packages.

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

### Making Changes
1. Edit files in the `home/` directory structure
2. Template files (`.tmpl`) will be processed by Chezmoi
3. Test changes: `chezmoi diff` to see what would change
4. Apply changes: `chezmoi apply`

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