---
name: fix-issue
description: Pick a bug from KNOWN_ISSUES.md, fix it, verify, and commit. Use when the user says "fix issue", "fix bug", "work on known issue", or "pick a bug".
argument-hint: "<BUG-NNN or description>"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
model: sonnet
---

# /fix-issue — Fix a tracked known issue

Select a bug from KNOWN_ISSUES.md, fix it in a focused session, verify the fix, and update documentation.

## Steps

1. **Select the issue:**
   - If `$ARGUMENTS` specifies a BUG-NNN, find that entry in `docs/KNOWN_ISSUES.md`
   - If `$ARGUMENTS` is a description, search for matching entries
   - If no arguments, list all Open issues and ask the user to pick one

2. **Review the issue entry:**
   - Read the symptom, evidence, suspected root cause, and suggested fix approach
   - Verify the evidence is still valid (re-check logs, reproduce if possible)
   - If the entry lacks evidence, gather it before proceeding

3. **Plan the fix:**
   - List the files that need to change (must be within Change Size Limits for bug fixes: 1-3 files)
   - State the fix approach and what could go wrong
   - Get user confirmation before proceeding

4. **Implement the fix:**
   - Make the minimum changes needed
   - Follow the max 2 fix attempts rule — if the 2nd attempt fails, STOP and update the issue

5. **Verify the fix:**
   - Run the project build command
   - Run relevant tests from the test mapping table
   - If the original issue included specific reproduction steps, verify the symptom is gone

6. **Update documentation:**
   - Update the issue in `docs/KNOWN_ISSUES.md`:
     - Change Status to `FIXED`
     - Add the actual root cause (may differ from suspected)
     - Add the fix details with file:line references
     - Strikethrough the entry title: `### ~~[BUG-NNN] — [description]~~`
   - Update `docs/CURRENT_SPRINT.md` if the fix is part of active work

7. **Report:**
   ```
   ## Fixed: BUG-NNN — [description]

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

   Ready to commit? Use /commit to create a conventional commit.
   ```

## Notes

- Only fix ONE issue per invocation — single-responsibility
- If the fix touches more than 3 files, stop and discuss scope with the user
- If you discover a new bug during the fix, use /document-bug to log it separately
- Never mark an issue as FIXED if tests fail
