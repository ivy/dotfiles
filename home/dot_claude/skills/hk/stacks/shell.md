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

- **shellcheck glob**: Default is `List("**/*.sh", "**/*.bash")`. Does **not** match `.zsh` files — shellcheck doesn't support zsh syntax. Don't add `*.zsh` to shellcheck glob.
- **shfmt glob**: Default includes `List("**/*.sh", "**/*.bash", "**/*.mksh", "**/*.bats", "**/*.zsh")`. Broader than shellcheck — formats bats and zsh too.
- **shfmt respects .editorconfig**: shfmt reads indent style/size from `.editorconfig`. If the project has one, shfmt will use it. The `--apply-ignore` flag respects editorconfig `ignore = true` directives.
- **.tmpl files**: If the project uses chezmoi or other template engines, exclude `.tmpl` files from both builtins — template syntax will cause parse errors. Add `exclude = "**/*.tmpl"` to each step.
- **batch mode**: Both builtins use `batch = true` for parallelism — shellcheck and shfmt are single-threaded, so batching improves performance on large codebases.

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
