---
name: create-ticket
description: Create a new ticket for task tracking. Use when the user says "create ticket", "new ticket", or "track this".
argument-hint: "<ticket title>"
user-invocable: true
allowed-tools: Read, Write, Glob, Grep
model: haiku
---

# /create-ticket — Create a tracked ticket

Create a new ticket in the project's ticket system.

## Steps

1. Determine the next ticket number:
   - Read `.claude/tickets/ticket-list.md`
   - Find the highest existing TICKET-NNN number
   - Increment by 1

2. Gather ticket details. If `$ARGUMENTS` is provided, use it as the title. Then determine:
   - **Title:** short, descriptive (from arguments or ask the user)
   - **Priority:** High / Medium / Low
   - **Description:** what needs to be done and why
   - **Acceptance criteria:** specific, verifiable conditions

3. Read the ticket template:
   ```
   .claude/tickets/TICKET-000-template.md
   ```

4. Create the ticket file at:
   ```
   .claude/tickets/TICKET-NNN-kebab-case-title.md
   ```

5. Update `.claude/tickets/ticket-list.md`:
   - Add the new ticket to the appropriate priority section
   - Status: 🔴 Todo

6. Report:
   ```
   Created: .claude/tickets/TICKET-NNN-<title>.md
   Priority: <priority>
   Status: 🔴 Todo

   Acceptance Criteria:
   - [ ] <criterion 1>
   - [ ] <criterion 2>
   ```

## Notes

- Use today's date for the Created field
- Keep titles under 60 characters
- Acceptance criteria must be objectively verifiable — not vague ("works well")
- Always update ticket-list.md when creating a ticket
