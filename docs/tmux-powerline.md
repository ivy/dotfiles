# tmux-powerline

Status bar via [erikw/tmux-powerline](https://github.com/erikw/tmux-powerline) with Catppuccin theming and a notification rail design.

## Design: notification rail

The status bar is silent by default and loud when something needs attention. It does not duplicate information already visible elsewhere (macOS menu bar: time/date/battery; shell prompt: cwd/git; Neovim statusline: cwd/branch).

```
[session:win.pane]  ···  [window tabs]  ···  [mode] [host?] [gh?] [load?] [mem?] [disk?]
     left                   center                     right (conditional)
```

**Left** — session identity only (`session:window.pane`).\
**Center** — tmux window list (built-in).\
**Right** — mode indicator (always) + alert segments that appear/disappear based on state.

Under normal local conditions only `tmux_session_info` and `mode_indicator` are visible. Alert segments pop in when thresholds are crossed.

## File map

```
home/dot_config/tmux-powerline/
  config.sh                     # Main configuration (theme, intervals, GitHub token)
  helpers/
    alert_helpers.sh            # tp_alert_color_* functions for color escalation
  segments/
    alert_hostname.sh           # Shows hostname in SSH/container sessions
    alert_load.sh               # Shows load when 1-min load > core count
    alert_mem.sh                # Shows memory usage when > 80%
    alert_disk.sh               # Shows disk usage when > 85%
  themes/
    catppuccin-mocha.sh         # Dark mode theme (segment arrays + colors)
    catppuccin-latte.sh         # Light mode theme (segment arrays + colors)
```

The upstream tmux-powerline is installed as a chezmoi external to `~/.config/tmux/plugins/tmux-powerline/`.

## Right-side segments

| Segment | Always shown | Trigger condition | Icon |
|---------|-------------|-------------------|------|
| `mode_indicator` | yes | — | varies by mode |
| `alert_hostname` | no | `$SSH_CONNECTION`, `$SSH_TTY`, `$SSH_CLIENT` set, or `/.dockerenv` exists | short hostname |
| `github_notifications` | no | unread count > 0 (upstream segment behavior) | bell icon + count |
| `alert_load` | no | 1-min load average > CPU core count | ` ` + load averages |
| `alert_mem` | no | memory usage ≥ 80% | ` ` + used GB |
| `alert_disk` | no | root filesystem ≥ 85% used | ` ` + percent |

Segments return empty output when below threshold — powerline hides zero-width segments automatically.

## Color escalation

Alert segment background colors are computed by `tp_alert_color_*` functions in `alert_helpers.sh` and injected into the theme arrays at source time via `$(...)` subshells.

| Resource | normal | warning | critical |
|----------|--------|---------|----------|
| Load | `$surface0` (hidden) | `$yellow` (> cores) | `$red` (> 2× cores) |
| Memory | `$surface0` (hidden) | `$yellow` (≥ 80%) | `$red` (≥ 90%) |
| Disk | `$surface0` (hidden) | `$yellow` (≥ 85%) | `$red` (≥ 95%) |

`$surface0` is used as the "below threshold" color — it still renders with that background, but the segment returns empty output so nothing is shown. The segment file controls visibility; the theme controls color severity.

## Helper functions (`alert_helpers.sh`)

Sourced by theme files **after** the palette is defined, so `$yellow`, `$red`, `$surface0` are already in scope.

| Function | Returns | Notes |
|----------|---------|-------|
| `tp_cpu_count` | integer | `sysctl -n hw.ncpu` (macOS), `nproc` (Linux), fallback 1 |
| `tp_alert_color_load` | palette variable | Reads 1-min load from `uptime`, compares to `tp_cpu_count` |
| `tp_alert_color_mem` | palette variable | Delegates to `tp_mem_used_percentage_at_least` from upstream |
| `tp_alert_color_disk` | palette variable | Parses `df /` for root filesystem percent |

These functions echo a color hex string (e.g. `#f9e2af`), which becomes the background argument in the segment definition.

## Configuration (`config.sh`)

| Variable | Value | Purpose |
|----------|-------|---------|
| `TMUX_POWERLINE_THEME` | `catppuccin-mocha` or `catppuccin-latte` | Auto-detected from system appearance |
| `TMUX_POWERLINE_STATUS_INTERVAL` | `5` | Refresh every 5 seconds |
| `TMUX_POWERLINE_STATUS_LEFT_LENGTH` | `30` | Narrow — session info only |
| `TMUX_POWERLINE_STATUS_RIGHT_LENGTH` | `90` | Wide enough for all alerts firing simultaneously |
| `TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_TOKEN` | from `gh auth token` | Auth for GitHub API |
| `TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_HIDE_NO_NOTIFICATIONS` | `yes` | Hides segment when count is zero |
| `TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_SYMBOL_MODE` | `yes` | Shows icon instead of text label |
| `TMUX_POWERLINE_SEG_GITHUB_NOTIFICATIONS_SUMMARIZE` | `yes` | Single count instead of per-repo breakdown |

## Adding a new alert segment

1. Create `home/dot_config/tmux-powerline/segments/alert_<name>.sh`:
   ```bash
   # shellcheck shell=bash
   run_segment() {
       # Return empty to hide, echo content to show
       if <condition>; then
           echo "icon content"
           return 0
       fi
       return 0
   }
   ```

2. Add a helper to `alert_helpers.sh` if color escalation is needed:
   ```bash
   tp_alert_color_<name>() {
       if <critical>; then echo "$red"
       elif <warning>; then echo "$yellow"
       else echo "$surface0"
       fi
   }
   ```

3. Add the segment to both theme arrays in `catppuccin-mocha.sh` and `catppuccin-latte.sh`:
   ```bash
   # Mocha (fg: $crust), Latte (fg: $base)
   "alert_<name> $(tp_alert_color_<name>) $crust"
   ```

4. Apply and reload:
   ```bash
   chezmoi apply
   tmux source-file ~/.config/tmux/tmux.conf
   ```

## Adjusting thresholds

Thresholds live in two places:

- **Color escalation** — in `tp_alert_color_*` functions in `alert_helpers.sh`
- **Segment visibility** — in `run_segment()` in the segment file itself

Both must be updated together to keep color and visibility in sync. For example, to lower the memory warning threshold from 80% to 70%:
- In `alert_helpers.sh`: change `tp_mem_used_percentage_at_least 80` to `70`
- In `alert_mem.sh`: change the `run_segment` threshold check from `80` to `70`

## Theming

Both `catppuccin-mocha.sh` and `catppuccin-latte.sh` share the same structure. Key difference: alert segment foreground color uses `$crust` (Mocha) vs `$base` (Latte) to maintain contrast on each palette.

The theme files source `alert_helpers.sh` immediately after the palette block so helper functions can reference color variables:

```bash
source "${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/helpers/alert_helpers.sh"
```

The `$(tp_alert_color_*)` subshells in the segment arrays are evaluated once at theme source time (every 5 seconds), not per-render — color updates on the next refresh cycle.

## Troubleshooting

### Status bar not updating

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

Or from inside tmux: `prefix + r`.

### Alert segment always visible / never visible

Run the segment directly to check output:
```bash
bash -c 'source ~/.config/tmux/plugins/tmux-powerline/lib/headers.sh; source ~/.config/tmux-powerline/segments/alert_mem.sh; run_segment'
```

Empty output = segment would be hidden. Non-empty = segment would appear.

### GitHub notifications not showing

```bash
gh auth status          # Confirm authenticated
gh auth token           # Confirm token is non-empty
```

The segment uses a cache file — stale cache can delay changes by up to 60 seconds (default `UPDATE_INTERVAL`).

### Wrong theme after appearance change

`prefix + r` — config re-detects appearance on reload.

## References

- [erikw/tmux-powerline](https://github.com/erikw/tmux-powerline) — upstream
- [docs/tmux.md](tmux.md) — tmux config, plugins, keybindings
- [docs/catppuccin.md](catppuccin.md) — palette and appearance detection
