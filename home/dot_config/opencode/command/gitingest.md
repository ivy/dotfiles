---
description: Fetch and contextualize a GitHub repository using gitingest
---

Use gitingest to fetch and contextualize a GitHub repository for future reference.

## User Input

```
$ARGUMENTS
```

## Parsing User Input

Handle the user input in this order:
1. **Full URL**: If it's a complete GitHub URL, use directly
2. **user/repo format**: If it contains a slash, construct `https://github.com/$ARGUMENTS`
3. **Single name**: If it's just a repository name (like "rails"), try to identify the canonical/most popular repository:
   - For well-known projects, use the official repository (e.g., "rails" -> "rails/rails")
   - If ambiguous, ask the user to clarify which repository they want

The user may also include filtering instructions in natural language (e.g., "only Python files", "exclude tests"). Parse these and apply the appropriate options below.

## Available Options

Build the gitingest command using these options as needed:

- `-o, --output PATH` - Output file path (required, use `docs/reference/<user>-<repo>.txt`)
- `-i, --include-pattern PATTERN` - Shell-style patterns to include (e.g., `"*.py"`, `"*.js"`)
- `-e, --exclude-pattern PATTERN` - Shell-style patterns to exclude (e.g., `"*.log"`, `"node_modules/*"`)
- `-b, --branch NAME` - Specific branch to clone and ingest
- `-s, --max-size BYTES` - Maximum file size to process (default: 10485760)
- `--include-gitignored` - Include files matched by .gitignore
- `--include-submodules` - Include repository's submodules
- `-t, --token TOKEN` - GitHub PAT for private repos (or set GITHUB_TOKEN env var)

Multiple patterns can be specified by repeating the flag: `-i "*.py" -i "*.md"`

## Steps

1. Run `mkdir -p docs/reference/` to ensure the output directory exists
2. Run `gitingest [OPTIONS] -o docs/reference/<user>-<repo_name>.txt <repo_url>`
3. Read the generated documentation file to understand the repository
4. Provide a brief confirmation of what was fetched (repository name, main purpose, file location, and any filters applied)

## Examples

- Basic: `gitingest -o docs/reference/rails-rails.txt https://github.com/rails/rails`
- Python only: `gitingest -i "*.py" -o docs/reference/user-repo.txt https://github.com/user/repo`
- Exclude tests: `gitingest -e "test/*" -e "*_test.py" -o docs/reference/user-repo.txt https://github.com/user/repo`
- Specific branch: `gitingest -b develop -o docs/reference/user-repo.txt https://github.com/user/repo`

The generated file will be available for future prompts and questions about the repository.
