# Claude Code Project Framework

A project framework for Claude Code that enforces engineering discipline, prevents common AI agent failure modes, and builds continuous improvement into your workflow.

## What This Is

A complete set of templates for configuring Claude Code as a **rigorous engineering partner** rather than a compliant assistant. Includes:

- **CLAUDE.md template** — Project rules, architecture constraints, agent behavior rules with auto-generated section markers
- **Skills** — 13 slash commands (`/build`, `/test`, `/review`, `/check-sizes`, `/retro`, `/commit`, `/create-pr`, `/create-ticket`, `/create-skill`, `/document-bug`, `/session-mode`, `/diagnose`, `/fix-issue`)
- **Hooks** — 5 automated enforcement hooks (file size limits, scope warnings, pre-commit verification, rule persistence through context compression)
- **Rules** — Modular, path-scoped rule files (anti-sycophancy, scope guardrails, feedback loops)
- **Agents** — 4 specialized subagents with persistent memory (code reviewer, planner, QA tester, domain expert)
- **Ticket system** — Persistent task tracking across sessions with structured templates
- **Setup tooling** — Automated setup script, comment stripping for production, `.claudeignore` template
- **Companion docs** — KNOWN_ISSUES.md, CURRENT_SPRINT.md templates

## Why This Exists

These patterns were developed during a real production project (a financial trading plugin) where AI agent mistakes had real consequences. Every rule exists because of a specific failure:

| Rule | What Went Wrong Without It |
|------|---------------------------|
| File size limits | 2900-line file consumed the entire context window, Claude hallucinated |
| Anti-sycophancy rules | Claude agreed with a wrong fix that caused financial losses |
| Evidence-based claims | Claude claimed code existed that didn't, wasting hours debugging |
| Max 2 fix attempts | Claude made 5 failed fix attempts, each introducing new bugs |
| Scope guardrails | Asked to fix 1 bug, Claude refactored 8 files and broke 3 things |
| Feedback loop | Same gotcha was rediscovered 4 times across sessions |
| PreCompact hook | Critical rules were lost during context compression, Claude "forgot" constraints |
| Diagnosis rules | Speculative fix ignored log evidence, causing financial damage |
| Session modes | Constraint stated once was forgotten mid-session, causing scope violations |
| Pre-commit hook | Code committed without build/test verification, deploying broken artifacts |

## Quick Start

### 1. Copy into your project

```bash
# Clone this repo
git clone https://github.com/opmau/claude-code-framework.git

# Option A: Automated setup (recommended)
bash claude-code-framework/bin/setup.sh /path/to/your-project

# Option B: Manual copy
cp -r claude-code-framework/templates/.claude your-project/.claude
cp claude-code-framework/templates/CLAUDE.md your-project/CLAUDE.md
cp claude-code-framework/templates/.claudeignore your-project/.claudeignore
cp -r claude-code-framework/templates/docs your-project/docs
```

