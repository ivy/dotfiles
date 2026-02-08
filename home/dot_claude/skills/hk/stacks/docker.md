# Docker Stack

Dockerfile linting.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `Dockerfile` | High |
| `**/Dockerfile*` | High |
| `Containerfile` | High |
| `docker-compose.yml` / `compose.yml` | Medium |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| hadolint | `Builtins.hadolint` | Lints Dockerfiles for best practices |

## Tool Install Commands

```bash
mise use hadolint
```

## Gotchas

- **Default glob misses Containerfile**: The builtin glob is `**/Dockerfile*`. If the project uses Podman-style `Containerfile`, override the glob to include it.
- **hadolint has no fix command**: It's check-only. Fixes must be applied manually.
- **hadolint config**: Respects `.hadolint.yaml` in the project root for rule configuration (ignore rules, trusted registries, etc.).

## Example Pkl Snippet

```pkl
// Standard — Dockerfile only
["hadolint"] = Builtins.hadolint

// For projects using Containerfile (Podman)
["hadolint"] = (Builtins.hadolint) {
  glob = List("**/Dockerfile*", "**/Containerfile*")
}
```
