# Shell Stack

Shell script analysis and formatting.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `*.sh` | High |
| `*.bash` | High |
| `*.zsh` | Medium |
| `*.bats` | Medium |
| `bin/` directory with scripts | Medium |
| Files with a `sh` or `bash` shebang and no extension | Medium |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| shellcheck | `Builtins.shellcheck` | Static analysis for shell scripts |
| shfmt | `Builtins.shfmt` | Formats shell scripts |

## Tool Install Commands

```bash
mise use shellcheck
mise use shfmt
```

## Gotchas

- **File selection** (hk 2.11.1): both builtins select with `match_any`, a glob or a file type read from the shebang. shellcheck takes `**/*.sh` and `**/*.bash`, and the types `sh` and `bash`. shfmt adds `*.mksh`, `*.bats` and `*.zsh`, and the type `zsh`. Scripts with a shebang and no extension (`bin/tool`, `scripts/run`) are covered with no override. shellcheck's selection has no zsh: shellcheck doesn't support zsh syntax.
- **Don't set `glob` on them**: `(Builtins.shellcheck) { glob = … }` fails `hk validate` with `cannot combine 'match_any' with top-level 'glob' or 'types'`.
- **shfmt indents with tabs unless `.editorconfig` says otherwise**: the builtin runs `shfmt -d --apply-ignore {{ files }}` with no style flags, so shfmt's defaults apply to any file no `.editorconfig` section reaches. For two-space scripts set `indent_style = space` and `indent_size = 2`, with `switch_case_indent = true` where `case` bodies are indented and `binary_next_line = true` where `||` and `&&` lead a continued line. The `--apply-ignore` flag respects editorconfig `ignore = true` directives.
- **Give `*.sh` and path-named scripts separate `.editorconfig` sections**: `.editorconfig` can't match on a shebang, so scripts without an extension are listed by path (`[{bin/tool,scripts/run}]`). Keep `*.sh` out of those braces. A pattern containing a slash is matched from the `.editorconfig`'s directory, so `[{*.sh,bin/tool}]` stops reaching `.sh` files in subdirectories, and shfmt formats those with tabs.
- **Check the formatting by reading it**: after `hk fix`, read the diff, or count tab-indented lines with `grep -c "$(printf '\t')" FILE`. `hk check` passes whichever style shfmt applied, because check and fix read the same configuration.
- **Measure findings only with the tools pinned in the project**: before `mise use shellcheck`, the shim exits 1 with `No version is set for shim`, which looks like no findings once stderr is discarded.
- **.tmpl files**: If the project uses chezmoi or other template engines, exclude `.tmpl` files from both builtins — template syntax will cause parse errors. Add `exclude = "**/*.tmpl"` to each step.
- **batch mode**: Both builtins use `batch = true` for parallelism — shellcheck and shfmt are single-threaded, so batching improves performance on large codebases.
- **Reading a builtin**: the release archive `https://github.com/jdx/hk/releases/download/vX.Y.Z/hk@X.Y.Z.zip` holds `builtins/<name>.pkl`, with each builtin's selection rule and commands for that release. Both change between releases, so read the one you pin.

## Example Pkl Snippet

```pkl
["shellcheck"] = Builtins.shellcheck
["shfmt"] = Builtins.shfmt

// For chezmoi repos — exclude templates
["shellcheck"] = (Builtins.shellcheck) {
  exclude = "**/*.tmpl"
}
["shfmt"] = (Builtins.shfmt) {
  exclude = "**/*.tmpl"
}
```

An `.editorconfig` for two-space scripts, some of them without an extension:

```ini
root = true

[*.sh]
indent_style = space
indent_size = 2
switch_case_indent = true
binary_next_line = true

# Scripts without an extension, in a section of their own.
[{bin/tool,scripts/run}]
indent_style = space
indent_size = 2
switch_case_indent = true
binary_next_line = true
```
