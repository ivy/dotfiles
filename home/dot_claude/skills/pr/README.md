# `/pr` — Open a Pull Request

Push the branch, create the PR, and report the URL. Stamps the session ID into the body so the conversation that produced the code stays traceable.

```
/pr
/pr fixes a race condition in the session handler
```

## Why this exists

The PR is the final artifact of the [`/work-on`](../work-on/README.md) workflow — the deliverable that gets reviewed, approved, and merged. But it's more than a code delivery mechanism: it's the permanent record of why a change was made.

Code tells you *what* changed. Commit messages tell you *why* each piece changed. The PR description tells you the *overall intent* — what problem was being solved, what approach was chosen, and what alternatives were considered and rejected.

This repo follows the "Source Truth" principle: truth lives with the artifact. The PR body carries a `<!-- claude-session: ... -->` marker, so the session that produced the code is identified on the artifact itself and the full transcript stays reachable via `cq -s <id>` — a pointer to the primary source rather than a copy of it.

## No browser step

The PR is created non-interactively with `gh pr create`, and the skill reports the URL.

The bundled `gh-pr-create-web` shim is not invoked by this skill. It survives as the worked example that [`write-skill/SHIM-PATTERN.md`](../write-skill/SHIM-PATTERN.md) and [`write-skill/REVIEW.md`](../write-skill/REVIEW.md) cite.

## In the [`/work-on`](../work-on/README.md) workflow

[`/pr`](../pr/README.md) is the last step before the workflow closes out. By the time it runs:

- The branch has been committed incrementally via [`/commit`](../commit/README.md)
- `/simplify` has run a code quality pass
- The implementation reflects the approved plan

The PR description is generated from the commit history, the original issue, and the session context — so it describes the actual implementation, not just what was intended.
