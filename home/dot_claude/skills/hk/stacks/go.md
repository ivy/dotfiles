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
- **A module in a subdirectory**: a step's command runs from the repository root. Scope the step with `glob` (`server/**/*.go`) and change directory in the command (`cd server && go vet ./...`). A literal `dir = "server"` also scopes the step's `glob` and `exclude` to that directory, so patterns written from the root then match nothing: the step is skipped without an error, and `hk check --plan -g FILE` shows `no files matched filters`. hk's `Config.pkl` documents `workspace_indicator = "go.mod"` with `dir = "{{workspace}}"` as its per-module form. The builtins above have not been tried against a module in a subdirectory.
- **gofmt needs nothing installed**: where goimports isn't wanted, a step around `gofmt -l` checks formatting and `gofmt -w` fixes it. See the snippet.
- **Tests on commit**: a step that runs the suite, with a `glob` covering everything the suite reads, not only `.go` files: protocol definitions, SQL, fixtures. A suite of about 20 seconds is comfortable on commit.

## Example Pkl Snippet

```pkl
["go-imports"] = Builtins.go_imports
["go-vet"] = Builtins.go_vet
["go-sec"] = (Builtins.go_sec) {
  profiles = List("slow")
}
["gomod-tidy"] = Builtins.gomod_tidy
```

For a module in `server/`, with gofmt and the tests on commit:

```pkl
["gofmt"] {
  glob = "server/**/*.go"
  check = "test -z \"$(gofmt -l {{files}})\" || { gofmt -l {{files}}; exit 1; }"
  fix = "gofmt -w {{files}}"
}
["go-vet"] {
  glob = "server/**/*.go"
  check = "cd server && go vet ./..."
}
["go-test"] {
  glob = List("server/**", "proto/**")
  check = "cd server && go test ./..."
}
```
