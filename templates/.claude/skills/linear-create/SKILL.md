---
name: linear-create
description: Create a new issue in Linear. Use when the user says "create linear issue", "file linear ticket", or "add to linear".
argument-hint: "<issue title>"
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep
model: sonnet
---

# /linear-create — Create a Linear issue

Create a new issue in Linear and optionally link it to a local ticket.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Gather issue details. If `$ARGUMENTS` is provided, use it as the title. Determine:
   - **Title:** short, descriptive (from arguments or ask)
   - **Team:** which Linear team (e.g., `ENG`, `DES`)
   - **Priority:** Urgent / High / Medium / Low / None
   - **Status:** Backlog, Todo, In Progress
   - **Labels:** comma-separated (e.g., `bug`, `feature`, `tech-debt`)
   - **Description:** what needs to be done and why
   - **Estimate:** story points if the team uses them

3. Show the proposed issue to the user for confirmation before creating:
   ```
   ## Proposed Linear Issue

   Title: <title>
   Team: <team>
   Priority: <priority>
   Labels: <labels>
   Description: <description>

   Create this issue? (yes/no)
   ```

4. Create the issue in Linear:
   ```bash
   linear issue create \
     --title "<title>" \
     --team "<team>" \
     --priority "<priority>" \
     --label "<labels>" \
     --description "<description>"
   ```

5. Capture the returned issue ID (e.g., `ENG-456`).

6. Ask the user if they want a corresponding local ticket. If yes:
   - Create a local ticket via the `/create-ticket` pattern
   - Include `Linear: ENG-456` in the ticket metadata

7. Report:
   ```
   Created: ENG-456 — <title>
   Priority: <priority>
   Status: <status>
   URL: <linear-issue-url>

   Local ticket: TICKET-NNN (linked) | none
   ```

## Arguments

- No arguments: prompt for all details interactively
- `$ARGUMENTS`: use as issue title, prompt for remaining details

## Notes

- Always confirm with the user before creating — creating issues is not reversible
- If creating from a bug fix or code change, include relevant file references in the description
- Default to the team configured in CLAUDE.md if available, otherwise ask
- Keep descriptions concise but include enough context for another developer
