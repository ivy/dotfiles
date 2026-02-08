# Rust Stack

Rust formatting, linting, and type checking.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `Cargo.toml` | High |
| `**/*.rs` | High |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| cargo-fmt | `Builtins.cargo_fmt` | Formats Rust code via `cargo fmt` |
| cargo-clippy | `Builtins.cargo_clippy` | Lints Rust code via `cargo clippy` |
| cargo-check | `Builtins.cargo_check` | Fast type checking via `cargo check` |

## Tool Install Commands

```bash
# Rust toolchain (rustfmt, clippy included)
mise use rust
# For cargo-check's nightly requirement
rustup toolchain install nightly
```

## Gotchas

- **cargo-clippy is slow**: Always put it behind a `slow` profile so it doesn't run on every commit. Use `profiles = List("slow")` and override the check command to add `-D warnings`.
- **cargo-check needs nightly**: The builtin uses `cargo +nightly check -Zwarnings` to enable the unstable `CARGO_BUILD_WARNINGS=deny` feature. Ensure `rustup toolchain install nightly` has been run.
- **cargo-check profiles**: Use `profiles = List("!slow")` so it runs by default but is skipped when running the `slow` profile (where clippy covers the same ground more thoroughly).
- **workspace_indicator**: Both cargo-clippy and cargo-fmt use `workspace_indicator = "Cargo.toml"` for monorepo support. Each workspace gets its own invocation.
- **check_first = false on clippy**: The builtin sets this because clippy's fix modifies code and needs a write lock upfront.

## Example Pkl Snippet

```pkl
["cargo-fmt"] = Builtins.cargo_fmt
["cargo-clippy"] = (Builtins.cargo_clippy) {
  profiles = List("slow")
  check = "cargo clippy --manifest-path {{workspace_indicator}} --quiet -- -D warnings"
}
["cargo-check"] = (Builtins.cargo_check) {
  profiles = List("!slow")
}
```
