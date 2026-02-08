---
name: linear-sprint
description: Manage Linear cycles and sprint planning. Use when the user says "sprint planning", "manage cycle", "linear sprint", or "plan cycle".
argument-hint: "[current|next|cycle-id]"
user-invocable: true
allowed-tools: Bash, Read, Write, Grep
model: sonnet
---

# /linear-sprint — Manage Linear cycles

View, plan, and report on Linear cycles (sprints).

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Determine which cycle to operate on:
   - `$ARGUMENTS` = `current` or empty → current active cycle
   - `$ARGUMENTS` = `next` → upcoming cycle
   - `$ARGUMENTS` = cycle ID → specific cycle

3. Fetch cycle details:
   ```bash
   linear cycle list --active --format json
   ```
   ```bash
   linear issue list --cycle active --format json
   ```

4. Analyze the cycle and generate a report:

   **For current cycle — progress report:**
   ```
   ## Cycle Report: [cycle name] ([start] → [end])

   ### Progress:
   - Total issues: [count]
   - Completed: [count] ([percent]%)
   - In Progress: [count]
   - Todo: [count]
   - Blocked: [count]

   ### By Priority:
   - Urgent: [done/total]
   - High: [done/total]
   - Medium: [done/total]
   - Low: [done/total]

   ### At Risk:
   - ENG-123: <title> — [reason: blocked, stale, overdue]
   - ENG-456: <title> — [reason]

   ### Velocity:
   - Points completed: [count]
   - Days remaining: [count]
   - Projected completion: [on-track / at-risk / behind]
   ```

   **For next cycle — planning view:**
   ```
   ## Planning: [next cycle name] ([start] → [end])

   ### Candidates (unscheduled high-priority):
   | Issue | Title | Priority | Estimate | Labels |
   |-------|-------|----------|----------|--------|
   | ENG-789 | <title> | High | 3pts | feature |

   ### Carryover (incomplete from current):
   | Issue | Title | Status | Remaining |
   |-------|-------|--------|-----------|
   | ENG-123 | <title> | In Progress | ~2pts |

   ### Capacity:
   - Team capacity: [estimated points]
   - Candidate total: [points]
   - Carryover total: [points]
   - Available: [remaining points]
   ```

5. If planning next cycle, ask the user which candidates to add:
   ```
   Add candidates to next cycle? (all / select by number / none)
   ```

6. Apply changes if approved:
   ```bash
   linear issue update ENG-789 --cycle "<next-cycle-id>"
   ```

7. Optionally update `docs/CURRENT_SPRINT.md` with the cycle report for local reference.

## Arguments

- No arguments or `current`: report on active cycle
- `next`: plan the upcoming cycle
- Cycle ID: operate on a specific cycle

## Notes

- Sprint reports are read-only by default — only modify cycle contents with user approval
- Velocity calculations are estimates — flag them as such
- Carryover issues should be highlighted, not automatically moved
- Always sync with local `CURRENT_SPRINT.md` when reporting
