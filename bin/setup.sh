#!/bin/bash
# ============================================================================
# Claude Code Project Framework — Setup Script
# ============================================================================
# Bootstraps a new project with the framework templates.
#
# Usage:
#   bash setup.sh <target-project-dir> [options]
#
# Options:
#   --all                  Install everything (default)
#   --language <name>      Apply file-size calibration for a language.
#                          Supported: python, cpp, typescript, rust, go, none.
#                          Default (omitted): no calibration — template C++ defaults
#                          remain in place. Use 'none' to be explicit.
#   --no-hooks             Skip hooks
#   --no-agents            Skip agents
#   --no-skills            Skip skills
#   --no-rules             Skip rules
#   --no-docs              Skip companion docs
#   --dry-run              Show what would be copied without doing it
#   --force                Overwrite existing files without prompting
#
# Prerequisites:
#   - bash 4+ (macOS: brew install bash)
#   - jq (for hooks): brew install jq / apt install jq
#   - Git Bash or WSL on Windows
# ============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Resolve template directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates" && pwd)"

# --- Defaults ---
INSTALL_HOOKS=true
INSTALL_AGENTS=true
INSTALL_SKILLS=true
INSTALL_RULES=true
INSTALL_DOCS=true
DRY_RUN=false
FORCE=false
LANGUAGE=""

# --- Parse arguments ---
TARGET_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --all)          ;; # default behavior
    --language)
      shift
      if [ $# -eq 0 ]; then
        echo -e "${RED}ERROR: --language requires an argument.${NC}"
        exit 1
      fi
      LANGUAGE="$1"
      ;;
    --language=*)   LANGUAGE="${1#--language=}" ;;
    --no-hooks)     INSTALL_HOOKS=false ;;
    --no-agents)    INSTALL_AGENTS=false ;;
    --no-skills)    INSTALL_SKILLS=false ;;
    --no-rules)     INSTALL_RULES=false ;;
    --no-docs)      INSTALL_DOCS=false ;;
    --dry-run)      DRY_RUN=true ;;
    --force)        FORCE=true ;;
    -*)             echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    *)              TARGET_DIR="$1" ;;
  esac
  shift
done

# --- Validate --language ---
case "${LANGUAGE:-}" in
  ""|"none"|"python"|"cpp"|"typescript"|"rust"|"go") ;;
  *)
    echo -e "${RED}ERROR: unknown --language '$LANGUAGE'.${NC}"
    echo "       Supported: python, cpp, typescript, rust, go, none"
    exit 1
    ;;
esac

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Usage: bash setup.sh <target-project-dir> [options]${NC}"
  echo ""
  echo "Options:"
  echo "  --all                  Install everything (default)"
  echo "  --language <name>      Auto-calibrate file-size limits for a language."
  echo "                         Supported: python, cpp, typescript, rust, go, none"
  echo "  --no-hooks             Skip hooks"
  echo "  --no-agents            Skip agents"
  echo "  --no-skills            Skip skills"
  echo "  --no-rules             Skip rules"
  echo "  --no-docs              Skip companion docs"
  echo "  --dry-run              Show what would be copied without doing it"
  echo "  --force                Overwrite existing files without prompting"
  exit 1
fi

# --- Validate ---
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo -e "${RED}ERROR: Template directory not found at $TEMPLATE_DIR${NC}"
  exit 1
fi

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

# --- Helper functions ---
copy_file() {
  local src="$1"
  local dst="$2"

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${BLUE}[dry-run]${NC} $dst"
    return
  fi

  if [ -f "$dst" ] && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}[exists]${NC} $dst — skipping (use --force to overwrite)"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo -e "  ${GREEN}[copied]${NC} $dst"
}

