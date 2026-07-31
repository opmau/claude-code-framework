---
name: fix-issue
description: Pick a bug from Linear, reproduce it, agree the acceptance criteria, then fix it test-first and update the issue. Use when the user says "fix issue", "fix bug", "work on known issue", or "pick a bug".
argument-hint: "<ENG-NNN or description>"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
model: opus
---

# /fix-issue — Fix a tracked Linear issue (test-driven)

Select a bug from Linear, confirm it is real and understood, agree what correct
behaviour is, then fix it test-first and update the issue.

This skill follows a **test-driven** approach: RED → GREEN → REFACTOR, behind two
gates that run before any fix is planned.

> **A tracked issue is a lead, not a specification.** It tells you where to look.
> It does not tell you what is true, or what the code is supposed to do — both are
> established here, with the user, before RED.

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

### GATE 1 — A confirmed root cause

3. **Check the entry condition** — the issue's `Root Cause:` field:

   - `CONFIRMED` → proceed to Gate 2.
   - `UNCONFIRMED`, missing, or phrased as a theory → STOP. Run the `/diagnose`
     protocol (Task agents for independent hypotheses) and post the verdict to the
     issue as `/diagnose` step 6 describes. Only then continue.

   **Do not fix a suspicion.** A theory that fits the evidence is not a cause.

4. **Check whether the evidence is stale.** If the affected code has moved since
   the issue's `Observed at:` commit, re-verify every claim at Gate 2 rather than
   reasoning from the description. An absent field means re-verify by default.

   ```bash
   git log --oneline <observed-sha>..HEAD -- <affected files>
   ```

### GATE 2 — Reproduce the failure

5. **Reproduce the bug and watch it fail.** Run the command, script or test that
   exhibits the symptom, and read the actual output.

   Judging the issue's recorded evidence "still valid" is **not** reproduction —
   only an executable check tells you the bug is still real. Bugs get fixed
   incidentally; issues go stale.

   **If you cannot reproduce it, STOP.** Comment on the issue with what you tried
   and what you saw instead, and ask the user. Proceeding would mean changing code
   on the strength of a description alone.

   The user may explicitly waive this for a bug that cannot be reproduced locally.
   Record the waiver and its reason on the issue, and repeat it in the final report.

### Establish the contract

6. **Agree what the code is meant to do.** The RED test asserts *expected correct
   behaviour* — this is where that is established, not inferred.

   Ask the questions the investigation raised — the ones the code cannot answer —
   and ask them **now**, after both gates. Questions asked before reading the code
   are generic. Where intended behaviour is ambiguous you must ask: the buggy code
   cannot tell you what it was meant to do, and an `Expected: UNKNOWN` field is the
   norm rather than a defect in the report.

   Present the contract and get explicit approval before writing any test:

   ```
   ## Contract: ENG-123

   Symptom:         [observed failure, as reproduced at Gate 2]
   Expected:        [what correct behaviour is]
   Root cause:      [confirmed cause, file:line]

   Acceptance criteria:
   1. [specific, testable statement of correct behaviour]
   2. [...]

   Out of scope:    [what this fix deliberately does not address]
   Manual check:    [how the user will confirm it themselves]
   ```

   Each acceptance criterion must be testable — it becomes one assertion in the
   RED test. "Handles errors properly" is not a criterion; "returns -1 and logs
   the symbol when the asset is unknown" is.

7. **Post the approved contract to the issue** — the only durable record of what
   "fixed" was agreed to mean:

   ```bash
   linear issue comment add ENG-123 -b "**Agreed contract**

   <the approved block from step 6>"
   ```

8. **Plan the fix:**
   - List the files that need to change (must be within Change Size Limits for bug fixes: 1-3 files)
   - Identify the test file where the regression test will go (existing test file or new one)
   - State the fix approach and what could go wrong
   - Get user confirmation before proceeding

### RED — Write a failing test

9. **Turn the acceptance criteria into a failing test:**
   - **Each acceptance criterion from step 6 becomes one assertion** — the criteria
     are the specification, the test is that specification made executable. It
     fails against the current buggy code
   - Place the test in the appropriate test file following the project's existing test conventions
   - Name the test descriptively: `test_<what_should_happen>` or `it("should <expected behavior>")`
   - Run the test and **confirm it fails**:
     ```bash
     # Run only the new test to confirm RED
     <project test command> --filter "<test name>"
     ```
   - If the test **passes**, the test does not capture what you reproduced at
     Gate 2. Fix the test — do not proceed, and do not conclude the bug is absent
   - If the test **fails for the wrong reason** (syntax error, import issue, etc.), fix the test itself — the test must fail because of the bug, not because of a test error
   - If a criterion cannot be expressed as an automated test, say which one and
     why, and agree a manual check for it with the user before continuing

### GREEN — Write the minimum fix

10. **Implement the fix:**
    - Make the **minimum changes** needed to make the failing test pass
    - Do NOT add code beyond what the test requires
    - Follow the max 2 fix attempts rule — if the 2nd attempt fails, STOP and add a comment to the issue
    - Run the new test and **confirm it passes**:
      ```bash
      # Run only the new test to confirm GREEN
      <project test command> --filter "<test name>"
      ```

### REFACTOR — Clean up with confidence

11. **Refactor (if needed):**
    - Now that tests pass, clean up the implementation (remove duplication, improve naming, etc.)
    - Run the **full test suite** after any refactoring to ensure nothing else broke:
      ```bash
      <project test command>
      ```
    - Run the project build command to confirm it compiles/builds cleanly

### Update and report

12. **Update the Linear issue to "In Review":**
    ```bash
    linear issue update ENG-123 --state "In Review"
    linear issue comment add ENG-123 -b "**Root Cause:** [actual root cause]

    **Regression Test:** [test file:test name] — asserts [what the test checks]

    **Acceptance Criteria:**
    - 1. [criterion] — MET (asserted by [test name])
    - 2. [criterion] — MET / NOT MET

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

13. **Report:**
    ```
    ## Fixed: ENG-123 — [description]

    ### Root Cause
    [actual root cause]

    ### Acceptance Criteria
    - 1. [criterion] — MET, asserted by [test name]
    - 2. [criterion] — MET / NOT MET
    [Every criterion agreed at step 6 appears here with its verdict.]

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
    - How to verify: [the manual check agreed in the contract at step 6]

    ### Files Changed
    - [file list]

    Ready to commit? Use /commit to create a conventional commit with [ENG-123] reference.
    ```

## Notes

- Only fix ONE issue per invocation — single-responsibility
- If the fix touches more than 3 files, stop and discuss scope with the user
- If you discover a new bug during the fix, use /document-bug to log it separately
- **Never waive a gate on your own initiative** — only the user can, and only Gate 2
- **Always write the test BEFORE writing the fix** — never skip the RED phase
- The test must fail before the fix and pass after — this proves the fix actually addresses the bug
- If you cannot write a meaningful automated test (e.g., UI-only issue, environment-specific), explain why and ask the user how to proceed
- **Never mark an issue as "Done"** — only move it to "In Review" after automated checks pass
- "Done" means the user has manually verified the fix works; only the user sets this status
- Passing automated tests (build, unit tests) is necessary but NOT sufficient — the user performs final verification
- Include the issue ID in the commit message: `fix(module): description [ENG-123]`
- For automated TDD enforcement via hooks, install [tdd-guard](https://github.com/nizos/tdd-guard): `npm install -g tdd-guard`
