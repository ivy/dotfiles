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
mise use editorconfig-checker@VERSION
mise use jq@VERSION
mise use npm:markdownlint-cli@VERSION   # NOT aqua — aqua only has markdownlint-cli2
mise use mise@VERSION                    # usually already installed
```

Resolve each VERSION with `mise ls-remote TOOL | tail -1` before running.

## Gotchas

- **editorconfig-checker**: The binary is called `ec`, not `editorconfig-checker`. Requires a `.editorconfig` file in the project root — the builtin is useless without one.
- **jq + JSONC**: The `fix` command uses `jq -S` which **sorts object keys** and **cannot parse JSONC** (JSON with `//` comments). Scan `.json` files for `//` comments — if any exist (common in VS Code/Cursor configs like `keybindings.json`, `settings.json`), exclude them: `exclude = List("**/.vscode/**", "**/private_Library/**")`. Alternatively, exclude the specific files.
- **markdown-lint**: Requires `markdownlint` CLI. **Use `npm:markdownlint-cli`** — the aqua registry does not have `markdownlint-cli` (only `markdownlint-cli2`, which has a different CLI interface). On existing repos, defaults produce thousands of errors. **Always generate a `.markdownlint.json`** during planning — run `markdownlint --disable MD013 MD060 -- '**/*.md' 2>&1 | wc -l` to gauge noise, then disable the noisiest rules upfront. Common rules to disable: **MD013** (line length — conflicts with prose), **MD060** (table-column-style — enforces table pipe alignment, noisy on hand-authored tables).
- **detect-private-key**: Triggers false positives on reference docs, gitingest dumps, and vendored text files that mention "PRIVATE KEY" in documentation. Exclude directories like `docs/reference/`, `vendor/`, or any large text dump directories.
- **mise builtin**: Has an extensive glob list covering all mise config file locations. The `check` command runs `mise fmt --check` (ignores `{{files}}`).
- **trailing-whitespace and newlines**: These are fast, zero-dependency builtins built into hk itself. Always include them.

## Example Pkl Snippet

```pkl
// Essential checks — always include
["check-merge-conflict"] = Builtins.check_merge_conflict
["check-executables-have-shebangs"] = Builtins.check_executables_have_shebangs
["check-symlinks"] = Builtins.check_symlinks
["mixed-line-ending"] = Builtins.mixed_line_ending
["trailing-whitespace"] = Builtins.trailing_whitespace
["newlines"] = Builtins.newlines

// Only if .editorconfig exists
["editorconfig-checker"] = Builtins.editorconfig_checker

// JSON formatting — exclude JSONC files (VS Code/Cursor configs with // comments)
["jq"] = (Builtins.jq) {
  exclude = List("**/.vscode/**", "**/private_Library/**")
}

// Markdown linting — exclude vendor/reference dumps
["markdown-lint"] = (Builtins.markdown_lint) {
  exclude = "docs/reference/"
}

// Detect private keys — exclude reference docs (gitingest dumps mention keys)
["detect-private-key"] = (Builtins.detect_private_key) {
  exclude = "docs/reference/"
}

// mise config formatting
["mise"] = Builtins.mise
```
