# Linear Workflow Rules

## Tooling

This project uses [schpet/linear-cli](https://github.com/schpet/linear-cli) for Linear integration.

- **Install:** `brew install schpet/tap/linear` (macOS) or `deno install -A --reload -f -g -n linear jsr:@schpet/linear-cli`
- **Auth:** `linear auth login`
- **Config:** `linear config` (generates `.linear.toml` with team ID, workspace, etc.)
- **Help:** `linear --help`, `linear issue --help`, `linear issue list --help`

For operations not supported by the CLI (e.g., cycles), use the GraphQL API:
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $(linear auth token)" \
  -d '{"query": "{ viewer { id name } }"}'
```

## Issue-Driven Development

All non-trivial work should trace back to a Linear issue:

1. **Before starting work:** Check if a Linear issue exists for the task
2. **During work:** Reference the issue ID in commit messages (e.g., `feat(auth): add OAuth flow [ENG-123]`)
3. **After work:** Update the Linear issue status and link the PR via `linear issue pr`

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

## Priority Mapping

| Linear Priority | Number | Description |
|----------------|--------|-------------|
| None | 0 | No priority set |
| Urgent | 1 | Immediate attention required |
| High | 2 | Important, schedule soon |
| Medium | 3 | Normal priority |
| Low | 4 | Nice to have, backlog |

## Commit Message Convention

When working on a Linear issue, include the issue ID:

```
<type>(<scope>): <subject> [ENG-123]
```

This enables Linear's auto-linking to connect commits to issues.

## Key CLI Commands Reference

| Task | Command |
|------|---------|
| List my issues | `linear issue list` |
| List all unstarted | `linear issue list -A` |
| View issue details | `linear issue view ENG-123` |
| Start working on issue | `linear issue start ENG-123` |
| Create issue | `linear issue create -t "title" -d "desc" --team ENG` |
| Update issue | `linear issue update ENG-123 --state "Done" --priority 2` |
| Add comment | `linear issue comment add ENG-123 -b "comment text"` |
| Create PR from issue | `linear issue pr` |
| List team members | `linear team members` |
| List labels | `linear label list` |
| List projects | `linear project list` |
| Get auth token (for API) | `linear auth token` |
| Dump GraphQL schema | `linear schema -o schema.graphql` |

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
