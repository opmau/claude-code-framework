---
name: commit
description: Generate a conventional commit for staged changes. Use when the user says "commit", "save changes", or "commit this".
argument-hint: "[commit message override]"
user-invocable: true
allowed-tools: Bash, Read, Grep
model: haiku
---

# /commit — Generate conventional commit

Create a well-structured commit from staged (and optionally unstaged) changes.

## Steps

1. Check the current state:
   ```
   git status
   git diff --cached --stat
   git diff --stat
   ```

2. If nothing is staged, ask the user what to stage. Do NOT run `git add -A` automatically.

3. Analyze the staged diff:
   ```
   git diff --cached
   ```

4. Determine the commit type from the changes:
   - `feat:` — new functionality
   - `fix:` — bug fix
   - `refactor:` — code restructuring without behavior change
   - `test:` — adding or updating tests
   - `docs:` — documentation changes
   - `chore:` — build, config, dependency changes
   - `perf:` — performance improvement

5. Generate a commit message following this format:
   ```
   <type>(<scope>): <subject>

   [optional body — what and why, not how]
   ```
   Rules:
   - Subject line: imperative mood, no period, under 50 characters
   - Scope: the module or area changed (e.g., `auth`, `api`, `config`)
   - Body: wrap at 72 characters, explain WHY not WHAT

6. If `$ARGUMENTS` is provided, use it as the commit message instead of generating one.

7. Show the proposed commit message to the user and ask for confirmation before committing.

8. Create the commit using a HEREDOC:
   ```bash
   git commit -m "$(cat <<'EOF'
   <the commit message>
   EOF
   )"
   ```

## Notes

- NEVER use `git add -A` or `git add .` — always stage specific files
- NEVER use `--no-verify` — let pre-commit hooks run
- If the commit fails due to a pre-commit hook, report the failure — do NOT retry with `--no-verify`
- Show the message and get confirmation before committing
