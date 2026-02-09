---
name: fix-issue
description: Pick a bug from Linear, fix it, verify, and update. Use when the user says "fix issue", "fix bug", "work on known issue", or "pick a bug".
argument-hint: "<ENG-NNN or description>"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
model: sonnet
---

# /fix-issue — Fix a tracked Linear issue

Select a bug from Linear, fix it in a focused session, verify the fix, and update the issue status.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```

2. **Select the issue:**
   - If `$ARGUMENTS` specifies an issue ID (e.g., `ENG-123`), fetch that issue:
     ```bash
     linear issue view ENG-123 --json
     ```
   - If `$ARGUMENTS` is a description, search for matching bug issues:
     ```bash
     linear issue list --label "bug" --json
     ```
     Then match by title/description.
   - If no arguments, list all open bugs and ask the user to pick one:
     ```bash
     linear issue list --label "bug" --json
     ```

3. **Review the issue details:**
   - Read the symptom, evidence, suspected root cause from the Linear issue description
   - Verify the evidence is still valid (re-check logs, reproduce if possible)
   - If the issue lacks evidence, gather it before proceeding
   - Optionally check `docs/LINEAR_SNAPSHOT.md` for a quick local reference

4. **Plan the fix:**
   - List the files that need to change (must be within Change Size Limits for bug fixes: 1-3 files)
   - State the fix approach and what could go wrong
   - Get user confirmation before proceeding

5. **Implement the fix:**
   - Make the minimum changes needed
   - Follow the max 2 fix attempts rule — if the 2nd attempt fails, STOP and add a comment to the issue

6. **Verify the fix:**
   - Run the project build command
   - Run relevant tests from the test mapping table
   - If the original issue included specific reproduction steps, verify the symptom is gone

7. **Update the Linear issue:**
   ```bash
   linear issue update ENG-123 --state "Done"
   linear issue comment add ENG-123 -b "**Root Cause:** [actual root cause]

   **Fix Applied:**
   - [file:line] — [what changed]

   **Verification:**
   - Build: PASS
   - Tests: PASS

   **Commit:** [commit hash or 'ready to commit']"
   ```

8. **Report:**
   ```
   ## Fixed: ENG-123 — [description]

   ### Root Cause
   [actual root cause]

   ### Fix Applied
   - [file:line] — [what changed]

   ### Verification
   - Build: PASS/FAIL
   - Tests: PASS/FAIL
   - Reproduction: [verified symptom is gone / N/A]

   ### Files Changed
   - [file list]

   Ready to commit? Use /commit to create a conventional commit with [ENG-123] reference.
   ```

## Notes

- Only fix ONE issue per invocation — single-responsibility
- If the fix touches more than 3 files, stop and discuss scope with the user
- If you discover a new bug during the fix, use /document-bug to log it separately
- Never mark an issue as Done if tests fail
- Include the issue ID in the commit message: `fix(module): description [ENG-123]`
