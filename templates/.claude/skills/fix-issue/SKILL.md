---
name: fix-issue
description: Pick a bug from Linear, fix it test-first, verify, and update. Use when the user says "fix issue", "fix bug", "work on known issue", or "pick a bug".
argument-hint: "<ENG-NNN or description>"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
model: opus
---

# /fix-issue — Fix a tracked Linear issue (test-driven)

Select a bug from Linear, write a failing test that reproduces it, fix it, and update the issue.

This skill follows a **test-driven** approach: RED → GREEN → REFACTOR.

> **Automated enforcement:** If [tdd-guard](https://github.com/nizos/tdd-guard) is installed, the TDD cycle is enforced automatically via hooks — implementation code is blocked unless corresponding failing tests exist. Toggle mid-session with `tdd-guard on` / `tdd-guard off`.

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
     linear issue list --label "bug"
     ```
     Then match by title/description.
   - If no arguments, list all open bugs and ask the user to pick one:
     ```bash
     linear issue list --label "bug"
     ```

3. **Review the issue details:**
   - Read the symptom, evidence, suspected root cause from the Linear issue description
   - Verify the evidence is still valid (re-check logs, reproduce if possible)
   - If the issue lacks evidence, gather it before proceeding
   - Optionally check `docs/LINEAR_SNAPSHOT.md` for a quick local reference

4. **Plan the fix:**
   - List the files that need to change (must be within Change Size Limits for bug fixes: 1-3 files)
   - Identify the test file where the regression test will go (existing test file or new one)
   - State the fix approach and what could go wrong
   - Get user confirmation before proceeding

### RED — Write a failing test

5. **Write a test that reproduces the bug:**
   - Write a test that captures the broken behavior described in the issue
   - The test should assert the **expected correct behavior** (so it fails against the current buggy code)
   - Place the test in the appropriate test file following the project's existing test conventions
   - Name the test descriptively: `test_<what_should_happen>` or `it("should <expected behavior>")`
   - Run the test and **confirm it fails**:
     ```bash
     # Run only the new test to confirm RED
     <project test command> --filter "<test name>"
     ```
   - If the test **passes** (meaning the bug can't be reproduced), STOP:
     - Add a comment to the Linear issue explaining the bug could not be reproduced
     - Ask the user how to proceed
   - If the test **fails for the wrong reason** (syntax error, import issue, etc.), fix the test itself — the test must fail because of the bug, not because of a test error

### GREEN — Write the minimum fix

6. **Implement the fix:**
   - Make the **minimum changes** needed to make the failing test pass
   - Do NOT add code beyond what the test requires
   - Follow the max 2 fix attempts rule — if the 2nd attempt fails, STOP and add a comment to the issue
   - Run the new test and **confirm it passes**:
     ```bash
     # Run only the new test to confirm GREEN
     <project test command> --filter "<test name>"
     ```

### REFACTOR — Clean up with confidence

7. **Refactor (if needed):**
   - Now that tests pass, clean up the implementation (remove duplication, improve naming, etc.)
   - Run the **full test suite** after any refactoring to ensure nothing else broke:
     ```bash
     <project test command>
     ```
   - Run the project build command to confirm it compiles/builds cleanly

### Update and report

8. **Update the Linear issue to "In Review":**
   ```bash
   linear issue update ENG-123 --state "In Review"
   linear issue comment add ENG-123 -b "**Root Cause:** [actual root cause]

   **Regression Test:** [test file:test name] — asserts [what the test checks]

   **Fix Applied:**
   - [file:line] — [what changed]

   **Automated Checks:**
   - New test: PASS (was RED before fix)
   - Full test suite: PASS
   - Build: PASS

   **Awaiting:** Manual verification by the user before marking Done.

   **Commit:** [commit hash or 'ready to commit']"
   ```

   > **Important:** "In Review" means the code change is ready for the user to manually test and verify.
   > Only the user moves an issue to "Done" — never mark it "Done" yourself.

9. **Report:**
   ```
   ## Fixed: ENG-123 — [description]

   ### Root Cause
   [actual root cause]

   ### Regression Test
   - File: [test file path]
   - Test: [test name]
   - Asserts: [what the test verifies — the correct behavior]

   ### Fix Applied
   - [file:line] — [what changed]

   ### TDD Cycle
   - RED: New test failed against buggy code (confirmed bug reproduced)
   - GREEN: Minimum fix applied, new test passes
   - REFACTOR: [any cleanup done, or "N/A — no refactoring needed"]

   ### Automated Checks
   - New test: PASS
   - Full suite: PASS/FAIL
   - Build: PASS/FAIL

   ### Manual Verification
   - Status: **Awaiting user testing**
   - How to verify: [describe how the user can confirm the symptom is gone]

   ### Files Changed
   - [file list]

   Ready to commit? Use /commit to create a conventional commit with [ENG-123] reference.
   ```

## Notes

- Only fix ONE issue per invocation — single-responsibility
- If the fix touches more than 3 files, stop and discuss scope with the user
- If you discover a new bug during the fix, use /document-bug to log it separately
- **Always write the test BEFORE writing the fix** — never skip the RED phase
- The test must fail before the fix and pass after — this proves the fix actually addresses the bug
- If you cannot write a meaningful automated test (e.g., UI-only issue, environment-specific), explain why and ask the user how to proceed
- **Never mark an issue as "Done"** — only move it to "In Review" after automated checks pass
- "Done" means the user has manually verified the fix works; only the user sets this status
- Passing automated tests (build, unit tests) is necessary but NOT sufficient — the user performs final verification
- Include the issue ID in the commit message: `fix(module): description [ENG-123]`
- For automated TDD enforcement via hooks, install [tdd-guard](https://github.com/nizos/tdd-guard): `npm install -g tdd-guard`
