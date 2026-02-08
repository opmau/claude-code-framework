---
name: document-bug
description: Document a bug without fixing it. Use when the user says "document bug", "log this bug", "document don't fix", or during refactoring when a bug is discovered.
argument-hint: "<bug description>"
user-invocable: true
allowed-tools: Read, Write, Glob, Grep
model: haiku
---

# /document-bug — Document a bug without fixing source code

Record a bug in KNOWN_ISSUES.md without modifying any source files. This enforces the "document, don't fix" protocol during refactoring and migration sessions.

## Steps

1. Gather bug details. If `$ARGUMENTS` is provided, use it as the symptom description. Then determine:
   - **Symptom:** What's happening? (from arguments or observation)
   - **Evidence:** Log output, error messages, file:line references
   - **Suspected root cause:** What you THINK is wrong (with reasoning)
   - **Affected module:** Which file(s) are involved

2. Read the current known issues file:
   ```
   docs/KNOWN_ISSUES.md
   ```

3. Add a new entry to `docs/KNOWN_ISSUES.md` using this format:
   ```markdown
   ### [BUG-NNN] — [Short description]
   - **Status:** Open
   - **Discovered:** [date] during [activity]
   - **Symptom:** [What's visibly wrong]
   - **Evidence:** [Log lines, error messages with file:line]
   - **Suspected Root Cause:** [Theory with reasoning]
   - **Affected Module:** [file(s)]
   - **Fix Approach:** [Suggested fix — to be attempted in a separate session]
   - **Priority:** [High / Medium / Low]
   ```

4. Report what was documented:
   ```
   Documented: BUG-NNN — [description]
   File: docs/KNOWN_ISSUES.md
   Priority: [priority]

   NO source files were modified. Fix this in a dedicated session.
   ```

## Critical Constraint

**DO NOT modify any source files (src/, tests/, or any code files).** This skill is documentation-only. If you feel the urge to fix the bug, resist — that's exactly the failure mode this skill prevents. The fix belongs in a separate, focused session.

## Notes

- Increment the BUG-NNN number from the highest existing entry
- Include actual log evidence, not paraphrased summaries
- If the bug was found during refactoring, note which refactoring task surfaced it
- Link to the relevant ticket if one exists
