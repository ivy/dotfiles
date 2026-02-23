# Catppuccin Color Reference

The standard color palette for this dotfiles repo. See
[ADR 004](adrs/004-catppuccin-color-palette-standard.md) for the decision
rationale.

Source: [catppuccin/palette](https://github.com/catppuccin/palette) (MIT
License, 2021, Catppuccin Contributors)

## Color Reference

### Latte (Light Mode)

| Name | Hex |
|------|-----|
| Rosewater | `#dc8a78` |
| Flamingo | `#dd7878` |
| Pink | `#ea76cb` |
| Mauve | `#8839ef` |
| Red | `#d20f39` |
| Maroon | `#e64553` |
| Peach | `#fe640b` |
| Yellow | `#df8e1d` |
| Green | `#40a02b` |
| Teal | `#179299` |
| Sky | `#04a5e5` |
| Sapphire | `#209fb5` |
| Blue | `#1e66f5` |
| Lavender | `#7287fd` |
| Text | `#4c4f69` |
| Subtext 1 | `#5c5f77` |
| Subtext 0 | `#6c6f85` |
| Overlay 2 | `#7c7f93` |
| Overlay 1 | `#8c8fa1` |
| Overlay 0 | `#9ca0b0` |
| Surface 2 | `#acb0be` |
| Surface 1 | `#bcc0cc` |
| Surface 0 | `#ccd0da` |
| Base | `#eff1f5` |
| Mantle | `#e6e9ef` |
| Crust | `#dce0e8` |

### Mocha (Dark Mode)

| Name | Hex |
|------|-----|
| Rosewater | `#f5e0dc` |
| Flamingo | `#f2cdcd` |
| Pink | `#f5c2e7` |
| Mauve | `#cba6f7` |
| Red | `#f38ba8` |
| Maroon | `#eba0ac` |
| Peach | `#fab387` |
| Yellow | `#f9e2af` |
| Green | `#a6e3a1` |
| Teal | `#94e2d5` |
| Sky | `#89dceb` |
| Sapphire | `#74c7ec` |
| Blue | `#89b4fa` |
| Lavender | `#b4befe` |
| Text | `#cdd6f4` |
| Subtext 1 | `#bac2de` |
| Subtext 0 | `#a6adc8` |
| Overlay 2 | `#9399b2` |
| Overlay 1 | `#7f849c` |
| Overlay 0 | `#6c7086` |
| Surface 2 | `#585b70` |
| Surface 1 | `#45475a` |
| Surface 0 | `#313244` |
| Base | `#1e1e2e` |
| Mantle | `#181825` |
| Crust | `#11111b` |

## Style Guide

Distilled from the [upstream style
guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md).
**Legibility always comes first** — deviate from these guidelines when needed
for contrast (e.g., use Base for text on colored backgrounds).

### Background Layering

Use these colors to build visual depth. Each level is slightly more prominent
than the one below it:

| Layer | Color | Use for |
|-------|-------|---------|
| Background | Base | Primary pane / canvas |
| Secondary pane | Crust, Mantle | Side panels, status bars, secondary areas |
| Raised surface | Surface 0 / 1 / 2 | Cards, input fields, raised containers (higher = more prominent) |
| Overlay | Overlay 0 / 1 / 2 | Floating menus, tooltips, pop-ups (higher = more prominent) |

### Typography & Text Hierarchy

| Function | Color |
|----------|-------|
| Body copy, headlines | Text |
| Sub-headlines, labels | Subtext 0, Subtext 1 |
| Subtle / muted text | Overlay 1 |
| Text on colored background | Base (Latte) / Crust (Mocha) |

### UI Elements

| Element | Color |
|---------|-------|
| Cursor | Rosewater |
| Selection background | Overlay 2 at 20-30% opacity |
| Active border | Lavender |
| Inactive border | Overlay 0 |
| Links / URLs | Blue |
| Tags, pills | Blue |
| Success | Green |
| Warnings | Yellow |
| Errors | Red |

### Terminal ANSI Colors

This repo uses Latte and Mocha only. Black/white mappings are inverted between
light and dark variants to maintain contrast.

