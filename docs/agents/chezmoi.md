# Chezmoi Operations

Operational reference for working with Chezmoi in this dotfiles repo. For the big picture, start with [AGENTS.md](../../AGENTS.md).

## How Chezmoi Works

Chezmoi manages dotfiles by maintaining a **source directory** (this repo's `home/`) and applying it to the home directory. The repo root is the source directory (configured via `sourceDir = "{{ .chezmoi.workingTree }}"`).

### File Naming Conventions

| Source prefix | Destination effect |
|---------------|-------------------|
| `dot_` | Becomes `.` (e.g., `dot_zshrc` -> `.zshrc`) |
| `private_` | File gets `0600` permissions |
| `executable_` | File gets `0755` permissions |
| `.tmpl` suffix | Processed through Go template engine |
| `run_onchange_` | Script runs when its content hash changes |

### Template System

Templates use Go's `text/template` syntax. Key variables:

- `.chezmoi.os` — `"darwin"` or `"linux"`
- `.chezmoi.workingTree` — Repository path
- `.packages.darwin.brews`, `.packages.darwin.casks`, `.packages.darwin.mas` — Package definitions

Common patterns:

```go
{{ if eq .chezmoi.os "darwin" }}
  # macOS-only config
{{ end }}

{{ if lookPath "eza" }}
  alias ls="eza"
{{ end }}
```

### Platform Exclusions

`.chezmoiignore` uses `ne` (not-equal) logic to exclude platform-specific files:

```
{{ if ne .chezmoi.os "darwin" }}
private_Library/**
{{ end }}
```

## Installation

```bash
git clone https://github.com/ivy/dotfiles.git && cd dotfiles && ./install.sh
```

### Environment Variables

| Variable | Effect |
|----------|--------|
| `REINSTALL_TOOLS=true` | Force reinstallation of tools |
| `BIN_DIR=/custom/path` | Custom binary directory (default: `~/.local/bin`) |
| `DEBUG=1` | Enable debug output |
| `VERIFY_SIGNATURES=false` | Disable cosign signature verification |

### Installer Options

```bash
./install.sh -- --force      # Force overwrite existing files
./install.sh -- --one-shot   # One-shot mode (no source state)
```

## Scripts

- Scripts prefixed `run_onchange_` execute when their content changes
- Scripts should be idempotent
- Use `set -o errexit -o nounset` for error handling
- Support `DEBUG` env var for verbose output
- Check tool availability before attempting operations

## Adding New Dotfiles

1. Place the file in `home/` with appropriate prefixes (`dot_`, `private_`, etc.)
2. For `~/.config/` files, use `home/dot_config/` structure
3. For private files (secrets, keys), use `private_` prefix
4. Add `.tmpl` suffix if the file needs platform-conditional content

## Security

### Signature Verification

The installer uses cosign for GitHub release signature verification by default. Falls back to checksum verification if cosign is unavailable. Disable with `VERIFY_SIGNATURES=false` (not recommended).

### Private Files

Files with `private_` prefix are stored with restricted permissions. Chezmoi encrypts these in the source state.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Tools not in PATH | Ensure `~/.local/bin` is in PATH |
| Template rendering errors | Check syntax and variable availability with `chezmoi execute-template` |
| Permission issues | Run installer with appropriate permissions |
| Signature verification failures | Check connectivity or set `VERIFY_SIGNATURES=false` |

### Debug Mode

```bash
DEBUG=1 ./install.sh
DEBUG=1 chezmoi apply -v
```
