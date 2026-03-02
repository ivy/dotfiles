---
name: label-ticket
description: Use when labeling GitHub issues or triaging the backlog. Applies the project's label taxonomy from docs/labels.md.
argument-hint: "[#123 | #123 #456 | all | unlabeled]"
model: haiku
allowed-tools:
  - Read
  - Bash(gh issue list:*)
  - Bash(gh issue view:*)
  - Bash(gh issue edit:*)
  - Bash(gh label list:*)
---

# Label Ticket

Apply labels to GitHub issues per the taxonomy in [docs/labels.md](docs/labels.md).

## Arguments

```
local /label-ticket
```

## Label Reference

Read `docs/labels.md` for the full taxonomy. Quick summary:

| Group | Labels |
|-------|--------|
| Priority (pick one) | `p0:now`, `p1:soon`, `p2:later`, `p3:someday` |
| Readiness (pick one) | `for:agent`, `for:human` |
| Area (pick one) | `area:claude`, `area:tmux`, `area:nvim`, `area:shell`, `area:git`, `area:mise`, `area:renovate`, `area:os` |
| Type (optional) | `type:feature`, `type:bug`, `type:chore`, `type:workflow`, `type:security`, `type:test` |
| Status (optional) | `blocked` |

## Instructions

### 1. Determine scope

Parse arguments to decide what to label:

- **Issue numbers** (`#123`, `#456`) — label those specific issues
- **`all`** — triage all open issues
- **`unlabeled`** — find and triage open issues missing labels
- **No arguments** — default to `unlabeled`

### 2. Fetch issues

```bash
# Specific issues
gh issue view 123 --json number,title,body,labels

# All open
gh issue list --state open --json number,title,labels --limit 200

# Unlabeled (filter client-side)
gh issue list --state open --json number,title,body,labels --limit 200
# then filter to issues missing priority OR readiness OR area labels
```

### 3. Analyze each issue

For each issue, determine:

1. **Priority** — Is it blocking (`p0:now`)? Wanted soon (`p1:soon`)? Backlog (`p2:later`)? Wishlist (`p3:someday`)?
2. **Readiness** — Is the issue fully specified enough for an agent to execute autonomously (`for:agent`)? Or does it need human judgment, hardware access, or interactive work (`for:human`)?
3. **Area** — What part of the stack does it touch? Match against area labels. Use the issue title prefix as a strong hint (e.g., `claude(statusline):` → `area:claude`, `tmux:` → `area:tmux`).
4. **Type** — If not obvious from context, assign one. Feature requests → `type:feature`, broken things → `type:bug`, etc.

### 4. Present recommendations

For each issue, show the proposed labels in a table:

```
| # | Title | Priority | Readiness | Area | Type |
```

When labeling **specific issues** (1-3), apply immediately after showing the table.

When labeling **all** or **unlabeled**, present the full table first and wait for user confirmation before applying.

### 5. Apply labels

```bash
gh issue edit 123 --add-label "p2:later" --add-label "for:agent" --add-label "area:claude" --add-label "type:feature"
```

Do NOT remove existing valid labels. Only add missing ones.

### 6. Summary

Report what was labeled:
- Count of issues labeled
- Any issues skipped (already fully labeled, or couldn't determine labels)

## Examples

```
/label-ticket #203                → label one issue
/label-ticket #199 #200 #201     → label specific issues
/label-ticket unlabeled           → find and triage unlabeled issues
/label-ticket all                 → review and label all open issues
/label-ticket                     → same as unlabeled
```
