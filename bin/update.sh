#!/bin/bash
# ============================================================================
# Claude Code Project Framework — Update Script
# ============================================================================
# Updates framework files in an existing project without touching
# project-specific customizations (CLAUDE.md, docs/, .linear.toml).
#
# Usage:
#   bash update.sh <target-project-dir> [options]
#
# Options:
#   --dry-run      Show what would be updated without doing it
#
# Prerequisites:
#   - bash 4+ (macOS: brew install bash)
#   - Git Bash or WSL on Windows
# ============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Resolve paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_DIR/templates"

# --- Defaults ---
DRY_RUN=false

# --- Parse arguments ---
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    -*)         echo -e "${RED}Unknown option: $arg${NC}"; exit 1 ;;
    *)          TARGET_DIR="$arg" ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Usage: bash update.sh <target-project-dir> [--dry-run]${NC}"
  exit 1
fi

# --- Validate ---
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo -e "${RED}ERROR: Template directory not found at $TEMPLATE_DIR${NC}"
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}ERROR: Target project directory does not exist: $TARGET_DIR${NC}"
  exit 1
fi

if [ ! -d "$TARGET_DIR/.claude" ]; then
  echo -e "${RED}ERROR: No .claude/ directory found in $TARGET_DIR${NC}"
  echo "This doesn't look like a project using the framework."
  echo "Use bin/setup.sh for initial installation."
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# --- Framework version ---
FRAMEWORK_VERSION="unknown"
if command -v git &>/dev/null && [ -d "$REPO_DIR/.git" ]; then
  FRAMEWORK_VERSION=$(cd "$REPO_DIR" && git log -1 --format="%h (%cd)" --date=short 2>/dev/null || echo "unknown")
fi

# --- Counters ---
UPDATED=0
ADDED=0
UNCHANGED=0
REMOVED=0

# --- Helper: update a single file ---
update_file() {
  local src="$1"
  local dst="$2"

  if [ "$DRY_RUN" = true ]; then
    if [ -f "$dst" ]; then
      if diff -q "$src" "$dst" &>/dev/null; then
        UNCHANGED=$((UNCHANGED + 1))
      else
        echo -e "  ${BLUE}[update]${NC} $dst"
        UPDATED=$((UPDATED + 1))
      fi
    else
      echo -e "  ${GREEN}[new]${NC}    $dst"
      ADDED=$((ADDED + 1))
    fi
    return
  fi

  if [ -f "$dst" ]; then
    if diff -q "$src" "$dst" &>/dev/null; then
      UNCHANGED=$((UNCHANGED + 1))
      return
    fi
    cp "$src" "$dst"
    echo -e "  ${BLUE}[update]${NC} $dst"
    UPDATED=$((UPDATED + 1))
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo -e "  ${GREEN}[new]${NC}    $dst"
    ADDED=$((ADDED + 1))
  fi
}

# --- Helper: update all files in a directory ---
update_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  find "$src_dir" -type f | sort | while read -r src_file; do
    local rel_path="${src_file#$src_dir/}"
    update_file "$src_file" "$dst_dir/$rel_path"
  done
}

# --- Helper: remove files in target that no longer exist in templates ---
cleanup_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$dst_dir" ]; then
    return
  fi

  find "$dst_dir" -type f | sort | while read -r dst_file; do
    local rel_path="${dst_file#$dst_dir/}"
    local src_file="$src_dir/$rel_path"
    if [ ! -f "$src_file" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo -e "  ${RED}[remove]${NC} $dst_file"
      else
        rm "$dst_file"
        echo -e "  ${RED}[remove]${NC} $dst_file"
      fi
      REMOVED=$((REMOVED + 1))
    fi
  done
}

# --- Banner ---
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Claude Code Project Framework — Update         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Framework:  ${BLUE}$FRAMEWORK_VERSION${NC}"
echo -e "Source:     ${BLUE}$TEMPLATE_DIR${NC}"
echo -e "Target:     ${BLUE}$TARGET_DIR${NC}"
if [ "$DRY_RUN" = true ]; then
  echo -e "Mode:       ${YELLOW}DRY RUN${NC}"
fi
echo ""

# --- Update framework files ---

echo -e "${GREEN}[1/6] Skills${NC}"
update_dir "$TEMPLATE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"
cleanup_dir "$TEMPLATE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

echo -e "${GREEN}[2/6] Rules${NC}"
update_dir "$TEMPLATE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"
cleanup_dir "$TEMPLATE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"

echo -e "${GREEN}[3/6] Hooks${NC}"
update_dir "$TEMPLATE_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"
cleanup_dir "$TEMPLATE_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"
if [ "$DRY_RUN" = false ]; then
  find "$TARGET_DIR/.claude/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
fi

echo -e "${GREEN}[4/6] Agents${NC}"
update_dir "$TEMPLATE_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"
cleanup_dir "$TEMPLATE_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"

echo -e "${GREEN}[5/6] Settings${NC}"
update_file "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"

echo -e "${GREEN}[6/6] .claudeignore${NC}"
update_file "$TEMPLATE_DIR/.claudeignore" "$TARGET_DIR/.claudeignore"

# --- Skipped files ---
echo ""
echo -e "${YELLOW}Skipped (project-specific):${NC}"
echo "  CLAUDE.md"
echo "  docs/CURRENT_SPRINT.md"
echo "  docs/LINEAR_SNAPSHOT.md"

# --- Summary ---
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Update complete                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Updated:   ${BLUE}$UPDATED${NC}"
echo -e "  New:       ${GREEN}$ADDED${NC}"
echo -e "  Removed:   ${RED}$REMOVED${NC}"
echo -e "  Unchanged: $UNCHANGED"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}This was a dry run. No files were changed.${NC}"
  echo -e "${YELLOW}Remove --dry-run to apply updates.${NC}"
fi
