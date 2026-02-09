#!/bin/bash
# ============================================================================
# pre-commit-check.sh — PreToolUse hook for Bash (git commit)
# ============================================================================
# Intercepts git commit commands and warns if build or tests haven't been
# run in the current session. Does NOT block — provides context so Claude
# can self-correct by running build/test before committing.
#
# CUSTOMIZE: Adjust BUILD_CMD and TEST_CMD for your project.
# ============================================================================

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only trigger on git commit commands
if ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# Skip if this is an amend or merge commit
if echo "$COMMAND" | grep -q "\-\-amend\|merge"; then
  exit 0
fi

# --- CUSTOMIZE THESE FOR YOUR PROJECT ---
# Set to your project's build and test commands
BUILD_CMD="cmake --build"
TEST_CMD="ctest\|pytest\|npm test\|cargo test\|go test"
# Path to track session state (uses temp directory)
SESSION_FILE="/tmp/.claude-session-checks-$$"
# ----------------------------------------

# Check if build was run in recent commands (look for build artifacts or markers)
# This is a heuristic check — it warns but doesn't block
BUILD_RAN=false
TEST_RAN=false

# Check for recent build/test evidence in current directory
if [ -f ".claude-build-ok" ] && [ "$(find .claude-build-ok -mmin -30 2>/dev/null)" ]; then
  BUILD_RAN=true
fi

if [ -f ".claude-test-ok" ] && [ "$(find .claude-test-ok -mmin -30 2>/dev/null)" ]; then
  TEST_RAN=true
fi

WARNINGS=""

if [ "$BUILD_RAN" = false ]; then
  WARNINGS="Build has not been verified in this session."
fi

if [ "$TEST_RAN" = false ]; then
  if [ -n "$WARNINGS" ]; then
    WARNINGS="$WARNINGS Tests have not been run in this session."
  else
    WARNINGS="Tests have not been run in this session."
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "PRE-COMMIT WARNING: $WARNINGS Run build and tests before committing. If build/tests pass, create marker files: touch .claude-build-ok && touch .claude-test-ok"
  }
}
EOF
fi

# Always allow — this is advisory, not blocking
exit 0
