# Claude Code User Preferences

Personal preferences and instructions for all projects. **Note**: Project-specific preferences in local CLAUDE.md files take precedence over these settings.

## Code Style

### Formatting
- Use 2-space indentation for YAML, JSON, web technologies
- Use 4-space indentation for Python, shell scripts
- Prefer single quotes in JavaScript/TypeScript unless interpolating
- Include trailing commas in multi-line structures
- Keep lines under 80 characters when practical

### Git Commits
- Use Conventional Commits format (feat:, fix:, chore:, docs:)
- Keep first line under 72 characters
- Use present tense ("add feature" not "added feature")
- Be descriptive but concise

## Tools & Testing

### Package Management
- Use `mise` to install missing tools

### Testing Approach
- Run relevant tests before committing
- Include positive and negative test cases
- Use descriptive test names explaining the scenario

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
