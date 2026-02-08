#!/bin/bash
# ============================================================================
# strip-comments.sh — Remove HTML coaching comments from CLAUDE.md
# ============================================================================
# After initial project setup, strip the coaching comments to reduce
# CLAUDE.md size for production use. This typically cuts the file from
# ~850 lines to ~400 lines, saving context window for reasoning.
#
# Usage:
#   bash strip-comments.sh <path-to-CLAUDE.md>
#   bash strip-comments.sh <path-to-CLAUDE.md> --dry-run
#
# What it removes:
#   - Multi-line HTML comments (<!-- ... -->)
#   - Blank lines left behind after comment removal
#
# What it preserves:
#   - Auto-generated section markers (<!-- auto-generated-start/end:... -->)
#   - Template version comment
#   - Last updated comment
#   - All actual content and rules
# ============================================================================

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: bash strip-comments.sh <path-to-CLAUDE.md> [--dry-run]"
  exit 1
fi

FILE="$1"
DRY_RUN=false

if [ "${2:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

if [ ! -f "$FILE" ]; then
  echo "ERROR: File not found: $FILE"
  exit 1
fi

BEFORE=$(wc -l < "$FILE")

# Create temp file for processing
TMPFILE=$(mktemp)

# Use awk to remove multi-line HTML comments while preserving:
# - auto-generated markers
# - Template version / Last updated lines
awk '
  # Preserve auto-generated markers
  /<!-- auto-generated-(start|end):/ { print; next }
  # Preserve template metadata
  /<!-- Template version:/ { print; next }
  /<!-- Last updated:/ { print; next }
  # Skip multi-line comment blocks
  /<!--/ { in_comment = 1 }
  in_comment && /-->/ { in_comment = 0; next }
  !in_comment { print }
' "$FILE" > "$TMPFILE"

# Remove runs of 3+ blank lines (leave max 2)
awk '
  /^$/ { blank++; if (blank <= 2) print; next }
  { blank = 0; print }
' "$TMPFILE" > "${TMPFILE}.clean"
mv "${TMPFILE}.clean" "$TMPFILE"

AFTER=$(wc -l < "$TMPFILE")
REMOVED=$((BEFORE - AFTER))

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN — would remove $REMOVED lines ($BEFORE → $AFTER)"
  echo ""
  echo "Lines that would be removed:"
  diff "$FILE" "$TMPFILE" | grep "^< " | head -30
  if [ "$REMOVED" -gt 30 ]; then
    echo "... and $((REMOVED - 30)) more lines"
  fi
  rm "$TMPFILE"
else
  cp "$TMPFILE" "$FILE"
  rm "$TMPFILE"
  echo "Stripped coaching comments: $BEFORE → $AFTER lines ($REMOVED lines removed)"
  echo "Auto-generated markers and template metadata preserved."
fi
