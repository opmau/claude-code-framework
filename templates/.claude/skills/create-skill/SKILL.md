---
name: create-skill
description: Create a new Claude Code skill from a description. Use when the user says "create skill", "new skill", or "add a slash command".
argument-hint: "<skill-name>"
user-invocable: true
allowed-tools: Read, Write, Glob
model: sonnet
---

# /create-skill — Generate a new skill

Create a new skill (slash command) following the framework's conventions.

## Steps

1. If `$ARGUMENTS` is empty, ask the user for:
   - Skill name (lowercase, hyphenated)
   - What the skill should do (one sentence)
   - When it should trigger (what the user would say)

2. Read an existing skill for reference patterns:
   ```
   .claude/skills/review/SKILL.md
   ```

3. Generate the skill file following this structure:
   ```yaml
   ---
   name: <skill-name>
   description: <what it does>. Use when the user says "<trigger phrases>".
   argument-hint: "<hint>"
   user-invocable: true
   allowed-tools: <minimal set needed>
   model: <haiku for simple, sonnet for complex>
   ---
   ```

   Body structure:
   ```markdown
   # /<skill-name> — <one-line description>

   <What this skill does, in one sentence.>

   ## Steps

   1. <first action>
   2. <second action>
   3. <report results in specific format>

   ## Arguments

   - No arguments: <default behavior>
   - `$ARGUMENTS`: <behavior with arguments>

   ## Notes

   - <important constraint 1>
   - <important constraint 2>
   ```

4. Write the skill to `.claude/skills/<skill-name>/SKILL.md`

5. Report what was created:
   ```
   Created: .claude/skills/<skill-name>/SKILL.md
   Trigger: /<skill-name>
   Description: <what it does>
   ```

## Guidelines

- **Context efficiency:** Keep skills under 100 lines. The context window is a shared resource.
- **Model selection:** Use `haiku` for simple tasks (build, test, file checks). Use `sonnet` for tasks requiring analysis (review, planning).
- **Tool minimization:** Only include tools the skill actually needs in `allowed-tools`.
- **No side effects:** Skills should report findings — not silently make changes unless that's their explicit purpose.
- **Follow conventions:** Match the tone and format of existing skills in the project.
