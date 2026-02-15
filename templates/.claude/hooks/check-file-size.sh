#!/bin/bash
# ============================================================================
# check-file-size.sh — PostToolUse hook for Edit|Write
# ============================================================================
# Checks if the edited file now exceeds the size limits from CLAUDE.md.
# Returns additional context (warning) but does NOT block (exit 0).
#
# CUSTOMIZE: Adjust HEADER_LIMIT, IMPL_LIMIT for your language.
#            See CLAUDE.md File Size Limits calibration table.
# ============================================================================

# Read hook input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# --- CUSTOMIZE THESE FOR YOUR PROJECT ---
HEADER_LIMIT=150
IMPL_LIMIT=400
TOTAL_LIMIT=500
# ----------------------------------------

LINE_COUNT=$(wc -l < "$FILE_PATH")
FILENAME=$(basename "$FILE_PATH")

# Determine limit based on file type
LIMIT=$IMPL_LIMIT
TYPE="implementation"
case "$FILENAME" in
  *.h|*.hpp|*.d.ts|*.types.ts)
    LIMIT=$HEADER_LIMIT
    TYPE="header/interface"
    ;;
esac

if [ "$LINE_COUNT" -gt "$LIMIT" ]; then
  OVER=$((LINE_COUNT - LIMIT))
  # Output warning as additional context (Claude will see this)
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "WARNING: $FILENAME is now $LINE_COUNT lines ($OVER over the $LIMIT-line $TYPE limit). Consider splitting per CLAUDE.md Splitting Strategies."
  }
}
EOF
fi

# --- COMPLEXITY HINTS (from complexity-budget rule) ---
# Lightweight heuristic to detect long functions. Not a real parser.
# CUSTOMIZE: Adjust FUNC_LIMIT for your project's threshold.
FUNC_LIMIT=40

LONG_FUNCS=""
case "$FILENAME" in
  *.ts|*.js|*.tsx|*.jsx)
    LONG_FUNCS=$(awk -v limit="$FUNC_LIMIT" '
      /^[[:space:]]*(export[[:space:]]+)?(async[[:space:]]+)?function[[:space:]]/ ||
      /^[[:space:]]*(export[[:space:]]+)?(const|let)[[:space:]]+[a-zA-Z_]+[[:space:]]*=[[:space:]]*(async[[:space:]]*)?\(/ {
        if (fname && (NR - start) > limit) printf "%s (%d lines), ", fname, (NR - start)
        fname = ""; start = NR
        if (match($0, /function[[:space:]]+([a-zA-Z_]+)/)) {
          fname = substr($0, RSTART+9, RLENGTH-9); sub(/^[[:space:]]+/, "", fname)
        } else if (match($0, /(const|let)[[:space:]]+([a-zA-Z_]+)/)) {
          s = substr($0, RSTART, RLENGTH); sub(/^(const|let)[[:space:]]+/, "", s); fname = s
        }
      }
      END { if (fname && (NR - start) > limit) printf "%s (%d lines)", fname, (NR - start) }
    ' "$FILE_PATH" 2>/dev/null)
    ;;
  *.py)
    LONG_FUNCS=$(awk -v limit="$FUNC_LIMIT" '
      /^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+/ {
        if (fname && (NR - start) > limit) printf "%s (%d lines), ", fname, (NR - start)
        fname = ""; start = NR
        if (match($0, /def[[:space:]]+([a-zA-Z_]+)/)) {
          fname = substr($0, RSTART+4, RLENGTH-4); sub(/^[[:space:]]+/, "", fname)
        }
      }
      END { if (fname && (NR - start) > limit) printf "%s (%d lines)", fname, (NR - start) }
    ' "$FILE_PATH" 2>/dev/null)
    ;;
esac

if [ -n "$LONG_FUNCS" ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "COMPLEXITY HINT: Functions exceeding ${FUNC_LIMIT}-line budget in $FILENAME: $LONG_FUNCS. Consider extracting helpers per complexity-budget rule."
  }
}
EOF
fi

exit 0
