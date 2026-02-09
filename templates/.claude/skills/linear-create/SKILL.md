---
name: linear-create
description: Create a new issue in Linear. Use when the user says "create linear issue", "file linear ticket", or "add to linear".
argument-hint: "<issue title>"
user-invocable: true
allowed-tools: Bash, Read, Write, Glob, Grep
model: sonnet
---

# /linear-create — Create a Linear issue

Create a new issue in Linear using [schpet/linear-cli](https://github.com/schpet/linear-cli).

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. Gather issue details. If `$ARGUMENTS` is provided, use it as the title. Determine:
   - **Title:** short, descriptive (from arguments or ask)
   - **Team:** which Linear team key (e.g., `ENG`) — check `.linear.toml` for default
   - **Priority:** 1 (Urgent) / 2 (High) / 3 (Medium) / 4 (Low) / 0 (None)
   - **Labels:** label names (e.g., `bug`, `feature`)
   - **Description:** what needs to be done and why

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
     -t "<title>" \
     -d "<description>" \
     --team "<team-key>" \
     --priority <priority-number> \
     --label "<label>" \
     --no-interactive
   ```
   For multiple labels, repeat the flag: `--label "bug" --label "high-priority"`

5. Capture the returned issue ID (e.g., `ENG-456`).

6. Get the issue URL for reference:
   ```bash
   linear issue url ENG-456
   ```

7. Report:
   ```
   Created: ENG-456 — <title>
   Priority: <priority>
   URL: <linear-issue-url>

   Run /linear-sync to update the local snapshot.
   ```

## Arguments

- No arguments: prompt for all details interactively
- `$ARGUMENTS`: use as issue title, prompt for remaining details

## Notes

- Always confirm with the user before creating — creating issues is not reversible via the CLI
- If creating from a bug fix or code change, include relevant file references in the description
- Default to the team configured in `.linear.toml` if available, otherwise ask
- Keep descriptions concise but include enough context for another developer
- Use `linear issue create --help` to discover additional flags