**Prerequisites (for hooks):** bash 4+, `jq`. On Windows, use Git Bash or WSL. See [Platform Notes](PROJECT_SETUP.md#platform-notes).

### 2. Bootstrap with Claude Code

Open Claude Code in your project and paste:

```
I'm setting up a new project with a CLAUDE.md framework. The template is
already in place at CLAUDE.md. Your job is to POPULATE it, not redesign it.

PROJECT CONTEXT:
- Project name: [your project name]
- Language: [e.g., Python 3.11, TypeScript, C++17]
- Build command: [e.g., npm run build]
- Test command: [e.g., pytest, npm test]

Read CLAUDE.md and replace [BRACKETED] placeholders with my project values.
DO NOT change the section order or remove any agent behavior rules.
Show me the changes before writing.
```

### 3. Verify

```
Read CLAUDE.md and answer:
1. If I proposed a fix and you thought it was wrong, what would you do?
2. If a file hit 450 lines, what would you do?
3. If your second fix attempt failed, what would you do?
```

See [PROJECT_SETUP.md](PROJECT_SETUP.md) for the full 11-step setup guide.

## What's Included

```
bin/
├── setup.sh                            # Automated project setup script
└── strip-comments.sh                   # Strip coaching comments for production

templates/
├── CLAUDE.md                           # Main agent rules template
├── .claudeignore                       # Files Claude should skip
├── docs/
│   ├── KNOWN_ISSUES.md                 # Bug tracking template
│   └── CURRENT_SPRINT.md               # Sprint state template
└── .claude/
    ├── settings.local.json             # Hook registration (pre-configured)
    ├── skills/
    │   ├── build/SKILL.md              # /build — compile and report
    │   ├── test/SKILL.md               # /test — run tests, parse results
    │   ├── review/SKILL.md             # /review — pre-commit code review
    │   ├── check-sizes/SKILL.md        # /check-sizes — audit file sizes
    │   ├── retro/SKILL.md              # /retro — session retrospective
    │   ├── commit/SKILL.md             # /commit — conventional commit generation
    │   ├── create-pr/SKILL.md          # /create-pr — structured PR creation
    │   ├── create-ticket/SKILL.md      # /create-ticket — task tracking
    │   ├── create-skill/SKILL.md       # /create-skill — generate new skills
    │   ├── document-bug/SKILL.md       # /document-bug — log bugs without fixing
    │   ├── session-mode/SKILL.md       # /session-mode — set session constraints
    │   ├── diagnose/SKILL.md           # /diagnose — structured bug investigation
    │   └── fix-issue/SKILL.md          # /fix-issue — fix tracked known issues
    ├── hooks/
    │   ├── check-file-size.sh          # Warns when files exceed size limits
    │   ├── check-scope.sh              # Warns when editing out-of-scope files + session mode
    │   ├── pre-commit-check.sh         # Warns when committing without build/test
    │   ├── inject-critical-rules.sh    # Preserves rules through context compression
    │   └── session-check.sh            # Periodic feedback loop reminder
    ├── rules/
    │   ├── agent-behavior.md           # Anti-sycophancy, evidence rules
    │   ├── scope-guardrails.md         # Change scope limits
    │   ├── file-size-limits.md         # Size limits (path-scoped to src/)
    │   ├── testing-protocol.md         # Test mapping, bug handling
    │   └── feedback-loop.md            # Post-session review triggers
    ├── agents/
    │   ├── code-reviewer.md            # Pre-commit reviewer with memory
    │   ├── planner.md                  # Task planning and breakdown
    │   ├── qa-tester.md                # Test writing and QA
    │   └── domain-expert.md            # Domain specialist with memory
    └── tickets/
        ├── README.md                   # Ticket system guide
        ├── ticket-list.md              # Centralized task index
        └── TICKET-000-template.md      # Ticket template
```

## Key Features

### Anti-Sycophancy Rules

Claude's default is to agree with users. In engineering, this creates blind spots. The framework explicitly instructs Claude to:

- Push back when it disagrees ("I'd push back on this because...")
- Propose better alternatives even when not asked
- Never agree just to be agreeable
- Re-check evidence when challenged instead of immediately conceding
- Follow user-provided log evidence before proposing its own theories
- Test multiple hypotheses before concluding on a root cause

### Session Modes

Lock sessions into specific operating modes to prevent drift:

- `/session-mode document-only` — audit and document, no source changes
- `/session-mode debug` — focused bug fixing, no refactoring
- `/session-mode refactor` — restructure code, document bugs found but don't fix them
- `/session-mode feature` — build new functionality with a plan
- `/session-mode review` — read-only code assessment

### Structured Bug Workflow

Complete lifecycle from discovery to fix:

- `/document-bug` — log bugs without touching source code (enforces "document, don't fix")
- `/diagnose` — structured differential diagnosis with multiple hypotheses
- `/fix-issue` — pick a tracked bug from KNOWN_ISSUES, fix it, verify, update docs

### Automated Enforcement via Hooks

Rules aren't just documented — they're enforced automatically:

- **PostToolUse** hook checks file size after every edit
- **PreToolUse** hook warns about out-of-scope changes and enforces session mode constraints
- **PreToolUse** hook warns when committing without running build/tests
- **PreCompact** hook re-injects critical rules (including diagnosis rules) before context compression
- **Stop** hook periodically reminds about documentation updates

### Git Workflow Skills

Built-in slash commands for clean git workflows:

- `/commit` — generates conventional commit messages from staged changes
- `/create-pr` — creates PRs with structured summary, changes list, and test plan
- `/create-ticket` — tracks tasks persistently across sessions
- `/create-skill` — meta-skill to generate new custom skills

### Specialized Agents

Four agents with persistent memory for different roles:

- **code-reviewer** — pre-commit review against CLAUDE.md rules (Haiku, fast)
- **planner** — breaks down complex tasks before implementation (Opus)
- **qa-tester** — writes tests, validates coverage, investigates failures (Sonnet)
- **domain-expert** — deep expertise for domain-specific debugging (Opus)

### Feedback Loop

The framework builds continuous improvement into every session:

- Post-session retrospectives via `/retro`
- Living documentation rules (Claude proposes updates to CLAUDE.md)
- Retrospective triggers for bugs, failed fixes, and incidents
- Agent memory persistence (all agents learn over time)

### File Size Limits as Agent Performance

File limits aren't just code quality — they're **agent performance optimization**:

- Smaller files = more context window for reasoning
- Smaller files = fewer ambiguous string matches for edits
- Smaller files = smaller blast radius from mistakes
- Language-specific calibration table included

## Customization

### Language Calibration

Adjust file size limits for your language:

| Language | Header/Interface | Implementation | Total |
|----------|------------------|----------------|-------|
| C/C++ | 150 | 400 | 500 |
| TypeScript | 100 | 300 | 400 |
| Python | N/A | 300 | 300 |
| Rust | N/A | 400 | 400 |
| Go | N/A | 400 | 400 |

### Removing Sections

Not every project needs every section. Safe to remove:

- **Production Protection** — if no production environment
- **File Header Template** — if your language/project doesn't use them

Never remove:

- **Agent Behavior Rules** — these prevent the most common AI failures
- **Feedback Loop** — this is how the system improves
- **Scope Guardrails** — this prevents Claude from making sweeping changes

### Context Window Optimization

Reduce CLAUDE.md from ~850 lines to ~400 lines after setup:

```bash
bash bin/strip-comments.sh CLAUDE.md --dry-run  # preview
bash bin/strip-comments.sh CLAUDE.md             # strip
```

Plus `.claudeignore` prevents Claude from reading build artifacts, dependencies, and binary files.

## Contributing

If you use this framework and discover improvements:

1. New steering phrases that work well for Claude Code
2. Hook scripts for additional enforcement
3. Skills for common workflows
4. Rules for specific languages/frameworks
5. Gotcha patterns that apply across projects

Open a PR or issue.

## License

MIT