| ANSI | Name | Mocha | Latte |
|------|------|-------|-------|
| 0 | Black | Surface 1 | Subtext 1 |
| 1 | Red | Red | Red |
| 2 | Green | Green | Green |
| 3 | Yellow | Yellow | Yellow |
| 4 | Blue | Blue | Blue |
| 5 | Magenta | Pink | Pink |
| 6 | Cyan | Teal | Teal |
| 7 | White | Subtext 0 | Surface 2 |
| 8 | Bright Black | Surface 2 | Subtext 0 |
| 9-14 | Bright colors | Auto-generated (see below) | Auto-generated |
| 15 | Bright White | Subtext 1 | Surface 1 |
| 16 | Extended | Peach | Peach |
| 17 | Extended | Rosewater | Rosewater |

**Bright color generation** (colors 9-14, excluding black/white):

- Dark variants: `lightness * 0.94`, `chroma + 8`, `hue + 2`
- Latte: `lightness * 1.09`, `hue + 2`

Window colors: cursor = Rosewater, cursor text = Crust (Mocha) / Base
(Latte), active border = Lavender, inactive border = Overlay 0, bell =
Yellow.

### Code Editor Syntax

| Syntax element | Color |
|----------------|-------|
| Keywords | Mauve |
| Strings | Green |
| Symbols, atoms, builtins | Red |
| Escape sequences, regex | Pink |
| Comments, braces, delimiters | Overlay 2 |
| Constants, numbers | Peach |
| Operators | Sky |
| Methods, functions, properties | Blue |
| Parameters | Maroon |
| Classes, types, annotations, attributes | Yellow |
| Enum variants | Teal |
| Macros | Rosewater |
| Line numbers | Overlay 1 |
| Active line number | Lavender |
| Cursor line | Text at 10% opacity |

**Rainbow highlights** (brackets, headings): Red, Peach, Yellow, Green,
Sapphire, Lavender.

**Search**: foreground = Text, background = Teal; active match background =
Red.

**Editor diagnostics**: errors = Red, warnings = Yellow or Peach, info = Teal.

### Diff & Merge

| Element | Color |
|---------|-------|
| Diff header | Blue |
| Index metadata | Overlay 2 |
| File path markers | Pink |
| Hunk header | Peach |
| Inserted line / text BG | Green at 15-25% / 10-20% opacity |
| Changed line / text BG | Blue at 15-25% / 10-20% opacity |
| Removed line / text BG | Red at 15-25% / 10-20% opacity |

### Debugging

Breakpoint icon = Red. Breakpoint line during execution = Yellow at 15%
opacity. Inactive breakpoint line = transparent.

## Implementing a New Tool Theme

When adding Catppuccin theming to a tool:

1. **Check for an official port** at [github.com/catppuccin](https://github.com/catppuccin) —
   prefer it over manual configuration
2. **If no port exists**, use the style guide tables above to map the tool's
   color settings to Catppuccin names
3. **Support both variants** — configure Latte and Mocha, switching based on
   system appearance
4. **Use semantic names** — map tool concepts to Catppuccin names consistently
   (e.g., errors to Red, warnings to Yellow, success to Green)
5. **Pin the port version** if installed via chezmoi externals — Renovate
   handles updates

### Quick Semantic Reference

When building a custom theme, use these conventions:

| Purpose | Catppuccin Color |
|---------|-----------------|
| Error / danger | Red |
| Warning | Yellow |
| Success / ok | Green |
| Info / link | Blue |
| Accent / highlight | Mauve |
| Secondary accent | Lavender |
| Primary text | Text |
| Secondary text | Subtext 1 |
| Muted text | Overlay 1 |
| Background | Base |
| Slightly raised surface | Surface 0 |
| Borders / dividers | Surface 1 |

### Appearance Detection

Use the shared `appearance` utility — it outputs `dark` or `light`, always
exits 0, and supports env-var override for remote systems:

```sh
case "$("$HOME/.local/libexec/dotfiles/appearance")" in
  dark) variant="mocha" ;;
  *)    variant="latte" ;;
esac
```

The utility checks (in order): `BG` env var, macOS `defaults
read`, then falls back to `light`. See
`home/dot_local/libexec/dotfiles/executable_appearance` for the implementation.
