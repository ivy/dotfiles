# Claude Code Global Memory

Precedence: project CLAUDE.md > this file > external docs.

## Tool Installation

Use mise exclusively (`mise use TOOL@VERSION`). No brew, apt, npm -g, or pipx unless mise lacks the tool—then ask first. No version bumps without explicit instruction.

## Commit Strategy

Commit small and often using `/commit`. Pre-commit hooks (`hk`) enforce quality checks automatically — linting, formatting, and conventional commit messages are all validated at commit time. Don't batch changes; each logical change gets its own `/commit`.

## Skills

| Task | Invocation |
|------|------------|
| Commit | `/commit` |
