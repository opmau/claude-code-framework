---
name: document-bug
description: Document a bug by creating a Linear issue without fixing it. Use when the user says "document bug", "log this bug", "document don't fix", or during refactoring when a bug is discovered.
argument-hint: "<bug description>"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
model: claude-3-5-haiku-latest
---

# /document-bug — Document a bug without fixing source code

Record a bug as a Linear issue (labeled `bug`) without modifying any source files. This enforces the "document, don't fix" protocol during refactoring and migration sessions.

## Steps

1. Verify the Linear CLI is available:
   ```bash
   linear --version 2>/dev/null || echo "LINEAR_CLI_MISSING"
   ```
   If missing, tell the user to install it:
   - macOS: `brew install schpet/tap/linear`
   - Deno: `deno install -A --reload -f -g -n linear jsr:@schpet/linear-cli`
   Then authenticate: `linear auth login`

2. Gather bug details. If `$ARGUMENTS` is provided, use it as the symptom description. Then determine:
   - **Symptom:** What's happening? (from arguments or observation)
   - **Evidence:** Log output, error messages, file:line references
   - **Suspected root cause:** What you THINK is wrong (with reasoning)
   - **Affected module:** Which file(s) are involved
   - **Priority:** 1 (Urgent) / 2 (High) / 3 (Medium) / 4 (Low)

3. Create the issue in Linear with the `bug` and `discovered-in-session` labels:
   ```bash
   linear issue create \
     -t "<Short bug title>" \
     -d "**Symptom:** <symptom>

   **Evidence:** <log lines, error messages with file:line>

   **Suspected Root Cause:** <theory with reasoning>

   **Affected Module:** <file(s)>

   **Fix Approach:** <suggested fix — to be attempted in a separate session>

   **Discovered during:** <activity — e.g., refactoring, feature work>" \
     --team "<team-key>" \
     --priority <priority-number> \
     --label "bug" \
     --label "discovered-in-session" \
     --no-interactive
   ```

4. Capture the returned issue ID (e.g., `ENG-456`).

5. Report what was documented:
   ```
   Documented: ENG-456 — [description]
   Priority: [priority]
   Labels: bug, discovered-in-session

   NO source files were modified. Fix this in a dedicated session using /fix-issue ENG-456.
   ```

## Critical Constraint

**DO NOT modify any source files (src/, tests/, or any code files).** This skill is documentation-only. If you feel the urge to fix the bug, resist — that's exactly the failure mode this skill prevents. The fix belongs in a separate, focused session using `/fix-issue`.

## Notes

- Include actual log evidence in the description, not paraphrased summaries
- If the bug was found during refactoring, note which refactoring task surfaced it
- Default to the team configured in `.linear.toml` if available
- The `discovered-in-session` label distinguishes bugs found by Claude from user-reported bugs
