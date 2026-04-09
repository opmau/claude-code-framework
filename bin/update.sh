#!/bin/bash
# ============================================================================
# Claude Code Project Framework — Update Script
# ============================================================================
# Updates framework files in an existing project while preserving
# project-specific customizations.
#
# UPDATES (overwrites):
#   .claude/skills/     — all skill definitions
#   .claude/rules/      — all rule files
#   .claude/hooks/      — all hook scripts
#   .claude/agents/     — all agent definitions
#   .claude/settings.local.json — hook registration
#   .claude/tdd-guard/  — TDD guard templates
#   .claudeignore       — ignore patterns
#
# PRESERVES (never overwrites):
#   CLAUDE.md           — project-specific rules and configuration
#   docs/               — project documentation
#   .claude/tickets/    — local ticket data
#   .claude/agent-memory/ — agent persistent memory
#
# Usage:
#   bash update.sh <target-project-dir> [options]
#
# Options:
#   --dry-run      Show what would be changed without doing it
#   --force        Skip confirmation prompt
#
# Prerequisites:
#   - bash 4+
#   - Git Bash or WSL on Windows
# ============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Resolve template directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates" && pwd)"

# --- Defaults ---
DRY_RUN=false
FORCE=false

# --- Parse arguments ---
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --force)    FORCE=true ;;
    -*)         echo -e "${RED}Unknown option: $arg${NC}"; exit 1 ;;
    *)          TARGET_DIR="$arg" ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Usage: bash update.sh <target-project-dir> [--dry-run] [--force]${NC}"
  exit 1
fi

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

# --- Validate target ---
if [ ! -d "$TARGET_DIR/.claude" ]; then
  echo -e "${RED}ERROR: $TARGET_DIR does not appear to be a framework project (.claude/ not found)${NC}"
  echo -e "Use ${BLUE}setup.sh${NC} for first-time installation."
  exit 1
fi

# --- Helper functions ---
update_file() {
  local src="$1"
  local dst="$2"

  if [ "$DRY_RUN" = true ]; then
    if [ -f "$dst" ]; then
      if diff -q "$src" "$dst" >/dev/null 2>&1; then
        echo -e "  ${BLUE}[unchanged]${NC} $dst"
      else
        echo -e "  ${YELLOW}[would update]${NC} $dst"
      fi
    else
      echo -e "  ${GREEN}[would add]${NC} $dst"
    fi
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo -e "  ${GREEN}[updated]${NC} $dst"
}

update_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  # Update/add files from template
  find "$src_dir" -type f | while read -r src_file; do
    local rel_path="${src_file#$src_dir/}"
    update_file "$src_file" "$dst_dir/$rel_path"
  done

  # Remove files in target that no longer exist in template
  if [ -d "$dst_dir" ]; then
    find "$dst_dir" -type f | while read -r dst_file; do
      local rel_path="${dst_file#$dst_dir/}"
      local src_file="$src_dir/$rel_path"
      if [ ! -f "$src_file" ]; then
        if [ "$DRY_RUN" = true ]; then
          echo -e "  ${RED}[would remove]${NC} $dst_file (no longer in framework)"
        else
          rm "$dst_file"
          echo -e "  ${RED}[removed]${NC} $dst_file (no longer in framework)"
        fi
      fi
    done
  fi
}

# --- Banner ---
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Claude Code Project Framework — Update         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Template source: ${BLUE}$TEMPLATE_DIR${NC}"
echo -e "Target project:  ${BLUE}$TARGET_DIR${NC}"
if [ "$DRY_RUN" = true ]; then
  echo -e "Mode:            ${YELLOW}DRY RUN${NC}"
fi
echo ""

# --- Confirmation ---
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
  echo -e "${YELLOW}This will overwrite framework files (skills, rules, hooks, agents).${NC}"
  echo -e "${YELLOW}Project-specific files (CLAUDE.md, docs/, tickets/) will NOT be touched.${NC}"
  echo ""
  read -p "Continue? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

# --- Protected files (never overwrite) ---
echo -e "${BLUE}Protected (not updated):${NC}"
echo -e "  CLAUDE.md, docs/*, .claude/tickets/*, .claude/agent-memory/*"
echo ""

# --- 1. Skills ---
echo -e "${GREEN}[1/6] Skills${NC}"
update_dir "$TEMPLATE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

# --- 2. Rules ---
echo -e "${GREEN}[2/6] Rules${NC}"
update_dir "$TEMPLATE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"

# --- 3. Hooks ---
echo -e "${GREEN}[3/6] Hooks${NC}"
update_dir "$TEMPLATE_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"
# Make hooks executable
if [ "$DRY_RUN" = false ]; then
  find "$TARGET_DIR/.claude/hooks" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
fi

# --- 4. Agents ---
echo -e "${GREEN}[4/6] Agents${NC}"
update_dir "$TEMPLATE_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"

# --- 5. Settings & TDD Guard ---
echo -e "${GREEN}[5/6] Settings & TDD Guard${NC}"
update_file "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"
if [ -d "$TEMPLATE_DIR/.claude/tdd-guard" ]; then
  update_dir "$TEMPLATE_DIR/.claude/tdd-guard" "$TARGET_DIR/.claude/tdd-guard"
fi

# --- 6. .claudeignore ---
echo -e "${GREEN}[6/6] .claudeignore${NC}"
update_file "$TEMPLATE_DIR/.claudeignore" "$TARGET_DIR/.claudeignore"

# --- Summary ---
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Update complete!                               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "What was updated:"
echo "  - Skills, rules, hooks, agents (overwritten with latest framework)"
echo "  - settings.local.json (hook registration)"
echo "  - .claudeignore"
echo ""
echo "What was preserved:"
echo "  - CLAUDE.md (your project rules)"
echo "  - docs/ (your documentation)"
echo "  - .claude/tickets/ (your task tracking)"
echo "  - .claude/agent-memory/ (agent persistent memory)"
echo ""
echo -e "${BLUE}Review changes:${NC} git diff"
echo -e "${BLUE}New framework features may need CLAUDE.md updates.${NC}"
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}This was a dry run. No files were changed.${NC}"
  echo -e "${YELLOW}Remove --dry-run to perform the actual update.${NC}"
fi
