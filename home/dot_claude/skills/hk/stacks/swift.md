# Swift Stack

Swift linting, and running a package's tests on commit.

## Detection Indicators

| File/Pattern | Confidence |
|---|---|
| `Package.swift` | High |
| `*.xcodeproj`, `*.xcworkspace` | High |
| `**/*.swift` | High |
| `.swiftlint.yml`, `.swiftlint.yaml` | High, for swiftlint |

## Builtins

| Name | Builtin | What it does |
|------|---------|-------------|
| swiftlint | `Builtins.swiftlint` | Swift style and conventions: `swiftlint lint {{files}}`, with `swiftlint --fix {{files}}` as its fix |

As of hk 2.11.1, swiftlint is the only Swift builtin. There is none for formatting or for running tests.

## Tool Install Commands

```bash
mise use swiftlint     # only where the project lints with it
```

`swift-format` ships in Xcode's toolchain (`xcrun --find swift-format`), with nothing to install.

## Gotchas

- **Linting and formatting are the owner's decision**: the swiftlint builtin's project indicator is a `.swiftlint.yml`. Where a project has neither that nor a formatter's configuration, adopting one flags or rewrites the whole codebase. Ask first, and leave it out of the hook otherwise. The swiftlint builtin has not been tried by this skill.
- **Tests on commit are steps you write**: `swift test` for the host platform, and a script around `xcodebuild test` for a simulator. See the snippet.
- **Durations**, from one package of about 260 tests: `swift test` takes about 40 seconds, the same tests on an iOS simulator about a minute with a warm build, and 16 UI tests a few minutes. Unit suites of that size are comfortable on commit. Leave UI tests a manual task.
- **`exclusive = true` on the test steps**: it keeps other steps from starting until the step finishes, so two builds don't compete. `depends` names steps that must finish before a step runs.
- **Globs**: a suite depends on more than `Sources/`. Watch the whole package directory, with its tests, resources and `Package.swift`, and exclude what can't change the result (docs, scripts, and UI tests when the hook doesn't run them).
- **Change directory in the command**: `check = "cd apps/app && swift test"`. A literal `dir` also scopes the step's `glob` and `exclude` to that directory, so a step watching two roots (`apps/app/**` and `packages/**`) matches nothing and is skipped without an error. `hk check --plan -g FILE` shows `no files matched filters`.
- **`xcodebuild` beside both an `.xcodeproj` and a `Package.swift` builds the project**: `xcodebuild test -scheme Name-Package` then fails with `The project named "…" does not contain a scheme named "Name-Package"`, and no flag selects the package. Keep the Xcode project in a subdirectory of the package.

## Example Pkl Snippet

```pkl
["swift-test"] {
  glob = List("apps/app/**", "packages/**")
  exclude = List("**/*.md", "apps/app/scripts/**", "apps/app/UITests/**")
  check = "cd apps/app && swift test"
  exclusive = true
}
["swift-test-ios"] {
  glob = List("apps/app/**", "packages/**")
  exclude = List("**/*.md", "apps/app/scripts/**", "apps/app/UITests/**")
  // A script around `xcodebuild test` on a simulator, exiting non-zero on failure.
  check = "apps/app/scripts/test-ios.sh"
  exclusive = true
  depends = List("swift-test")
}

// Only where the project already lints with it
["swiftlint"] = Builtins.swiftlint
```