# Portable in-place file edit (works on GNU sed, BSD sed, Git Bash).
# Usage: inplace_sed <sed-expression> <file>
inplace_sed() {
  local expr="$1"
  local file="$2"
  if [ "$DRY_RUN" = true ]; then return; fi
  if [ ! -f "$file" ]; then return; fi
  local tmp="$file.tmp.$$"
  sed "$expr" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Apply language calibration to the file-size hook constants and the
# CLAUDE.md File Size Limits table. Idempotent — re-running with a different
# language overwrites cleanly.
apply_language_calibration() {
  local lang="$1"
  local target="$2"
  local hook="$target/.claude/hooks/check-file-size.sh"
  local claude_md="$target/CLAUDE.md"

  # Per-language calibration. Header limit is "N/A" for languages without
  # separate header/interface files; we still set the hook constant equal
  # to the impl limit so any extension that *would* match (none for these
  # langs) gets the impl limit. The table value is the human-facing one.
  local h_hook i_hook t_hook h_table i_table t_table label
  case "$lang" in
    python)     h_hook=300; i_hook=300; t_hook=300; h_table="N/A"; i_table=300; t_table=300; label="Python";;
    cpp)        h_hook=150; i_hook=400; t_hook=500; h_table=150;   i_table=400; t_table=500; label="C/C++";;
    typescript) h_hook=100; i_hook=300; t_hook=400; h_table=100;   i_table=300; t_table=400; label="TypeScript";;
    rust)       h_hook=400; i_hook=400; t_hook=400; h_table="N/A"; i_table=400; t_table=400; label="Rust";;
    go)         h_hook=400; i_hook=400; t_hook=400; h_table="N/A"; i_table=400; t_table=400; label="Go";;
    *) return ;;
  esac

  # 1. Patch the hook script constants.
  if [ -f "$hook" ]; then
    inplace_sed "s/^HEADER_LIMIT=.*/HEADER_LIMIT=$h_hook/" "$hook"
    inplace_sed "s/^IMPL_LIMIT=.*/IMPL_LIMIT=$i_hook/"     "$hook"
    inplace_sed "s/^TOTAL_LIMIT=.*/TOTAL_LIMIT=$t_hook/"   "$hook"
  fi

  # 2. Patch the CLAUDE.md File Size Limits table placeholders.
  #    The template uses [150], [400], [500] as bracketed placeholders.
  #    Use | as the s-command delimiter so values containing / (e.g. N/A) are safe.
  if [ -f "$claude_md" ]; then
    inplace_sed "s|\[150\] lines|$h_table lines|g" "$claude_md"
    inplace_sed "s|\[400\] lines|$i_table lines|g" "$claude_md"
    inplace_sed "s|\[500\] lines|$t_table lines|g" "$claude_md"
  fi

  echo -e "  ${GREEN}[calibrated]${NC} $label — hook + CLAUDE.md File Size Limits patched (header/$h_table, impl/$i_table, total/$t_table)"
}

copy_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  find "$src_dir" -type f | while read -r src_file; do
    local rel_path="${src_file#$src_dir/}"
    copy_file "$src_file" "$dst_dir/$rel_path"
  done
}

# --- Banner ---
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Claude Code Project Framework — Setup          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Template source: ${BLUE}$TEMPLATE_DIR${NC}"
echo -e "Target project:  ${BLUE}$TARGET_DIR${NC}"
if [ "$DRY_RUN" = true ]; then
  echo -e "Mode:            ${YELLOW}DRY RUN${NC}"
fi
echo ""

# --- Create target directory if needed ---
if [ ! -d "$TARGET_DIR" ] && [ "$DRY_RUN" = false ]; then
  mkdir -p "$TARGET_DIR"
  echo -e "${GREEN}Created target directory${NC}"
fi

# --- 1. CLAUDE.md ---
echo -e "${GREEN}[1/7] CLAUDE.md${NC}"
copy_file "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

