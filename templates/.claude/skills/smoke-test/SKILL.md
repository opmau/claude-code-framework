---
name: smoke-test
description: Diagnose an integration/E2E test log, classify failures by severity, and batch-create issues. Use when the user says "smoke test", "diagnose log", "triage test log", or provides a test log.
argument-hint: "<path to log file or paste log>"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob, TodoWrite
model: sonnet
---

# /smoke-test — Integration Test Log Diagnosis & Triage

Analyze an integration or E2E test log, diagnose each failure against the source code, and batch-create issues for new findings.

## Steps

1. **Load the log** from `$ARGUMENTS` (file path or inline text). If no argument, ask for the log file path.

2. **Parse all failures and warnings** — extract:
   - Error messages and their context (5 lines before/after)
   - Components or modules involved
   - Function calls or API endpoints that failed
   - Network, timeout, or connection errors
   - Any stack traces or crash indicators

3. **Diagnose each failure** — for every distinct error:
   - Search the source code for the function/path that produced the error
   - Identify the root cause (wrong parameter, API response parsing, timing, config issue)
   - Classify severity:
     - **Critical**: Core functionality failure, data corruption, security issue
     - **Medium**: Degraded functionality, fallback triggered, non-fatal error
     - **Low**: Cosmetic, logging, or non-functional issue

4. **Check for existing tracked issues** — for each finding:
   - Check `docs/LINEAR_SNAPSHOT.md` or `docs/KNOWN_ISSUES.md` for existing entries
   - Search by keyword: component name, error message, function name
   - Mark as "EXISTING: [ID]" if found, "NEW" if not

5. **Create issues for NEW findings** — use the project's issue tracking:
   - If using Linear: create via `linear issue create` CLI
   - If using local tickets: create via `/create-ticket`
   - Set priority: Critical=High/Urgent, Medium=Medium, Low=Low
   - Include in description: error message, affected file:line, suspected root cause, log context

6. **Output summary table**:
   ```
   ## Smoke Test Triage: [date/log name]

   | # | Issue | Severity | Root Cause | File:Line | Tracking |
   |---|-------|----------|------------|-----------|----------|
   | 1 | ... | Critical | ... | src/...:NN | NEW: [ID] |
   | 2 | ... | Medium | ... | src/...:NN | EXISTING: [ID] |

   ### Statistics
   - Total failures: N
   - Critical: N | Medium: N | Low: N
   - New issues created: N
   - Already tracked: N
   ```

## Critical Rules

- **Diagnose against source, not assumptions.** Every root cause must reference actual code with file:line.
- **Do not fix anything.** This skill is diagnosis and triage only.
- **Do not create duplicate issues.** Always check existing tracking first.
- **Group related errors.** Multiple log lines from the same root cause = one issue, not many.
- **Include log context in issue descriptions.** Future fixers need the evidence.

## Notes

- Use TodoWrite to track multiple failures being investigated in parallel
- If the log is very large, focus on Critical and Medium issues first
- After this skill completes, use `/fix-issue [ID]` to fix individual issues
