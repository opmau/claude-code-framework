---
name: linear-update
description: Update a Linear issue's status, assignee, or labels. Use when the user says "update linear", "move issue", "close linear issue", or "assign issue".
argument-hint: "<issue-id> [field=value ...]"
user-invocable: true
allowed-tools: Bash, Read, Write, Grep, Glob
model: haiku
---

# /linear-update — Update a Linear issue

Push updates to a Linear issue using [schpet/linear-cli](https://github.com/schpet/linear-cli) and sync the local ticket if one exists.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Parse `$ARGUMENTS` for the issue ID and field updates:
   - First token: issue ID (e.g., `ENG-123`)
   - Remaining tokens: field=value pairs (e.g., `status=done priority=high`)

   If no arguments, ask the user for the issue ID and what to update.

3. Fetch the current issue state:
   ```bash
   linear issue view ENG-123 --json
   ```

4. Show the proposed changes for confirmation:
   ```
   ## Update: ENG-123 — <title>

   | Field | Current | New |
   |-------|---------|-----|
   | Status | In Progress | Done |
   | Priority | Medium (3) | High (2) |

   Apply these changes?
   ```

5. Apply the update using `linear issue update` with the appropriate flags:
   ```bash
   linear issue update ENG-123 --state "Done" --priority 2
   ```

   Available flags (use `linear issue update --help` for full list):
   - `--state "<state-name>"` — set workflow state (e.g., "Todo", "In Progress", "Done")
   - `--priority <number>` — set priority (0=None, 1=Urgent, 2=High, 3=Medium, 4=Low)
   - `--assignee "<username-or-email>"` — assign to user (use `@me` for self)
   - `--label "<label-name>"` — add label (repeat flag for multiple)
   - `-t "<title>"` — update title
   - `-d "<description>"` — update description

6. If a linked local ticket exists (search for `Linear: ENG-123` in `.claude/tickets/`):
   - Update the local ticket status to match
   - Map Linear status → local status: Todo→🔴, In Progress→🟡, Done→🟢, Cancelled→⚫

7. Report:
   ```
   Updated: ENG-123 — <title>
   Changes: state → Done, priority → High
   Local ticket: TICKET-NNN synced | no local ticket
   ```

## Arguments

- `$ARGUMENTS` format: `<issue-id> [state=<state>] [priority=<priority>] [assignee=<name>]`
- Examples:
  - `ENG-123 state=done` — mark as done
  - `ENG-123 priority=urgent assignee=@me` — set priority and self-assign
  - `ENG-123 label=bug label=regression` — add labels

## Notes

- Always show current vs proposed state and confirm before applying
- When marking an issue as Done, ask if a comment should be added (e.g., linking to the PR):
  `linear issue comment add ENG-123 -b "Fixed in PR #42"`
- Keep local tickets in sync — search `.claude/tickets/` for the Linear ID
- If the issue doesn't exist in Linear, report the error clearly
