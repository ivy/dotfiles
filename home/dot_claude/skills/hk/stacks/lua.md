# Lua Stack

Lua formatting.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `*.lua` | High |
| `.stylua.toml` | High |
| `init.lua` | High |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| stylua | `Builtins.stylua` | Formats Lua code |

## Tool Install Commands

```bash
mise use stylua
```

## Gotchas

- **Requires `.stylua.toml`**: StyLua needs a config file in the project root (or parent). Without it, it uses built-in defaults which may not match project conventions. Create one before running.
- **Uses `types` not `glob`**: The builtin uses `types = List("lua")` which matches `.lua` files by extension and shebang detection.
- **Uses `check_diff` not `check`**: The builtin uses `check_diff = "stylua --check {{files}}"` which outputs a diff that hk can apply directly. This is more efficient than separate check/fix cycles.
- **No `check` command**: Since the builtin uses `check_diff`, there is no separate `check` field. hk handles the diff-based workflow automatically.

## Example Pkl Snippet

```pkl
["stylua"] = Builtins.stylua
```
