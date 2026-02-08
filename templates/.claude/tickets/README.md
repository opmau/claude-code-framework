# Ticket System

Persistent task tracking that survives across Claude Code sessions.

## Why Tickets?

- `CURRENT_SPRINT.md` tracks the active phase, but individual tasks need more detail
- Tickets persist between sessions — Claude can pick up where it left off
- Structured format ensures acceptance criteria are clear before work starts

## Ticket Format

Each ticket is a markdown file in `.claude/tickets/`:

```
.claude/tickets/
├── README.md                              ← this file
├── ticket-list.md                         ← centralized index
├── TICKET-001-short-description.md        ← individual ticket
├── TICKET-002-another-task.md
└── ...
```

## File Naming

`TICKET-NNN-brief-description.md` (kebab-case, sequential numbering)

## Status Indicators

Use these in `ticket-list.md` and individual ticket headers:

| Emoji | Status | Meaning |
|-------|--------|---------|
| 🔴 | Todo | Not started |
| 🟡 | In Progress | Currently being worked on |
| 🟢 | Done | Completed and verified |
| 🔵 | Blocked | Waiting on something |
| ⚫ | Cancelled | No longer needed |

## Rules

1. Create a ticket BEFORE starting non-trivial work
2. Only ONE ticket should be 🟡 In Progress at a time
3. Update `ticket-list.md` when ticket status changes
4. Mark tickets 🟢 Done only when acceptance criteria are met
5. Never delete tickets — mark them ⚫ Cancelled with a reason
