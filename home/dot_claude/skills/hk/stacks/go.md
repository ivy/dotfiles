# Go Stack

Go formatting, linting, security scanning, and module maintenance.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `go.mod` | High |
| `**/*.go` | High |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| go-imports | `Builtins.go_imports` | Manages Go import grouping and ordering |
| go-vet | `Builtins.go_vet` | Reports suspicious constructs in Go code |
| go-sec | `Builtins.go_sec` | Security scanner for Go code |
| gomod-tidy | `Builtins.gomod_tidy` | Ensures `go.mod` and `go.sum` are tidy |

## Tool Install Commands

```bash
mise use go
mise use goimports     # separate tool, not part of Go toolchain
mise use gosec         # for go_sec
```

## Gotchas

- **goimports is a separate install**: Unlike `go vet` which ships with Go, `goimports` requires `mise use goimports` (or `go install golang.org/x/tools/cmd/goimports@latest`).
- **go_sec is slow**: Put it behind a `slow` profile: `profiles = List("slow")`. It does deep analysis and can take significant time on large codebases.
- **gomod_tidy uses check_diff**: The builtin uses `go mod tidy -diff` which outputs a patch that hk can apply directly — more efficient than running the fix separately. The glob is `**/go.mod` and it uses workspace-level detection.
- **go_vet and go_sec take `{{files}}`**: Both accept file arguments directly, so they benefit from hk's file filtering.
- **go_imports has fix**: The builtin defines both `check = "goimports -l {{files}}"` (list mode) and `fix = "goimports -w {{files}}"` (write mode).

## Example Pkl Snippet

```pkl
["go-imports"] = Builtins.go_imports
["go-vet"] = Builtins.go_vet
["go-sec"] = (Builtins.go_sec) {
  profiles = List("slow")
}
["gomod-tidy"] = Builtins.gomod_tidy
```
