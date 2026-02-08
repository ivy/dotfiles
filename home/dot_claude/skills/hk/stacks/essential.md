# Essential Stack

Universal checks and formatters that apply to virtually every project.

## Detection

Always included — no indicator files needed.

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| check-merge-conflict | `Builtins.check_merge_conflict` | Detects leftover merge conflict markers |
| check-executables-have-shebangs | `Builtins.check_executables_have_shebangs` | Ensures executable files have shebang lines |
| check-symlinks | `Builtins.check_symlinks` | Validates symlinks point to existing targets |
| detect-private-key | `Builtins.detect_private_key` | Prevents committing private keys |
| mixed-line-ending | `Builtins.mixed_line_ending` | Catches files with mixed LF/CRLF |
| trailing-whitespace | `Builtins.trailing_whitespace` | Removes trailing whitespace |
| newlines | `Builtins.newlines` | Ensures files end with a newline |
| editorconfig-checker | `Builtins.editorconfig_checker` | Validates files against `.editorconfig` rules |
| jq | `Builtins.jq` | Formats and validates JSON files |
| markdown-lint | `Builtins.markdown_lint` | Lints Markdown files |
| mise | `Builtins.mise` | Formats mise config files (`mise.toml` etc.) |

## Tool Install Commands

```bash
mise use editorconfig-checker
mise use jq
mise use markdownlint-cli    # provides the `markdownlint` binary
mise use mise                 # usually already installed
```

## Gotchas

- **editorconfig-checker**: The binary is called `ec`, not `editorconfig-checker`. Requires a `.editorconfig` file in the project root — the builtin is useless without one.
- **jq**: The `fix` command uses `jq -S` which **sorts object keys**. This is intentional for consistency but may surprise users. If key order matters, override the fix command.
- **markdown-lint**: Requires `markdownlint` CLI (from `markdownlint-cli` npm package). Install via `mise use npm:markdownlint-cli` or `mise use aqua:igorshubovych/markdownlint-cli`. Respects `.markdownlint.json` or `.markdownlint.yaml` config.
- **mise builtin**: Has an extensive glob list covering all mise config file locations. The `check` command runs `mise fmt --check` (ignores `{{files}}`).
- **trailing-whitespace and newlines**: These are fast, zero-dependency builtins built into hk itself. Always include them.

## Example Pkl Snippet

```pkl
// Essential checks — always include
["check-merge-conflict"] = Builtins.check_merge_conflict
["check-executables-have-shebangs"] = Builtins.check_executables_have_shebangs
["check-symlinks"] = Builtins.check_symlinks
["detect-private-key"] = Builtins.detect_private_key
["mixed-line-ending"] = Builtins.mixed_line_ending
["trailing-whitespace"] = Builtins.trailing_whitespace
["newlines"] = Builtins.newlines

// Only if .editorconfig exists
["editorconfig-checker"] = Builtins.editorconfig_checker

// JSON formatting
["jq"] = Builtins.jq

// Markdown linting
["markdown-lint"] = Builtins.markdown_lint

// mise config formatting
["mise"] = Builtins.mise
```
