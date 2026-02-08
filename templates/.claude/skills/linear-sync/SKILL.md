---
name: linear-sync
description: Sync Linear issues with local ticket system. Use when the user says "sync linear", "pull linear issues", or "update from linear".
argument-hint: "[team-key or project-slug]"
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep
model: sonnet
---

# /linear-sync — Sync Linear issues to local tickets

Pull issues from Linear and sync them with the local `.claude/tickets/` system.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```
   If missing, tell the user to install it: `npm install -g @linear/cli` and authenticate with `linear auth`.

2. Fetch issues from Linear. If `$ARGUMENTS` is provided, use it as the team key or project filter:
   ```bash
   linear issue list --team "$ARGUMENTS" --status "Todo,In Progress,Blocked" --format json
   ```
   Without arguments, fetch all assigned-to-me issues:
   ```bash
   linear issue list --mine --status "Todo,In Progress,Blocked" --format json
   ```

3. Read the current local ticket index:
   ```
   .claude/tickets/ticket-list.md
   ```

4. For each Linear issue, determine sync action:
   - **New:** Issue exists in Linear but not locally → create local ticket
   - **Updated:** Issue exists in both but Linear status differs → update local ticket status
   - **Unchanged:** Already in sync → skip

5. For new issues, create local tickets following the `/create-ticket` format:
   - Map Linear priority (Urgent/High/Medium/Low/None) to local priority
   - Map Linear status to local status: Todo→🔴, In Progress→🟡, Done→🟢, Cancelled→⚫
   - Include the Linear issue ID (e.g., `ENG-123`) in the ticket metadata
   - Add a `Linear: ENG-123` field in the ticket header

6. Update `.claude/tickets/ticket-list.md` with any new or changed tickets.

7. Report sync results:
   ```
   ## Linear Sync Results

   Source: [team/project or "my issues"]

   ### Created (Linear → Local):
   - TICKET-NNN (ENG-123): <title>

   ### Updated:
   - TICKET-NNN (ENG-456): status 🔴→🟡

   ### Already in sync: [count]

   Total local tickets: [count]
   ```

## Arguments

- No arguments: sync all issues assigned to the current user
- `$ARGUMENTS`: filter by team key (e.g., `ENG`) or project slug

## Notes

- Never overwrite local ticket notes or acceptance criteria — only sync status and metadata
- If a local ticket has changes not in Linear, flag it as a conflict rather than overwriting
- The Linear issue ID is the source of truth for linking — stored in ticket metadata
- Sync is pull-only by default — use `/linear-update` to push changes back to Linear
