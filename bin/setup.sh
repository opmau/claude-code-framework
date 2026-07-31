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

# jq is a hard dependency of the hooks: they parse tool input with it and build
# their JSON output with it. Without jq the hooks exit 0 having done nothing, so
# the framework appears installed while enforcing none of its rules. Fail loudly
# here rather than silently no-op on every edit forever after.
if [ "$INSTALL_HOOKS" = true ] && ! command -v jq >/dev/null 2>&1; then
  echo -e "${RED}ERROR: jq is required by the hooks and was not found on PATH.${NC}"
  echo "  Without it the hooks silently do nothing."
  echo ""
  echo "  macOS:         brew install jq"
  echo "  Debian/Ubuntu: sudo apt install jq"
  echo "  Windows:       download jq.exe and put it on PATH (see PROJECT_SETUP.md)"
  echo ""
  echo "  Or re-run with --no-hooks to install everything else."
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

# Install .claude/project.conf — the project-local configuration file that
# bin/update.sh never touches. Deliberately does NOT honour --force: this file
# is project-owned state, not framework content, so overwriting it would throw
# away exactly the customization it exists to protect.
install_project_conf() {
  local target="$1"
  local dst="$target/.claude/project.conf"

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${BLUE}[dry-run]${NC} $dst"
    return
  fi

  if [ -f "$dst" ]; then
    echo -e "  ${YELLOW}[exists]${NC} $dst — preserved (project-owned, never overwritten)"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$TEMPLATE_DIR/.claude/project.conf.example" "$dst"
  echo -e "  ${GREEN}[created]${NC} $dst"
}

# Set KEY=VALUE in a project.conf. Replaces the shipped commented-out default,
# or appends if the key is absent entirely.
#
# A key the project has ALREADY set is left alone unless --force: project.conf
# is project-owned, and silently rewriting a deliberate value would undo the
# customization this file exists to protect.
set_conf_value() {
  local file="$1"
  local key="$2"
  local value="$3"

  if [ "$DRY_RUN" = true ] || [ ! -f "$file" ]; then
    return
  fi

  if grep -q "^[[:space:]]*${key}=" "$file" && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}[skip]${NC}  ${key} already set in project.conf — use --force to recalibrate"
    return
  fi

  if grep -q "^[[:space:]]*#\{0,1\}[[:space:]]*${key}=" "$file"; then
    # 0,/re/ so only the FIRST occurrence is rewritten.
    inplace_sed "1,/^[[:space:]]*#\{0,1\}[[:space:]]*${key}=/s|^[[:space:]]*#\{0,1\}[[:space:]]*${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

# Apply language calibration to .claude/project.conf and the CLAUDE.md File
# Size Limits table. Idempotent — re-running with a different language
# overwrites cleanly.
#
# Writes to project.conf rather than patching the hook script directly:
# bin/update.sh copies hooks over wholesale, so hook-level calibration was
# silently reverted by the next framework update.
apply_language_calibration() {
  local lang="$1"
  local target="$2"
  local conf="$target/.claude/project.conf"
  local claude_md="$target/CLAUDE.md"

  # Per-language calibration. Header limit is "N/A" for languages without
  # separate header/interface files; we still set the hook constant equal
  # to the impl limit so any extension that *would* match (none for these
  # langs) gets the impl limit. The table value is the human-facing one.
  # t_table is the CLAUDE.md "Total per module" row, which /check-sizes reads;
  # there is no corresponding hook constant.
  local h_hook i_hook h_table i_table t_table label
  case "$lang" in
    python)     h_hook=300; i_hook=300; h_table="N/A"; i_table=300; t_table=300; label="Python";;
    cpp)        h_hook=150; i_hook=400; h_table=150;   i_table=400; t_table=500; label="C/C++";;
    typescript) h_hook=100; i_hook=300; h_table=100;   i_table=300; t_table=400; label="TypeScript";;
    rust)       h_hook=400; i_hook=400; h_table="N/A"; i_table=400; t_table=400; label="Rust";;
    go)         h_hook=400; i_hook=400; h_table="N/A"; i_table=400; t_table=400; label="Go";;
    *) return ;;
  esac

  # 1. Write the limits into project.conf, which survives framework updates.
  #    Covers the --no-hooks case, where step [4/7] never ran.
  [ -f "$conf" ] || install_project_conf "$target"
  set_conf_value "$conf" HEADER_LIMIT "$h_hook"
  set_conf_value "$conf" IMPL_LIMIT   "$i_hook"

  # 2. Patch the CLAUDE.md File Size Limits table.
  #    Matched by ROW LABEL rather than by the pristine [150]/[400]/[500]
  #    placeholders: those are consumed by the first calibration, so a
  #    placeholder-based substitution silently no-ops on every later run.
  #    Anchoring to the row keeps --language re-runnable.
  #    # is the s-command delimiter so values containing / (e.g. N/A) are safe.
  if [ -f "$claude_md" ]; then
    inplace_sed "s#^\(| Header / interface files *|\)[^|]*#\1 $h_table lines #" "$claude_md"
    inplace_sed "s#^\(| Implementation files *|\)[^|]*#\1 $i_table lines #" "$claude_md"
    inplace_sed "s#^\(| Total per module[^|]*|\)[^|]*#\1 $t_table lines #" "$claude_md"
  fi

  echo -e "  ${GREEN}[calibrated]${NC} $label — CLAUDE.md File Size Limits set to header/$h_table, impl/$i_table, total/$t_table (any [skip] above means project.conf kept your value)"
}

copy_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$src_dir" ]; then
    return
  fi

  find "$src_dir" -type f | while read -r src_file; do
    # The pattern operand must be quoted: unquoted, glob metacharacters in the
    # path (notably [ and ]) are parsed as a character class and the prefix
    # strip silently no-ops, scattering copies into an absolute-path tree.
    local rel_path="${src_file#"$src_dir"/}"
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
  # The /create-ticket skill reads and writes .claude/tickets/. Installing the
  # skill without its backing directory leaves it failing at step one, which
  # matters for projects that do not use Linear.
  copy_dir "$TEMPLATE_DIR/.claude/tickets" "$TARGET_DIR/.claude/tickets"
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
  # Project-local hook configuration (never overwritten by setup or update)
  install_project_conf "$TARGET_DIR"
  # tdd-guard support files. settings.local.json wires four tdd-guard hook
  # entries, and the reporter is what turns a test run into the JSON they
  # consume — shipping the wiring without these leaves the feature unusable.
  copy_dir "$TEMPLATE_DIR/.claude/tdd-guard" "$TARGET_DIR/.claude/tdd-guard"
  if [ "$DRY_RUN" = false ] && [ -d "$TARGET_DIR/.claude/tdd-guard/reporters" ]; then
    find "$TARGET_DIR/.claude/tdd-guard/reporters" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  fi
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
  echo "  4. Set hook limits and ALLOWED_DIRS in .claude/project.conf"
  echo "     (or re-run with --language python|cpp|typescript|rust|go to auto-calibrate)"
else
  echo "  4. Hook limits auto-calibrated for $LANGUAGE — review .claude/project.conf"
fi
echo "     Customize the framework there, never by editing .claude/hooks/ —"
echo "     the updater overwrites hooks but never touches project.conf."
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
