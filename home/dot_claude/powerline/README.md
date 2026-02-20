# Claude Powerline Themes

Catppuccin themes for [claude-powerline](https://github.com/Owloops/claude-powerline), auto-switching between light and dark based on macOS appearance.

## Design Principles

**Show only what demands action.** The powerline is not a dashboard — it's a glanceable status indicator. If a segment doesn't change what you do next, it doesn't belong here.

**Two segments, one line:**

| Segment | Why |
|---------|-----|
| **model** | Which Claude you're talking to (Opus vs Sonnet changes cost and capability) |
| **context** | The only metric that demands immediate action — when context is full, start a new conversation |

**Everything else lives in tmux.** Directory, git branch, system info — these are general dev context, not Claude-specific. tmux owns that layer.

## Theme Selection

The shim at `~/.local/libexec/claude-powerline-theme` detects macOS appearance:

- Light mode / default: `catppuccin-latte`
- Dark mode: `catppuccin-mocha`

Both themes use the full [Catppuccin](https://catppuccin.com/) palette. All 12 segment colors are defined even though only 2 segments are displayed — the schema requires them and they're ready if needs change.

## Files

| File | Purpose |
|------|---------|
| `catppuccin-latte.json` | Light theme config |
| `catppuccin-mocha.json` | Dark theme config |
