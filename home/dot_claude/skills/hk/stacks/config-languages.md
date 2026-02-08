# Config Languages Stack

Pkl and YAML formatting and linting.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `*.pkl` | High (for pkl/pkl_format) |
| `**/*.yml` or `**/*.yaml` (non-GHA) | High (for yamlfmt/yamllint) |
| `PklProject` | High (for pkl) |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| pkl | `Builtins.pkl` | Evaluates Pkl files for correctness |
| pkl-format | `Builtins.pkl_format` | Formats Pkl files |
| yamlfmt | `Builtins.yamlfmt` | Formats YAML files |
| yamllint | `Builtins.yamllint` | Lints YAML files |

## Tool Install Commands

```bash
mise use pkl          # for pkl and pkl_format
mise use yamlfmt      # YAML formatter
mise use yamllint     # YAML linter (Python-based)
```

## Gotchas

- **pkl_format exit code 11**: The builtin handles this with a custom shell wrapper — `pkl format` exits 11 even when it successfully formats files. The builtin's `fix` command catches exit 11 and returns 0. Do not override the fix command without preserving this logic.
- **pkl uses `types` not `glob`**: The builtin uses `types = List("pkl")` for file matching, which catches files by extension and content detection.
- **yamllint --strict**: The builtin runs `yamllint --strict {{files}}` which treats warnings as errors. Projects may need a `.yamllint.yml` config to customize rules.
- **yamlfmt needs config**: Respects `yamlfmt.yaml` or `.yamlfmt.yml` in the project root. Without it, uses default formatting which may not match project conventions.
- **Skip YAML builtins for GHA-only YAML**: If the only YAML files in the project are GitHub Actions workflows, skip yamlfmt/yamllint — ghalint handles those better. Including both causes conflicts (ghalint expects specific formatting that yamlfmt may change).
- **Overlap with GHA stack**: If both stacks are included, exclude `.github/` from yamlfmt and yamllint to avoid conflicts.

## Example Pkl Snippet

```pkl
// Pkl validation and formatting
["pkl"] = Builtins.pkl
["pkl-format"] = Builtins.pkl_format

// YAML — exclude GHA workflows if ghalint is also included
["yamlfmt"] = (Builtins.yamlfmt) {
  exclude = ".github/"
}
["yamllint"] = (Builtins.yamllint) {
  exclude = ".github/"
}
```
