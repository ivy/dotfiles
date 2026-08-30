# macOS Preferences

System preferences applied by `home/run_onchange_configure-macos-preferences.sh.tmpl`, a
`run_onchange_` script guarded by `{{ if eq .chezmoi.os "darwin" }}` — it re-runs whenever its
rendered content changes and is a no-op on Linux.

## Overview

- **Idempotent**: every stanza reads the current value and skips when it already matches
- **User domains only**: writes go to domains `defaults` can reach without elevation
- **Restarts what it must**: `activateSettings -u`, `killall Dock`, `killall ControlCenter`

## Applied Settings

| Setting | Domain / key |
|---------|--------------|
| Disable Spotlight ⌘Space | `com.apple.symbolichotkeys` HotKey 64 |
| Raycast ⌘Space | `com.raycast.macos raycastGlobalHotkey` |
| Wallpaper (Monterey Graphic) | System Events via `osascript` |
| Key repeat rate and delay | `NSGlobalDomain KeyRepeat`, `InitialKeyRepeat` |
| Full keyboard navigation | `NSGlobalDomain AppleKeyboardUIMode` |
| Empty Dock | `com.apple.dock persistent-apps` |
| Bluetooth in menu bar | `com.apple.controlcenter "NSStatusItem VisibleCC Bluetooth"` |

Raycast's hotkey is best-effort: a running Raycast holds its preferences in memory and writes
them back on quit, overwriting the value.

## Manual Steps

### Ctrl+scroll zoom

Enable by hand in **System Settings → Accessibility → Zoom → Use scroll gesture with modifier
keys to zoom**, with the modifier set to Control.

The live state is `closeViewScrollWheelToggle` and `closeViewScrollWheelModifiersInt` in
`com.apple.universalaccess`. That domain is TCC-protected, and `defaults write` against it is
refused outright:

```console
$ defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
Could not write domain com.apple.universalaccess; exiting
```

Writing the same keys into the user-writable `com.apple.Accessibility` domain does not work —
nothing reads them there for this feature, and the accessibility daemon prunes the ones that
are not part of that domain's schema. Reads against `com.apple.universalaccess` do succeed, so
the setting can be inspected; only the write is blocked.
