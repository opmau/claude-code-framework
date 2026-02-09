---
name: linear-triage
description: Triage and prioritize Linear inbox issues. Use when the user says "triage linear", "review inbox", or "prioritize issues".
argument-hint: "[team-key]"
user-invocable: true
allowed-tools: Bash, Read, Grep
model: sonnet
---

# /linear-triage — Triage Linear inbox

Review unassigned or unprioritized issues using [schpet/linear-cli](https://github.com/schpet/linear-cli) and help triage them.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Fetch issues that need triage. If `$ARGUMENTS` is provided, filter by team:
   ```bash
   linear issue list --team "$ARGUMENTS" -A --json
   ```
   Without arguments, fetch all unstarted issues across teams:
   ```bash
   linear issue list -A --json
   ```
   Note: `-A` lists all unstarted issues (not just yours).

3. Identify issues needing attention:
   - No priority set
   - No assignee
   - Sitting in Triage/Backlog state

4. For each issue needing triage, fetch details:
   ```bash
   linear issue view ENG-123 --json
   ```

5. Analyze and propose for each issue:
   - **Priority:** based on title, description, and labels
   - **Assignment:** suggest a team member if patterns are clear
   - **Labels:** suggest missing labels based on content analysis

6. Present the triage summary for user review:
   ```
   ## Linear Triage Report

   ### Needs Prioritization ([count] issues):

   | Issue | Title | Suggested Priority | Suggested Labels | Rationale |
   |-------|-------|--------------------|------------------|-----------|
   | ENG-123 | <title> | High (2) | bug | <why> |
   | ENG-124 | <title> | Low (4) | tech-debt | <why> |

   ### Suggested Actions:
   1. ENG-123: Set priority high, assign to [person]
   2. ENG-124: Set priority low, label as tech-debt

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
