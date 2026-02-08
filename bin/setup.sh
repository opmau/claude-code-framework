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
#   --all          Install everything (default)
#   --no-hooks     Skip hooks
#   --no-agents    Skip agents
#   --no-skills    Skip skills
#   --no-rules     Skip rules
#   --no-tickets   Skip ticket system
#   --no-docs      Skip companion docs
#   --dry-run      Show what would be copied without doing it
#   --force        Overwrite existing files without prompting
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
INSTALL_TICKETS=true
INSTALL_DOCS=true
DRY_RUN=false
FORCE=false

# --- Parse arguments ---
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --all)          ;; # default behavior
    --no-hooks)     INSTALL_HOOKS=false ;;
    --no-agents)    INSTALL_AGENTS=false ;;
    --no-skills)    INSTALL_SKILLS=false ;;
    --no-rules)     INSTALL_RULES=false ;;
    --no-tickets)   INSTALL_TICKETS=false ;;
    --no-docs)      INSTALL_DOCS=false ;;
    --dry-run)      DRY_RUN=true ;;
    --force)        FORCE=true ;;
    -*)             echo -e "${RED}Unknown option: $arg${NC}"; exit 1 ;;
    *)              TARGET_DIR="$arg" ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Usage: bash setup.sh <target-project-dir> [options]${NC}"
  echo ""
  echo "Options:"
  echo "  --all          Install everything (default)"
  echo "  --no-hooks     Skip hooks"
  echo "  --no-agents    Skip agents"
  echo "  --no-skills    Skip skills"
  echo "  --no-rules     Skip rules"
  echo "  --no-tickets   Skip ticket system"
  echo "  --no-docs      Skip companion docs"
  echo "  --dry-run      Show what would be copied without doing it"
  echo "  --force        Overwrite existing files without prompting"
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
echo -e "${GREEN}[1/8] CLAUDE.md${NC}"
copy_file "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

# --- 2. Companion docs ---
if [ "$INSTALL_DOCS" = true ]; then
  echo -e "${GREEN}[2/8] Companion docs${NC}"
  copy_file "$TEMPLATE_DIR/docs/KNOWN_ISSUES.md" "$TARGET_DIR/docs/KNOWN_ISSUES.md"
  copy_file "$TEMPLATE_DIR/docs/CURRENT_SPRINT.md" "$TARGET_DIR/docs/CURRENT_SPRINT.md"
else
  echo -e "${YELLOW}[2/8] Companion docs — skipped${NC}"
fi

# --- 3. Skills ---
if [ "$INSTALL_SKILLS" = true ]; then
  echo -e "${GREEN}[3/8] Skills${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"
else
  echo -e "${YELLOW}[3/8] Skills — skipped${NC}"
fi

# --- 4. Hooks ---
if [ "$INSTALL_HOOKS" = true ]; then
  echo -e "${GREEN}[4/8] Hooks${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"
  # Make hooks executable
  if [ "$DRY_RUN" = false ]; then
    find "$TARGET_DIR/.claude/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  fi
  # Copy settings template
  copy_file "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"
else
  echo -e "${YELLOW}[4/8] Hooks — skipped${NC}"
fi

# --- 5. Rules ---
if [ "$INSTALL_RULES" = true ]; then
  echo -e "${GREEN}[5/8] Rules${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"
else
  echo -e "${YELLOW}[5/8] Rules — skipped${NC}"
fi

# --- 6. Agents ---
if [ "$INSTALL_AGENTS" = true ]; then
  echo -e "${GREEN}[6/8] Agents${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"
else
  echo -e "${YELLOW}[6/8] Agents — skipped${NC}"
fi

# --- 7. Tickets ---
if [ "$INSTALL_TICKETS" = true ]; then
  echo -e "${GREEN}[7/8] Ticket system${NC}"
  copy_dir "$TEMPLATE_DIR/.claude/tickets" "$TARGET_DIR/.claude/tickets"
else
  echo -e "${YELLOW}[7/8] Ticket system — skipped${NC}"
fi

# --- 8. .claudeignore ---
echo -e "${GREEN}[8/8] .claudeignore${NC}"
copy_file "$TEMPLATE_DIR/.claudeignore" "$TARGET_DIR/.claudeignore"

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
echo "  4. Adjust hook limits in .claude/hooks/ for your language"
echo "  5. Run /build and /test to verify setup"
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}This was a dry run. No files were actually copied.${NC}"
  echo -e "${YELLOW}Remove --dry-run to perform the actual setup.${NC}"
fi
