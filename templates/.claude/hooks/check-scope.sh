#!/bin/bash
# ============================================================================
# check-scope.sh — PreToolUse hook for Edit|Write
# ============================================================================
# Warns when Claude edits files outside expected directories.
# Does NOT block — provides context so Claude can self-correct.
#
# CUSTOMIZE: Adjust ALLOWED_DIRS for your project structure.
# ============================================================================

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- CUSTOMIZE THESE FOR YOUR PROJECT ---
# Directories where edits are expected.
# DEFAULT: restrictive — only src, tests, docs, and .claude config.
# Add more directories as needed for your project.
ALLOWED_DIRS="src/ tests/ docs/ .claude/"
# Files that are always OK to edit
ALLOWED_FILES="CLAUDE.md docs/KNOWN_ISSUES.md docs/CURRENT_SPRINT.md"
# ----------------------------------------

# --- SESSION MODE ENFORCEMENT ---
# If a session mode is active in CURRENT_SPRINT.md, enforce stricter constraints
if [ -f "docs/CURRENT_SPRINT.md" ]; then
  SESSION_MODE=$(grep -A1 "Active Session Mode" docs/CURRENT_SPRINT.md 2>/dev/null | grep "Mode:" | sed 's/.*Mode:[[:space:]]*//' | tr -d '[:space:]')
  case "$SESSION_MODE" in
    document-only|review)
      # In document-only or review mode, only docs and .claude are allowed
      ALLOWED_DIRS="docs/ .claude/"
      ;;
    debug)
      # In debug mode, keep defaults but add extra warning
      ;;
  esac
fi
# ----------------------------------------

# Check if file is in an allowed directory
IN_SCOPE=false
for DIR in $ALLOWED_DIRS; do
  if echo "$FILE_PATH" | grep -q "$DIR"; then
    IN_SCOPE=true
    break
  fi
done

# Check if file is in the always-allowed list
for ALLOWED in $ALLOWED_FILES; do
  if echo "$FILE_PATH" | grep -q "$ALLOWED"; then
    IN_SCOPE=true
    break
  fi
done

if [ "$IN_SCOPE" = false ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "SCOPE WARNING: You're editing '$FILE_PATH' which is outside the expected directories ($ALLOWED_DIRS). Verify this file is in scope for the current task."
  }
}
EOF
fi

# Always allow — this is advisory, not blocking
exit 0
