---
name: diagnose
description: Investigate a bug using structured differential diagnosis. Use when the user says "diagnose", "investigate this", "what's causing this", or "figure out why".
argument-hint: "<symptom description>"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob, Task
model: sonnet
---

# /diagnose — Structured differential diagnosis

Investigate a bug systematically by gathering evidence, forming multiple hypotheses, and testing each before proposing any fix. This prevents the "guess and fix" anti-pattern.

## Steps

1. **Gather the symptom** from `$ARGUMENTS` or ask the user. Document:
   - What's happening (the observable failure)
   - What's expected (the correct behavior)
   - When it started (if known)
   - Any user-provided log evidence

2. **Collect evidence** — read logs, error output, and relevant source code:
   - Read the FULL log, not just the error line
   - Search for related error patterns in the codebase
   - Check `docs/LINEAR_SNAPSHOT.md` for related tracked bugs
   - Check recent git changes: `git log --oneline -20` and `git diff HEAD~5`

3. **Form hypotheses** — generate 2-4 distinct possible causes:
   ```
   Hypothesis 1: [cause] — Evidence for: [X] | Evidence against: [Y]
   Hypothesis 2: [cause] — Evidence for: [X] | Evidence against: [Y]
   Hypothesis 3: [cause] — Evidence for: [X] | Evidence against: [Y]
   ```

4. **Test each hypothesis** — for each one, find confirming or disconfirming evidence:
   - Use Task agents to investigate multiple hypotheses in parallel when possible
   - Search for code paths, check configurations, read documentation
   - Each hypothesis must have a verdict: CONFIRMED, RULED OUT, or INCONCLUSIVE

5. **Report findings** in structured format:
   ```
   ## Diagnosis: [symptom summary]

   ### Evidence Collected
   - [evidence 1 with file:line]
   - [evidence 2 with file:line]

   ### Hypotheses Tested
   1. [hypothesis] — [CONFIRMED/RULED OUT/INCONCLUSIVE]
      Evidence: [what confirmed or ruled it out]
   2. [hypothesis] — [CONFIRMED/RULED OUT/INCONCLUSIVE]
      Evidence: [what confirmed or ruled it out]

   ### Root Cause
   [Most likely cause with supporting evidence]

   ### Recommended Fix
   [Specific fix with file:line targets]
   [What could go wrong with this fix]

   ### What This Is NOT
   [Ruled-out causes — prevents revisiting dead ends]
   ```

6. **Do NOT implement the fix** — present the diagnosis and let the user decide.

## Critical Rules

- **Follow user evidence first.** If the user provides log evidence pointing to cause X, investigate X before proposing alternative theories.
- **No speculative fixes.** Do not propose a fix until at least one hypothesis is confirmed with evidence.
- **Quote evidence.** Every claim must reference specific file:line or log output.
- **Rule out before concluding.** The first plausible theory is often wrong. Test at least 2 hypotheses.

## Notes

- This skill is investigation-only — it does not modify source files
- Use Task agents for parallel investigation when hypotheses are independent
- If all hypotheses are inconclusive, say so and suggest additional diagnostic steps
- Use `/document-bug` to log findings in Linear if the bug isn't already tracked
