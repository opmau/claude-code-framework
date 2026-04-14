# Claude Code Project Framework

A project framework for Claude Code that enforces engineering discipline, prevents common AI agent failure modes, and builds continuous improvement into your workflow.

## What This Is

A complete set of templates for configuring Claude Code as a **rigorous engineering partner** rather than a compliant assistant. Includes:

- **CLAUDE.md template** — Project rules, architecture constraints, agent behavior rules with auto-generated section markers
- **Skills** — 20 slash commands: 15 core (`/build`, `/test`, `/review`, `/check-sizes`, `/retro`, `/commit`, `/create-pr`, `/create-ticket`, `/create-skill`, `/document-bug`, `/session-mode`, `/diagnose`, `/fix-issue`, `/smoke-test`) + 5 Linear integration (`/linear-sync`, `/linear-create`, `/linear-triage`, `/linear-sprint`, `/linear-update`)
- **Hooks** — 5 automated enforcement hooks + optional [tdd-guard](https://github.com/nizos/tdd-guard) TDD enforcement (file size limits, scope warnings, pre-commit verification, rule persistence through context compression)
- **Rules** — 10 modular, path-scoped rule files (anti-sycophancy, scope guardrails, feedback loops, anti-patterns, canary strategy, trust levels, complexity budget)
- **Agents** — 5 specialized subagents with persistent memory (code reviewer, planner, QA tester, domain expert, Linear PM)
- **Ticket system** — Persistent task tracking across sessions with structured templates
- **Issue tracking** — Linear as single source of truth with local snapshot cache (`docs/LINEAR_SNAPSHOT.md`)
- **Setup tooling** — Automated setup and update scripts, comment stripping for production, `.claudeignore` template

## Why This Exists

Every rule in this framework exists because of a specific failure mode observed in production use of AI coding agents. These are not theoretical — they address real categories of problems that occur when LLM agents operate without structured constraints.

| Rule | Failure Mode It Prevents |
|------|--------------------------|
| File size limits | Large files exhaust context windows, degrading reasoning quality and causing hallucinations |
| Anti-sycophancy rules | Agent agrees with incorrect approaches instead of pushing back, compounding errors |
| Evidence-based claims | Agent asserts code exists or behaves a certain way without verification, wasting debugging time |
| Max fix attempts | Unbounded fix-retry loops where each attempt introduces new regressions |
| Scope guardrails | Uncontrolled scope expansion — a single bug fix becomes a multi-file refactor with cascading breakage |
| Feedback loop | Hard-won knowledge is lost between sessions, causing the same mistakes to be repeated |
| PreCompact hook | Critical rules are dropped during context compression, effectively removing constraints mid-session |
| Diagnosis rules | Speculative fixes applied without evidence, masking root causes or introducing new failures |
| Session modes | Behavioral constraints stated early in a session are forgotten as context grows |
| Pre-commit hook | Code committed without build or test verification, shipping broken artifacts |

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

**Updating an existing project:**

```bash
# Pull latest framework changes without overwriting your CLAUDE.md, docs/, or tickets/
bash claude-code-framework/bin/update.sh /path/to/your-project

# Preview what would change first
bash claude-code-framework/bin/update.sh /path/to/your-project --dry-run
```

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

## Updating Existing Projects

When the framework gets new skills, bug fixes, or rule improvements, update your project:

```bash
# Preview what would change
bash claude-code-framework/bin/update.sh /path/to/your-project --dry-run

# Apply updates
bash claude-code-framework/bin/update.sh /path/to/your-project
```

The update script overwrites **framework files only** (skills, rules, hooks, agents, settings) and never touches your project-specific files (`CLAUDE.md`, `docs/`, `.linear.toml`). It also removes skills or rules that were deleted from the framework.

## What's Included

```
bin/
├── setup.sh                            # Automated project setup script
├── update.sh                           # Update framework files in existing projects
└── strip-comments.sh                   # Strip coaching comments for production

templates/
├── CLAUDE.md                           # Main agent rules template
├── .claudeignore                       # Files Claude should skip
├── docs/
│   ├── CURRENT_SPRINT.md              # Sprint state template
│   └── LINEAR_SNAPSHOT.md             # Auto-generated Linear cache
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
    │   ├── create-skill/SKILL.md       # /create-skill — generate new skills
    │   ├── document-bug/SKILL.md       # /document-bug — log bugs in Linear
    │   ├── session-mode/SKILL.md       # /session-mode — set session constraints
    │   ├── diagnose/SKILL.md           # /diagnose — structured bug investigation
    │   ├── fix-issue/SKILL.md          # /fix-issue — fix tracked Linear issues
    │   ├── smoke-test/SKILL.md         # /smoke-test — integration test log triage
    │   ├── create-ticket/SKILL.md      # /create-ticket — local task tracking
    │   ├── linear-create/SKILL.md      # /linear-create — create Linear issues
    │   ├── linear-sync/SKILL.md        # /linear-sync — generate local snapshot
    │   ├── linear-triage/SKILL.md      # /linear-triage — triage and groom issues
    │   ├── linear-sprint/SKILL.md      # /linear-sprint — sprint/cycle management
    │   └── linear-update/SKILL.md      # /linear-update — update issue status
    ├── hooks/
    │   ├── check-file-size.sh          # Warns when files exceed size limits
    │   ├── check-scope.sh              # Warns when editing out-of-scope files + session mode
    │   ├── pre-commit-check.sh         # Warns when committing without build/test
    │   ├── inject-critical-rules.sh    # Preserves rules through context compression
    │   └── session-check.sh            # Periodic feedback loop reminder
    │   # + tdd-guard hooks (optional, pre-configured in settings.local.json)
    ├── tdd-guard/                      # TDD enforcement templates (optional)
    │   ├── data/instructions.md        # Project-specific test instructions
    │   └── reporters/generic-reporter.sh  # Test output → TDD Guard JSON
    ├── rules/
    │   ├── agent-behavior.md           # Anti-sycophancy, evidence rules
    │   ├── scope-guardrails.md         # Change scope limits
    │   ├── file-size-limits.md         # Size limits (path-scoped to src/)
    │   ├── testing-protocol.md         # Test mapping, bug handling
    │   ├── linear-workflow.md          # Linear integration rules
    │   ├── feedback-loop.md            # Post-session review triggers
    │   ├── anti-patterns.md            # Explicit "don't do this" registry
    │   ├── canary-strategy.md          # De-risk cross-cutting changes
    │   ├── trust-levels.md             # Progressive autonomy by module risk
    │   └── complexity-budget.md        # Code health thresholds
    ├── agents/
    │   ├── code-reviewer.md            # Pre-commit reviewer with memory
    │   ├── planner.md                  # Task planning and breakdown
    │   ├── qa-tester.md                # Test writing and QA
    │   ├── domain-expert.md            # Domain specialist with memory
    │   └── linear-pm.md               # Linear PM — sprint planning, health checks
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

- `/session-mode debug` — focused bug fixing, no refactoring
- `/session-mode refactor` — restructure code, document bugs found but don't fix them
- `/session-mode feature` — build new functionality with a plan

### Structured Bug Workflow

Complete lifecycle from discovery to fix:

- `/document-bug` — log bugs as Linear issues without touching source code
- `/diagnose` — structured differential diagnosis with multiple hypotheses
- `/fix-issue` — pick a tracked bug, fix it, verify, update issue tracking
- `/smoke-test` — analyze integration test logs, classify failures by severity, batch-create issues

### Automated Enforcement via Hooks

Rules aren't just documented — they're enforced automatically:

- **PostToolUse** hook checks file size after every edit
- **PreToolUse** hook warns about out-of-scope changes and enforces session mode constraints
- **PreToolUse** hook warns when committing without running build/tests
- **PreCompact** hook re-injects critical rules (including diagnosis rules) before context compression
- **Stop** hook periodically reminds about documentation updates
- **Optional:** [tdd-guard](https://github.com/nizos/tdd-guard) hooks enforce TDD discipline automatically — blocks implementation code without failing tests, supports mid-session toggle (`tdd-guard on` / `tdd-guard off`). Pre-configured in `settings.local.json`; install with `npm install -g tdd-guard`

### Git Workflow Skills

Built-in slash commands for clean git workflows:

- `/commit` — generates conventional commit messages from staged changes
- `/create-pr` — creates PRs with structured summary, changes list, and test plan
- `/create-ticket` — tracks tasks persistently across sessions
- `/create-skill` — meta-skill to generate new custom skills
- `/linear-sync`, `/linear-create`, `/linear-triage`, `/linear-sprint`, `/linear-update` — full Linear issue tracking integration

### Integration Testing

- CLAUDE.md includes an **Integration Testing** section template for documenting smoke test commands and log interpretation
- `/smoke-test` skill analyzes integration test logs, diagnoses failures against source code, and batch-creates issues
- Integration test results feed into the structured bug workflow (`/document-bug` → `/fix-issue`)

### Specialized Agents

Five agents with persistent memory for different roles:

- **code-reviewer** — pre-commit review against CLAUDE.md rules (Opus)
- **planner** — breaks down complex tasks before implementation (Opus)
- **qa-tester** — writes tests, validates coverage, investigates failures (Opus)
- **domain-expert** — deep expertise for domain-specific debugging (Opus) — supports splitting into multiple domain experts
- **linear-pm** — sprint planning, velocity analysis, project health, release readiness (Opus)

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
