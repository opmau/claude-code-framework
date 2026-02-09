---
name: linear-sprint
description: Manage Linear cycles and sprint planning. Use when the user says "sprint planning", "manage cycle", "linear sprint", or "plan cycle".
argument-hint: "[current|next]"
user-invocable: true
allowed-tools: Bash, Read, Write, Grep
model: sonnet
---

# /linear-sprint — Manage Linear cycles

View, plan, and report on Linear cycles (sprints) using [schpet/linear-cli](https://github.com/schpet/linear-cli).

**Note:** The Linear CLI does not have a dedicated `cycle` command. This skill uses the CLI for issue data and falls back to the Linear GraphQL API (via `curl` + `linear auth token`) for cycle-specific queries, as documented by the CLI itself.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Get the GraphQL schema to discover cycle fields if needed:
   ```bash
   linear schema -o "${TMPDIR:-/tmp}/linear-schema.graphql"
   grep -A 30 "^type Cycle " "${TMPDIR:-/tmp}/linear-schema.graphql"
   ```

3. Determine which cycle to operate on:
   - `$ARGUMENTS` = `current` or empty → current active cycle
   - `$ARGUMENTS` = `next` → upcoming cycle

4. Fetch cycle data via the GraphQL API:
   ```bash
   curl -s -X POST https://api.linear.app/graphql \
     -H "Content-Type: application/json" \
     -H "Authorization: $(linear auth token)" \
     -d '{"query": "{ team(id: \"TEAM_ID\") { activeCycle { id name startsAt endsAt issues { nodes { identifier title state { name } priority assignee { name } } } } } }"}'
   ```
   Get the team ID first: `linear team id`

5. Fetch issue details for the cycle using the CLI for richer data:
   ```bash
   linear issue view ENG-123 --json
   ```

6. Generate the appropriate report:

   **For current cycle — progress report:**
   ```
   ## Cycle Report: [cycle name] ([start] → [end])

   ### Progress:
   - Total issues: [count]
   - Completed: [count] ([percent]%)
   - In Progress: [count]
   - Todo: [count]

   ### By Priority:
   - Urgent: [done/total]
   - High: [done/total]
   - Medium: [done/total]
   - Low: [done/total]

   ### At Risk:
   - ENG-123: <title> — [reason: stale, no assignee, etc.]

   ### Days remaining: [count]
   ```

   **For next cycle — planning view:**
   ```
   ## Planning: [next cycle name] ([start] → [end])

   ### Candidates (unscheduled high-priority):
   | Issue | Title | Priority | Labels |
   |-------|-------|----------|--------|
   | ENG-789 | <title> | High | feature |

   ### Carryover (incomplete from current):
   | Issue | Title | Status |
   |-------|-------|--------|
   | ENG-123 | <title> | In Progress |
   ```

7. Optionally update `docs/CURRENT_SPRINT.md` with the cycle report for local reference.

## Arguments

- No arguments or `current`: report on active cycle
- `next`: plan the upcoming cycle

## Notes

- Sprint reports are read-only by default — only modify cycle contents with user approval
- Velocity calculations are estimates — flag them as such
- Carryover issues should be highlighted, not automatically moved
- The GraphQL API is used because `linear-cli` doesn't have a cycle command — prefer CLI commands for everything else
- Get your auth token for API calls via: `linear auth token`
