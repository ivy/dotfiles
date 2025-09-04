Use gitingest to fetch and contextualize a GitHub repository for future reference based on $ARGUMENTS. 

Handle $ARGUMENTS in this order:
1. **Full URL**: If it's a complete GitHub URL, use directly
2. **user/repo format**: If it contains a slash, construct `https://github.com/$ARGUMENTS`
3. **Single name**: If it's just a repository name (like "rails"), try to identify the canonical/most popular repository:
   - For well-known projects, use the official repository (e.g., "rails" → "rails/rails")
   - If ambiguous, ask the user to clarify which repository they want

Steps:
1. Run `gitingest -o docs/reference/<user>-<repo_name>.txt <repo_url>` to fetch the complete codebase
2. Read the generated documentation file to understand the repository
3. Provide a brief confirmation of what was fetched (repository name, main purpose, and file location)

The generated file will be available for future prompts and questions about the repository. You can reference specific parts of the codebase or ask implementation questions based on the fetched content.
