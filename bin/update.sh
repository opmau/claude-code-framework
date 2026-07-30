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
#   --prune        Delete project files that no longer exist in the templates.
#                  OFF by default: it removes ANY skill/rule/hook/agent absent
#                  from the templates, including ones the project authored.
#
# Project-owned files, never overwritten:
#   .claude/project.conf       — always preserved; customize the framework here
#   .claude/settings.local.json \ preserved once locally modified, since they
#   .claudeignore              / carry hook wiring and per-project ignore rules
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
PRUNE=false

# --- Parse arguments ---
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --prune)    PRUNE=true ;;
    -*)         echo -e "${RED}Unknown option: $arg${NC}"; exit 1 ;;
    *)          TARGET_DIR="$arg" ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Usage: bash update.sh <target-project-dir> [--dry-run] [--prune]${NC}"
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
# Kept in a temp file because the update/cleanup loops would otherwise run in a
# pipeline subshell, where increments are discarded and every total reports 0.
COUNTER_FILE="$(mktemp)"
trap 'rm -f "$COUNTER_FILE"' EXIT
printf '0 0 0 0 0\n' > "$COUNTER_FILE"

bump() {
  local which="$1"
  local u a n r k
  read -r u a n r k < "$COUNTER_FILE"
  case "$which" in
    updated)   u=$((u + 1)) ;;
    added)     a=$((a + 1)) ;;
    unchanged) n=$((n + 1)) ;;
    removed)   r=$((r + 1)) ;;
    kept)      k=$((k + 1)) ;;
  esac
  printf '%s %s %s %s %s\n' "$u" "$a" "$n" "$r" "$k" > "$COUNTER_FILE"
}

# --- Helper: update a single file ---
update_file() {
  local src="$1"
  local dst="$2"

  if [ -f "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
    bump unchanged
    return
  fi

  if [ -f "$dst" ]; then
    [ "$DRY_RUN" = false ] && cp "$src" "$dst"
    echo -e "  ${BLUE}[update]${NC} $dst"
    bump updated
  else
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    fi
    echo -e "  ${GREEN}[new]${NC}    $dst"
    bump added
  fi
}

# --- Helper: install a project-owned file without ever clobbering it ---
# Copies only when the destination is absent. Once the project has edited it,
# the local version wins — these files carry hook wiring and ignore rules that
# a blind copy would silently destroy.
preserve_file() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$dst" ]; then
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    fi
    echo -e "  ${GREEN}[new]${NC}    $dst"
    bump added
    return
  fi

  if diff -q "$src" "$dst" &>/dev/null; then
    bump unchanged
    return
  fi

  echo -e "  ${YELLOW}[keep]${NC}   $dst — locally modified, left alone"
  echo -e "           review upstream changes with:"
  echo -e "           diff \"$src\" \"$dst\""
  bump kept
}

# --- Helper: update all files in a directory ---
update_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  while IFS= read -r src_file; do
    local rel_path="${src_file#$src_dir/}"
    update_file "$src_file" "$dst_dir/$rel_path"
  done < <(find "$src_dir" -type f | sort)
}

# --- Helper: remove files in target that no longer exist in templates ---
# Only runs under --prune. The criterion is "absent from the templates", which
# also matches skills, rules, hooks and agents the project wrote itself, so
# deleting them cannot be the default.
cleanup_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$dst_dir" ]; then
    return
  fi

  while IFS= read -r dst_file; do
    local rel_path="${dst_file#$dst_dir/}"
    local src_file="$src_dir/$rel_path"
    if [ ! -f "$src_file" ]; then
      if [ "$PRUNE" = true ]; then
        [ "$DRY_RUN" = false ] && rm "$dst_file"
        echo -e "  ${RED}[remove]${NC} $dst_file"
        bump removed
      else
        echo -e "  ${YELLOW}[extra]${NC}  $dst_file — not in templates, kept (use --prune to delete)"
        bump kept
      fi
    fi
  done < <(find "$dst_dir" -type f | sort)
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
if [ "$PRUNE" = true ]; then
  echo -e "Prune:      ${YELLOW}ON — files absent from templates will be deleted${NC}"
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
preserve_file "$TEMPLATE_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"

echo -e "${GREEN}[6/6] .claudeignore${NC}"
preserve_file "$TEMPLATE_DIR/.claudeignore" "$TARGET_DIR/.claudeignore"

# --- Skipped files ---
echo ""
echo -e "${YELLOW}Skipped (project-specific):${NC}"
echo "  CLAUDE.md"
echo "  docs/CURRENT_SPRINT.md"
echo "  docs/LINEAR_SNAPSHOT.md"
echo "  .claude/project.conf"

# --- Summary ---
read -r UPDATED ADDED UNCHANGED REMOVED KEPT < "$COUNTER_FILE"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Update complete                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Updated:   ${BLUE}$UPDATED${NC}"
echo -e "  New:       ${GREEN}$ADDED${NC}"
echo -e "  Removed:   ${RED}$REMOVED${NC}"
echo -e "  Kept:      ${YELLOW}$KEPT${NC}"
echo -e "  Unchanged: $UNCHANGED"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}This was a dry run. No files were changed.${NC}"
  echo -e "${YELLOW}Remove --dry-run to apply updates.${NC}"
fi
