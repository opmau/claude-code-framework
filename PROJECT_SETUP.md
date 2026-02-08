# New Project Setup Guide

How to bootstrap a new project with Claude Code using the CLAUDE.md template system.

---

## Overview

This guide ensures every new project starts with:
- A properly customized `CLAUDE.md` (not rewritten from scratch)
- Companion docs (`KNOWN_ISSUES.md`, `CURRENT_SPRINT.md`)
- Skills (slash commands) for common workflows (`/build`, `/test`, `/review`, `/commit`, `/create-pr`, etc.)
- Hooks for automated rule enforcement
- Modular rules for path-scoped constraints
- Agents with persistent memory (code-reviewer, planner, qa-tester, domain-expert)
- Ticket system for persistent task tracking across sessions
- `.claudeignore` for context window optimization
- Claude Code that understands and respects the framework

**The key principle:** Claude should POPULATE the template, not REDESIGN it.

---

## Step 1: Copy Template Files

### Option A: Automated Setup (Recommended)

Run the setup script from the framework root:

```bash
bash bin/setup.sh /path/to/your-new-project
```

Options:
- `--dry-run` — preview what would be copied
- `--force` — overwrite existing files
- `--no-hooks` — skip hooks
- `--no-agents` — skip agents
- `--no-skills` — skip skills
- `--no-rules` — skip rules
- `--no-tickets` — skip ticket system
- `--no-docs` — skip companion docs

**Prerequisites (for hooks):** bash 4+, `jq`. On Windows, use Git Bash or WSL.

### Option B: Manual Copy

