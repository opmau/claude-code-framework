#!/bin/bash
# ============================================================================
# inject-critical-rules.sh — PreCompact hook
# ============================================================================
# Before context compaction, outputs the most critical rules so they
# survive in the compressed context. Without this, Claude can "forget"
# rules after long sessions.
#
# CUSTOMIZE: Add your most important rules below.
# ============================================================================

cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "CRITICAL RULES (survive compaction):\n1. Evidence-based claims: FIND code, QUOTE file:line, VERIFY before claiming\n2. Max 2 fix attempts: STOP after 2nd failure, SUMMARIZE, ASK for guidance, use /document-bug to log in Linear\n3. Anti-sycophancy: Push back when you disagree, don't agree just to be agreeable\n4. Scope: Only modify files in scope for the current task\n5. File size limits: Check limits after edits, propose splitting if exceeded\n6. Document bugs: Use /document-bug to create Linear issue, don't fix during other work\n7. Test before commit: Run build AND tests before any commit\n8. Diagnosis rules: Follow USER evidence first, no speculative fixes, test 2+ hypotheses before concluding\n9. Session mode: If a session mode is active, respect its constraints (check docs/CURRENT_SPRINT.md)\n10. Linear is source of truth: bugs tracked in Linear with 'bug' label, local snapshot in docs/LINEAR_SNAPSHOT.md is read-only cache"
  }
}
EOF

exit 0
