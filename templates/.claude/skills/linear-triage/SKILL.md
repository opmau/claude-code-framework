---
name: linear-triage
description: Triage and prioritize Linear inbox issues. Use when the user says "triage linear", "review inbox", or "prioritize issues".
argument-hint: "[team-key]"
user-invocable: true
allowed-tools: Bash, Read, Grep
model: sonnet
---

# /linear-triage — Triage Linear inbox

Review unassigned or unprioritized issues and help triage them.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Fetch untriaged issues. If `$ARGUMENTS` is provided, filter by team:
   ```bash
   linear issue list --team "$ARGUMENTS" --status "Triage,Backlog" --no-assignee --format json
   ```
   Without arguments:
   ```bash
   linear issue list --status "Triage,Backlog" --no-assignee --format json
   ```

3. Also fetch recently created issues that may need review:
   ```bash
   linear issue list --created-after "7d" --status "Triage" --format json
   ```

4. For each issue, analyze and propose:
   - **Priority:** based on title, description, and labels
   - **Assignment:** suggest a team member if patterns are clear (e.g., frontend issues → frontend team)
   - **Labels:** suggest missing labels based on content analysis
   - **Cycle:** suggest current or next cycle placement

5. Present the triage summary for user review:
   ```
   ## Linear Triage Report

   ### Needs Prioritization ([count] issues):

   | Issue | Title | Suggested Priority | Suggested Labels | Rationale |
   |-------|-------|--------------------|------------------|-----------|
   | ENG-123 | <title> | High | bug, api | <why> |
   | ENG-124 | <title> | Low | tech-debt | <why> |

   ### Suggested Actions:
   1. ENG-123: Assign to [team/person], add to current cycle
   2. ENG-124: Move to backlog, label as tech-debt

   Apply these suggestions? (all / select / none)
   ```

6. If the user approves (all or selected), apply the changes:
   ```bash
   linear issue update ENG-123 --priority high --label "bug,api"
   ```

7. Report final results:
   ```
   Triage Complete:
   - Prioritized: [count]
   - Labeled: [count]
   - Assigned: [count]
   - Skipped: [count]
   ```

## Arguments

- No arguments: triage all untriaged issues across teams
- `$ARGUMENTS`: filter by team key (e.g., `ENG`)

## Notes

- Always present suggestions before applying — never auto-prioritize without user review
- Priority suggestions are based on keywords and labels, not assumptions
- If an issue is ambiguous, flag it for manual review rather than guessing
- Group related issues together when presenting (e.g., multiple bugs in same area)