See the full file listing in the [README](README.md#whats-included).

---

## Step 2: Bootstrap Prompt

Open Claude Code in your new project directory and paste this prompt.
Adjust the project details in the `PROJECT CONTEXT` section before pasting.

```
I'm setting up a new project with a CLAUDE.md framework. The template is
already in place at CLAUDE.md. Your job is to POPULATE it, not redesign it.

PROJECT CONTEXT:
- Project name: [your project name]
- What it does: [one sentence]
- Language: [e.g., Python 3.11, TypeScript, C++17]
- Build system: [e.g., npm, cargo, cmake, poetry]
- Build command: [e.g., npm run build]
- Test command: [e.g., pytest, npm test]
- Lint command: [e.g., eslint ., ruff check .]
- Entry point: [e.g., src/main.ts, src/app.py]
- Key dependencies: [list 3-5 main ones]
- Has production environment: [yes/no]
- If yes, production artifact: [e.g., Docker image, DLL, npm package]
- Branch strategy: [e.g., main/dev, main only, trunk-based]

INSTRUCTIONS:
1. Read the current CLAUDE.md template, including ALL HTML comments
2. Replace every [BRACKETED] placeholder with the project values above
3. Delete sections marked "delete if not applicable" that don't apply
4. Keep ALL HTML coaching comments — I'll decide when to remove them later
5. DO NOT change the section order
6. DO NOT remove any agent behavior rules, guardrails, or feedback loop sections
7. DO NOT add new sections — the template is complete
8. For the Architecture section: analyze my project's directory structure,
   then fill in the layer diagram to match what actually exists
9. For Domain Knowledge & Gotchas: leave the template placeholder for now,
   we'll populate this as we discover gotchas during development
10. For Directory Structure: fill it in based on what actually exists on disk

After populating CLAUDE.md, also populate:
- docs/KNOWN_ISSUES.md — just fill in the project name, keep the template
- docs/CURRENT_SPRINT.md — fill in the project name and current branch

Show me the changes you plan to make BEFORE writing any files.
Present as a checklist so I can approve or adjust.
```

---

## Step 3: Review Claude's Proposed Changes

Claude should present a checklist like:

```
Proposed CLAUDE.md customizations:
- [ ] Project Overview: filled with [your values]
- [ ] Architecture: [2/3/4] layers identified based on src/ structure
- [ ] File Size Limits: using [language] calibration from template
- [ ] Testing Protocol: mapped [test framework] commands
- [ ] Production Protection: [included/removed] based on your answer
- [ ] Branch Strategy: [your strategy]
- [ ] Sections removed: [list any deleted sections]
- [ ] Sections unchanged: Agent Behavior Rules, Feedback Loop, User Prompts
```

**Red flags to watch for** (reject and correct if you see these):
- Claude proposes removing the anti-sycophancy rules ("not needed for this project")
- Claude proposes merging sections ("I'll combine these for brevity")
- Claude proposes reordering sections ("I think Architecture should come first")
- Claude proposes rewriting rules in its own words instead of using the template text
- Claude adds large new sections not in the template

---

## Step 4: Architecture Discovery

For existing codebases, ask Claude to analyze the structure:

```
Analyze my project's directory structure and dependency graph.
Map what you find to the layer diagram in CLAUDE.md.

For each file/directory, tell me:
1. Which layer it belongs to (Foundation/Transport/Services/API)
2. What it depends on
3. Any dependency violations you see

Don't change anything yet — just present your analysis.
```

For new (greenfield) projects, fill in the architecture section yourself
based on your intended design, then tell Claude:

```
I've filled in the Architecture section with my intended design.
Read it and confirm you understand the layer rules. Then tell me
if you see any ambiguities I should clarify.
```

---

## Step 5: Configure Skills

Customize each skill for your project:

```
Read each SKILL.md in .claude/skills/ and update:

1. build/SKILL.md — replace [YOUR BUILD COMMAND] with our actual build command
2. test/SKILL.md — replace [YOUR FULL TEST COMMAND] and [YOUR SPECIFIC TEST COMMAND]
3. review/SKILL.md — no changes needed (uses generic CLAUDE.md rules)
4. check-sizes/SKILL.md — no changes needed (reads limits from CLAUDE.md)
5. retro/SKILL.md — no changes needed (reads rules from CLAUDE.md)
6. commit/SKILL.md — no changes needed (generates conventional commits)
7. create-pr/SKILL.md — no changes needed (reads branch strategy from CLAUDE.md)
8. create-ticket/SKILL.md — no changes needed (uses ticket templates)
9. create-skill/SKILL.md — no changes needed (meta-skill for creating new skills)

Show me the changes before writing.
```

Verify skills work by typing `/build` and `/test` in Claude Code.

---

## Step 6: Configure Hooks

The setup script (or manual copy) already installs `.claude/settings.local.json` with hooks pre-registered. Just customize the scripts:

```
Read .claude/hooks/ and customize:

1. check-scope.sh — update ALLOWED_DIRS for our project structure
2. check-file-size.sh — update HEADER_LIMIT, IMPL_LIMIT, TOTAL_LIMIT
   for our language (use the calibration table in CLAUDE.md)
3. inject-critical-rules.sh — review the critical rules list
4. session-check.sh — no changes needed

Make the hook scripts executable: chmod +x .claude/hooks/*.sh
Show me the changes before writing.
```

**Verify hooks work:**
- Edit a file → should see size check output
- Edit a file outside src/ → should see scope warning

---

## Step 7: Configure Agents

Customize the agents for your domain:

```
Read .claude/agents/ and customize:

1. code-reviewer.md — Replace [Project Name], update review checklist
2. planner.md — Replace [Project Name]
3. qa-tester.md — Replace [Project Name], update test conventions
4. domain-expert.md — Rename to [your-domain]-expert.md, fill in
   domain-specific topics and reference material

Keep the memory: project setting on all agents — this lets them learn over time.

Show me the changes before writing.
```

---

## Step 8: Install Git Hooks

```bash
# If your project has a pre-commit hook script:
cd scripts && ./install_hooks.sh

# Or create a simple one:
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running tests before commit..."
[YOUR TEST COMMAND]
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit blocked."
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

---

## Step 9: Verify Setup

After all configuration is done, verify with this prompt:

```
Read CLAUDE.md, .claude/rules/, and .claude/skills/ and answer:

1. If I asked you to add a utility function, which layer would you put it in?
2. If you discovered a bug while working on something else, what would you do?
3. If I proposed a fix and you thought it was wrong, what would you do?
4. If a file hit 450 lines, what would you do?
5. What should you do at the end of a work session?
6. If your second fix attempt failed, what would you do?
7. What slash commands are available and what do they do?
8. What hooks are active and what do they enforce?
9. How do you create a ticket for tracking work?
10. What agents are available and when should each be used?

Answers should come from project config, not general knowledge.
```

If Claude can't answer all 10, the setup is incomplete.

---

## Step 10: First Session Workflow

For the first real work session on the new project:

```
Before we start coding, let's establish baselines:

1. Run /build and confirm it works
2. Run /test and confirm it works
3. Run /check-sizes and confirm all files are within limits
4. Note the current test count/coverage in CURRENT_SPRINT.md
5. Identify any existing gotchas and add them to Domain Knowledge

Then we'll start on: [your first task]
```

---

## Step 11: Strip Coaching Comments (Optional)

After setup is complete and you're comfortable with the template, strip the
HTML coaching comments to reduce CLAUDE.md size for production use:

```bash
# Preview what would be removed
bash bin/strip-comments.sh CLAUDE.md --dry-run

# Strip comments (typically ~850 lines → ~400 lines)
bash bin/strip-comments.sh CLAUDE.md
```

This preserves all rules, auto-generated markers, and template metadata while
removing the setup-phase coaching comments. The savings are significant — fewer
tokens loaded per session means more context window for reasoning.

---

## Anti-Patterns to Avoid

### DON'T: Let Claude create CLAUDE.md from scratch

```
❌ "Create a CLAUDE.md for my project"
```

This gives Claude a blank canvas. It will produce something reasonable
but miss the battle-tested rules (anti-sycophancy, feedback loops,
scope guardrails, splitting strategies) that took months to develop.

### DO: Have Claude populate the template

```
✅ "The CLAUDE.md template is already in place. Read it and populate
    the placeholders for my Python web API project."
```

### DON'T: Let Claude "improve" the template structure

```
❌ "This template is long — can you streamline it?"
```

The length is intentional. The HTML comments are coaching notes for
future customization. The repetition between sections is a feature
(Claude re-reads CLAUDE.md every session — redundancy helps).

### DO: Remove what doesn't apply, keep what does

```
✅ "Remove the Production Protection section — this is a personal
    project with no production environment. Keep everything else."
```

### DON'T: Skip the verification step

Even after perfect setup, verify Claude internalized the rules.
The verification prompt in Step 5 takes 30 seconds and catches
misconfigurations that would cost hours later.

---

## Template Maintenance

### When to update the master template

After using the framework across 2-3 projects, you'll discover:
- Rules that always get deleted (→ make them optional in the template)
- Rules that always get added (→ add them to the template)
- Phrases that work well for steering Claude (→ add to User Prompts)
- Gotchas that apply to multiple projects (→ add to Domain Knowledge examples)

Update the master templates in `docs/templates/` based on these patterns.

### Template versioning

The template has a version comment at the top:
```
<!-- Template version: 2.0 -->
```

Bump this when you make significant changes. This helps you track
which projects are using which version of the framework.

---

## Platform Notes

### Windows

The hooks require bash and `jq`. On Windows, you have two options:

1. **Git Bash (recommended):** Installed with Git for Windows. Hooks work as-is.
2. **WSL:** Run Claude Code from a WSL terminal.

Install `jq`:
- Git Bash: download `jq.exe` from https://jqlang.github.io/jq/download/ and add to PATH
- WSL: `sudo apt install jq`

### macOS

```bash
# Install jq if not present
brew install jq
```

### Linux

```bash
# Debian/Ubuntu
sudo apt install jq

# Fedora
sudo dnf install jq
```
