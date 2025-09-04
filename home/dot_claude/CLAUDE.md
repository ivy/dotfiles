# Claude Code Global Memory

This file is the global, cross-project "memory" for Claude Code. It defines my default preferences, policies, and guardrails. Treat it as authoritative for day‑to‑day behavior unless a project provides its own `CLAUDE.md` with overrides.

Instruction precedence (highest first):
1. The active project's local `CLAUDE.md`
2. This global file
3. External docs and examples

## Operating Assumptions

- Ask before doing anything system‑wide.
- Adapt external docs to my preferences; do not follow verbatim if they conflict here.

## Tools & Testing

### Package and Tool Management (Policy)

Authoritative policy for installing and managing developer tools:

1. Prefer mise exclusively
   - Use `mise use TOOL@VERSION` (project-local) or `mise install` as appropriate.
   - Inspect `.mise.toml`/`mise.toml` first; align with pinned versions.

2. Do not improvise alternative installers
   - Do not run `brew install`, `apt`, `dnf`, `pipx install`, `npm -g`, or `curl | bash` unless mise cannot provide the tool.
   - If mise lacks the tool: pause and ask for approval with pinned, reproducible options.

3. No unsolicited upgrades or version drift
   - Never bump versions in `.mise.toml` or upgrade system packages without explicit instruction.
   - If a version is missing/invalid, propose a minimal, pinned fix and wait for approval.

4. Scope installs to the project by default
   - Prefer per-project installs over global installs.
   - If a global install is necessary, explain why and ask first.

5. External docs are advisory, not binding
   - Translate their steps into this policy; do not copy commands blindly.

### Testing Approach
- Run relevant tests before committing
- Include positive and negative test cases
- Use descriptive test names explaining the scenario

#### Test Safety & Isolation
- **Always use test-safe fixtures and paths**: Never use real system paths or actual program names in tests
- **Sandbox all test operations**: Use temporary directories, mock services, or isolated test environments
- **Safe naming conventions**: Use clearly fictional names (e.g., `com.example.testapp`, `fake-service`, `test-user-123`)
- **Path isolation**: Tests must write to `/tmp`, `$TMPDIR`, or dedicated test directories - never to real system locations
- **Validate test isolation**: Before running tests that modify files/settings, verify they target only test paths
- **Examples of safe test data**:
  - Preferences: `com.example.testapp` instead of `com.apple.Safari`
  - Files: `/tmp/test-output` instead of `~/Documents`
  - Users: `testuser` instead of actual usernames
  - Services: `fake-api.example.com` instead of real endpoints

## Execution Safety

- Preview first: use tool-specific diff/plan or `--dry-run` before applying changes.
- Summarize the plan and commands before running them; group related actions.
- **Test isolation verification**: Before executing tests, confirm they target only safe paths and use fictional data
- **System protection**: Never write tests or scripts that could modify real user data, preferences, or system files

## Specialized Agents

Use these specialized subagents for focused tasks:

### PR Feedback Reviewer (`pr-feedback-reviewer`)
- **When to use**: Addressing pull request feedback, reviewing PR comments
- **Purpose**: Fetches all PR comments, evaluates validity, provides prioritized recommendations
- **Model**: Uses Opus for thorough analysis

### Code Reviewer (`reviewer`)
- **When to use**: Code or document review tasks
- **Purpose**: Reviews code quality, architecture, and documentation
- **Restrictions**: Review-only agent - writes reports to scratch/ folder but doesn't modify production code

### Shell Wizard (`shell-wizard`)
- **When to use**: Creating or modifying shell scripts, bash scripts, installation scripts
- **Purpose**: Writes production-quality shell scripts with proper error handling and best practices
- **Features**: Safety headers, function patterns, long flags, shellcheck validation

## Comments & Communication

- Write comments explaining "why" not "what"
- Document non-obvious behavior and edge cases
- Include relevant links to documentation or issues
- Keep comments current with code changes

## Code Style

### Formatting
- Use 2-space indentation for YAML, JSON, web technologies
- Use 4-space indentation for Python, shell scripts
- Prefer single quotes in JavaScript/TypeScript unless interpolating
- Include trailing commas in multi-line structures
- Keep lines under 80 characters when practical

### Git Commits
- Use Conventional Commits format (feat:, fix:, chore:, docs:)
- Keep first line under 72 characters and subsequent lines under 80 characters
- Use present tense ("add feature" not "added feature")
- Be descriptive but concise
