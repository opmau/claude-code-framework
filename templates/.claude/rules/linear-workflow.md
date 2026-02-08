# Linear Workflow Rules

## Issue-Driven Development

All non-trivial work should trace back to a Linear issue:

1. **Before starting work:** Check if a Linear issue exists for the task
2. **During work:** Reference the issue ID in commit messages (e.g., `feat(auth): add OAuth flow [ENG-123]`)
3. **After work:** Update the Linear issue status and link the PR

## Linear ↔ Local Ticket Sync

- Linear is the **source of truth** for issue metadata (priority, status, assignee)
- Local tickets (`.claude/tickets/`) are the **source of truth** for implementation notes and acceptance criteria
- The `Linear: ENG-XXX` field in local tickets links the two systems
- Sync conflicts should be flagged, not silently resolved

## Status Mapping

| Linear Status | Local Status | Meaning |
|---------------|-------------|---------|
| Triage | 🔴 Todo | Needs review and prioritization |
| Backlog | 🔴 Todo | Accepted but not scheduled |
| Todo | 🔴 Todo | Scheduled for current/next cycle |
| In Progress | 🟡 In Progress | Actively being worked on |
| In Review | 🟡 In Progress | Code complete, awaiting review |
| Done | 🟢 Done | Completed and verified |
| Cancelled | ⚫ Cancelled | No longer needed |

## Commit Message Convention

When working on a Linear issue, include the issue ID:

```
<type>(<scope>): <subject> [ENG-123]
```

This enables Linear's auto-linking to connect commits to issues.

## Cycle Discipline

- Issues should not be added mid-cycle without explicit approval
- Carryover issues from previous cycles should be re-evaluated, not blindly moved
- Scope changes mid-cycle should be flagged by the `linear-pm` agent

## When to Use Each Linear Skill

| Situation | Skill |
|-----------|-------|
| Pull issues from Linear into local tickets | `/linear-sync` |
| Create a new issue in Linear | `/linear-create` |
| Review and prioritize untriaged issues | `/linear-triage` |
| View cycle progress or plan next sprint | `/linear-sprint` |
| Update an issue's status, priority, or assignee | `/linear-update` |
| Strategic planning, backlog grooming, health checks | `linear-pm` agent |
