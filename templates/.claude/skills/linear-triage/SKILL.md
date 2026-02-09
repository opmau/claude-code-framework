---
name: linear-triage
description: Triage, prioritize, and groom Linear issues. Use when the user says "triage linear", "review inbox", "prioritize issues", "groom backlog", or "clean up issues".
argument-hint: "[team-key]"
user-invocable: true
allowed-tools: Bash, Read, Grep
model: sonnet
---

# /linear-triage — Triage and groom Linear issues

Review unassigned, unprioritized, or stale issues using [schpet/linear-cli](https://github.com/schpet/linear-cli). Combines inbox triage with backlog grooming in a single workflow.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Fetch issues that need attention. If `$ARGUMENTS` is provided, filter by team:
   ```bash
   linear issue list --team "$ARGUMENTS" -A --json
   ```
   Without arguments, fetch all unstarted issues across teams:
   ```bash
   linear issue list -A --json
   ```
   Note: `-A` lists all unstarted issues (not just yours).

3. Categorize issues into triage buckets:

   **Inbox (needs prioritization):**
   - No priority set
   - No assignee
   - Sitting in Triage state

   **Stale (needs attention):**
   - In Backlog/Triage for >30 days with no activity
   - Assigned but no status change in >14 days

   **Potential duplicates:**
   - Issues with similar titles or descriptions
   - Issues addressing the same area/module

4. For each issue needing triage, fetch details:
   ```bash
   linear issue view ENG-123 --json
   ```

5. Analyze and propose for each issue:
   - **Priority:** based on title, description, and labels
   - **Assignment:** suggest a team member if patterns are clear
   - **Labels:** suggest missing labels based on content analysis
   - **Closure:** recommend closing stale/superseded issues

6. Present the triage summary for user review:
   ```
   ## Linear Triage Report

   ### Needs Prioritization ([count] issues):

   | Issue | Title | Suggested Priority | Suggested Labels | Rationale |
   |-------|-------|--------------------|------------------|-----------|
   | ENG-123 | <title> | High (2) | bug | <why> |
   | ENG-124 | <title> | Low (4) | tech-debt | <why> |

   ### Stale Issues ([count] issues):
   - ENG-200: <title> — in Backlog since [date], no activity
   - ENG-201: <title> — assigned to [person], no update in 21 days

   ### Potential Duplicates:
   - ENG-300 ↔ ENG-301: both address [topic]

   ### Recommended Closures:
   - ENG-400: [reason — superseded by ENG-401, no longer relevant, etc.]

   ### Suggested Groupings:
   - "Auth improvements": ENG-500, ENG-501, ENG-502

   ### Actions:
   1. ENG-123: Set priority high, assign to [person]
   2. ENG-124: Set priority low, label as tech-debt
   3. ENG-400: Close as superseded

   Apply these suggestions? (all / select / none)
   ```

7. If the user approves (all or selected), apply changes:
   ```bash
   linear issue update ENG-123 --priority 2 --label "bug"
   linear issue update ENG-124 --priority 4 --label "tech-debt"
   ```

8. Report final results:
   ```
   Triage Complete:
   - Prioritized: [count]
   - Labeled: [count]
   - Closed: [count]
   - Skipped: [count]
   ```

## Arguments

- No arguments: triage all unstarted issues across teams
- `$ARGUMENTS`: filter by team key (e.g., `ENG`)

## Notes

- Always present suggestions before applying — never auto-prioritize without user review
- Priority suggestions are based on keywords and labels, not assumptions
- If an issue is ambiguous, flag it for manual review rather than guessing
- Group related issues together when presenting (e.g., multiple bugs in same area)
- Linear priority numbers: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low
- For deeper strategic analysis (velocity trends, capacity planning), use the `linear-pm` agent
