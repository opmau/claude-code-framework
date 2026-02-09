---
name: session-mode
description: Set the operating mode for the current session. Use when the user says "session mode", "set mode", "refactor mode", "debug mode", or "feature mode".
argument-hint: "<mode name>"
user-invocable: true
allowed-tools: Read, Write, Glob
model: haiku
---

# /session-mode — Set session operating mode

Lock the current session into a specific operating mode with enforced constraints. This prevents drift by front-loading the rules at the start of a session.

## Available Modes

### `debug`
- **Purpose:** Find and fix a specific bug
- **Allowed edits:** Files directly related to the bug (max 3 files)
- **Required:** Quote log evidence before any fix. Run tests after every change.
- **Forbidden:** Refactoring, feature work, "while I'm here" improvements
- **Use when:** A specific bug needs to be fixed

### `refactor`
- **Purpose:** Restructure code without changing behavior
- **Allowed edits:** Files in the refactoring plan (max 10 files)
- **Required:** Tests must pass before AND after. Document any bugs found (use `/document-bug`), don't fix them.
- **Forbidden:** Bug fixes, new features, behavior changes
- **Use when:** Splitting files, moving code between layers, renaming

### `feature`
- **Purpose:** Add new functionality
- **Allowed edits:** Files in the feature plan (3-5 files) + new files
- **Required:** Plan approved before coding. Tests for new code.
- **Forbidden:** Unrelated refactoring, fixing pre-existing bugs
- **Use when:** Building new capabilities

## Steps

1. If `$ARGUMENTS` is provided, use it as the mode name. Otherwise, list available modes and ask the user to choose.

2. Validate the mode name against the available modes above.

3. Write the active session mode to `docs/CURRENT_SPRINT.md` under a `### Active Session Mode` heading:
   ```markdown
   ### Active Session Mode
   - **Mode:** [mode name]
   - **Set at:** [timestamp]
   - **Constraints:** [key constraints from the mode definition]
   - **Scope:** [files/directories in scope, if specified by user]
   ```

4. Report the mode activation:
   ```
   Session mode: [MODE NAME]

   Constraints active:
   - [constraint 1]
   - [constraint 2]
   - [constraint 3]

   I will follow these constraints for the rest of this session.
   To change modes, run /session-mode again.
   ```

## Notes

- Only one mode can be active at a time
- Mode constraints supplement (don't replace) CLAUDE.md rules
- If the user asks for something that violates the active mode, remind them of the constraint and ask if they want to switch modes
- The mode persists until explicitly changed or the session ends
- For read-only code review, use the `/review` skill directly — no session mode needed
