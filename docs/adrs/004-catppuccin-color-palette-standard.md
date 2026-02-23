---
status: "accepted"
date: 2026-02-22
decision-makers: [Ivy Evans]
consulted: []
informed: []
---

# Use Catppuccin as the Standard Color Palette Across All Tools

## Context and Problem Statement

The dotfiles configure multiple tools with independent theming (Ghostty, tmux,
Neovim, zsh, Claude Code powerline, etc.). Without a single palette standard,
each tool risks using slightly different colors, and agents adding new tool
configurations must guess which colors to use. How should color theming be
standardized across the stack?

## Decision Drivers

* **Visual consistency**: The same semantic colors MUST map to the same hex values
  everywhere — terminal, editor, multiplexer, and shell
* **Light and dark mode**: Both light and dark appearances MUST be supported,
  using variants designed to work together
* **Agent-friendly**: An agent implementing a new tool's theme SHOULD be able to
  look up exact hex values without searching external docs
* **System appearance detection**: Tools SHOULD automatically match the OS
  light/dark setting without manual toggling
* **Aesthetics**: It pleases the eyes

## Considered Options

1. **Catppuccin** (Latte + Mocha)
2. **Tokyo Night**
3. **Other community palettes** (Dracula, Nord, etc.)
4. **Ad-hoc per tool**

## Decision Outcome

Chosen option: **Catppuccin**, using **Latte** for light mode and **Mocha** for
dark mode.

Catppuccin provides a published [style guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md),
a machine-readable [color palette](https://github.com/catppuccin/palette), and
a community that makes it straightforward to create new ports. The four variants
share 26 identical semantic color names, so switching between them is a one-line
change per tool. The Latte/Mocha pairing covers light and dark without the
mid-range variants (Frappe, Macchiato) that would add complexity without clear
benefit.

Tokyo Night is a good palette — but Catppuccin is the aesthetic I enjoy, and its
ecosystem makes the practical work of theming new tools easier.

### Requirements

* All tools with theming capabilities SHOULD use the Catppuccin palette — see
  [docs/catppuccin.md](../catppuccin.md) for hex values and implementation guide
* All tools SHOULD detect the system appearance automatically and select the
  appropriate variant (Latte for light, Mocha for dark)
* When an official Catppuccin port exists for a tool, prefer it over manual hex
  configuration
* When no port exists, use the hex values from the
  [color reference](../catppuccin.md#color-reference) to build a custom theme
* Light mode MUST default to **Latte**, dark mode MUST default to **Mocha**

### Consequences

* **Good**: Any agent can implement a new tool's theme using the
  [palette reference](../catppuccin.md) — no external lookups needed
* **Good**: Visual consistency across the entire stack from terminal to editor
* **Good**: Official ports for most tools in the stack reduce manual maintenance
* **Good**: Renovate can update Catppuccin ports pinned via chezmoi externals
* **Bad**: Tools without official ports require manual hex configuration that
  must be kept in sync with upstream palette updates
* **Bad**: Some tools cannot auto-detect system appearance (see Known Gaps)
* **Neutral**: Frappe and Macchiato variants are intentionally excluded —
  revisit if a use case emerges

## Known Gaps

### No appearance detection on remote systems

The current detection pattern uses macOS `defaults read -g AppleInterfaceStyle`,
which only works locally. SSH sessions, dev containers, and remote machines
have no way to inherit the local system's appearance setting. This is
out-of-scope for this ADR but needs to be solved eventually — likely by
propagating appearance as an environment variable through SSH/tmux.

### No shared detection utility

Each tool that detects appearance reimplements the same logic (see
`home/dot_local/libexec/executable_claude-powerline-theme` for the current
pattern). A shared shell function or utility SHOULD be extracted to avoid
duplication. This will likely be solved alongside the remote detection gap.

### Per-tool status

| Tool | Catppuccin | Auto-detect | Gap |
|------|-----------|-------------|-----|
| Ghostty | Native port | Native OS integration | — |
| Neovim | `catppuccin/nvim` plugin | Plugin handles it | — |
| Claude Powerline | Custom JSON themes | `defaults read` | — |
| Zsh | ANSI names via terminal | Inherits from terminal | — |
| tmux status bar | Custom theme | Hardcoded to Mocha | No light mode switching |
| Mise | Supports `catppuccin` | Not configured | Not set to catppuccin |

## More Information

* **Color reference & implementation guide**: [docs/catppuccin.md](../catppuccin.md)

### Revisit When

* A shared appearance-detection utility is implemented (resolves both known gaps)
* Remote appearance propagation is solved (SSH, containers)
* A tool is encountered where Catppuccin pastels genuinely impair readability
* Frappe or Macchiato variants are needed for a specific use case
