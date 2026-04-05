# `/work-on [github issue]`

Triggers a workflow that runs a series of skills to rapidly iterate on and ship code:
- Fetches the referenced ticket, comments, linked/related tickets, reference, etc. to build high-level understanding of the scope and complexity of the task
- Plans (but doesn't use EnterPlanMode) at a high-level how to approach the issue based on the complexity of the ticket to identify what aspects of the workflow should be followed and what should be skipped
- Creates a task list to keep track of the order, sequencing, and dependencies of each stage of the workflow

## Phase 1. Research & Gather Requirements

### 1. `/checkout`

Creates a feature branch, ensuring that:
- New branch is based off of up-to-date origin's default branch (unless the user specifies otherwise)

### 2. `/gather-context`

Builds understanding about the problem, domain, codebase, and history. Adhere's to principle of Chesterton's Fence:

- Fetches the referenced ticket, comments, linked/related tickets, references, etc.
- Explores codebase, history, and prior work in parallel using Explore agents to answer remaining questions

### 3. `/think`

Activates "thought partner" approach to assess the problem space, evaluate solutions/tradeoffs, make recommendations that follow the project's vision and principles, and supports high-level discussion with the user until there's clear agreement about the high-level details.

## Phase 2. Devise a Plan

### 4. `/plan`

Creates an implementation plan:
- Focuses on parallelization using agent teams by identifying sequencing and dependencies

### 5. `/review-plan`

Reviews the plan with a subagent to identify gaps/ambiguity and cross-references with library documentation to check for errors.

### 6. `/share-plan`

Pushes details, decisions, and other context into the ticket to share with the team and preserve history for future engineers.

## Phase 3. Act

### 7. Execute

Performs the task based on the plan.

## Phase 4. Review

### 8. `/simplify [focus]`

Built in to Claude Code:

> Review your recently changed files for code reuse, quality, and efficiency issues, then fix them. Spawns three review agents in parallel, aggregates their findings, and applies fixes. Pass text to focus on specific concerns: `/simplify` focus on memory efficiency

### 9. `/pr`

Pushes and opens a pull request.

### 10. `/reflect`

Enables a self-improving feedback loop:
- Spawns agent(s) to review the session and identify:
  - Gaps in tooling, skills, instructions
  - What went well / what didn't
  - Proposes:
    - Memories and docs to create/update
    - Skills to create or improve
    - Improvements to make to the codebase and tooling based on identified points of friction (tech debt, DX gaps, etc.)
    - etc.
- Discusses with user, then creates/updates GitHub issues on ivy/dotfiles
  - Tracks recurring needs in comments to provide context and assist with prioritization of recurring issues