# --- 2. Companion docs ---
if [ "$INSTALL_DOCS" = true ]; then
  echo -e "${GREEN}[2/7] Companion docs${NC}"
  copy_file "$TEMPLATE_DIR/docs/CURRENT_SPRINT.md" "$TARGET_DIR/docs/CURRENT_SPRINT.md"
  copy_file "$TEMPLATE_DIR/docs/LINEAR_SNAPSHOT.md" "$TARGET_DIR/docs/LINEAR_SNAPSHOT.md"
else
  echo -e "${YELLOW}[2/7] Companion docs — skipped${NC}"
fi

# --- 3. Skills ---
if [ "$INSTALL_SKILLS" = true ]; then
  echo -e "${GREEN}[3/7] Skills${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"
else
  echo -e "${YELLOW}[3/7] Skills — skipped${NC}"
fi

# --- 4. Hooks ---
if [ "$INSTALL_HOOKS" = true ]; then
  echo -e "${GREEN}[4/7] Hooks${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"
  # Make hooks executable
  if [ "$DRY_RUN" = false ]; then
    find "$TARGET_DIR/.claude/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  fi
  # Copy settings template
  copy_file "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"
else
  echo -e "${YELLOW}[4/7] Hooks — skipped${NC}"
fi

# --- 5. Rules ---
if [ "$INSTALL_RULES" = true ]; then
  echo -e "${GREEN}[5/7] Rules${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"
else
  echo -e "${YELLOW}[5/7] Rules — skipped${NC}"
fi

# --- 6. Agents ---
if [ "$INSTALL_AGENTS" = true ]; then
  echo -e "${GREEN}[6/7] Agents${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"
else
  echo -e "${YELLOW}[6/7] Agents — skipped${NC}"
fi

# --- 7. .claudeignore ---
echo -e "${GREEN}[7/7] .claudeignore${NC}"
copy_file "$TEMPLATE_DIR/.claudeignore" "$TARGET_DIR/.claudeignore"

# --- Apply --language calibration (after hooks + CLAUDE.md are in place) ---
if [ -n "${LANGUAGE:-}" ] && [ "$LANGUAGE" != "none" ]; then
  if [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}[calibration]${NC} Applying $LANGUAGE language calibration"
    apply_language_calibration "$LANGUAGE" "$TARGET_DIR"
  else
    echo -e "${BLUE}[dry-run]${NC} Would calibrate hooks + CLAUDE.md for $LANGUAGE"
  fi
fi

# --- Summary ---
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Setup complete!                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Open Claude Code and run the bootstrap prompt from PROJECT_SETUP.md"
echo "  3. Customize [BRACKETED] placeholders in CLAUDE.md"
if [ -z "${LANGUAGE:-}" ] || [ "$LANGUAGE" = "none" ]; then
  echo "  4. Adjust hook limits in .claude/hooks/ for your language"
  echo "     (or re-run with --language python|cpp|typescript|rust|go to auto-calibrate)"
else
  echo "  4. Hook limits auto-calibrated for $LANGUAGE — review .claude/hooks/check-file-size.sh"
fi
echo "  5. Run /build and /test to verify setup"

# --- Linear CLI preflight (only if Linear skills are present) ---
if [ "$INSTALL_SKILLS" = true ] && [ -d "$TARGET_DIR/.claude/skills/linear-create" ]; then
  echo ""
  echo "  Linear integration uses schpet/linear-cli (CLI, not MCP)."
  if command -v linear >/dev/null 2>&1; then
    echo "  ✓ linear CLI detected on PATH"
  else
    echo "  ⚠ linear CLI not detected on PATH. Install:"
    echo "      macOS:  brew install schpet/tap/linear"
    echo "      Deno:   deno install -A --reload -f -g -n linear jsr:@schpet/linear-cli"
    echo "    Then authenticate: linear auth login"
  fi
fi
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}This was a dry run. No files were actually copied.${NC}"
  echo -e "${YELLOW}Remove --dry-run to perform the actual setup.${NC}"
fi
