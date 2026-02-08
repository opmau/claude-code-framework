---
name: create-pr
description: Create a pull request with a structured description. Use when the user says "create pr", "open pr", or "pull request".
argument-hint: "[base-branch]"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
model: sonnet
---

# /create-pr — Create a structured pull request

Create a well-formatted PR from the current branch.

## Steps

1. Gather context:
   ```bash
   git branch --show-current
   git log --oneline main..HEAD    # or dev..HEAD depending on base
   git diff main..HEAD --stat      # summary of all changes
   ```

2. If `$ARGUMENTS` is provided, use it as the base branch. Otherwise, determine the base branch from CLAUDE.md Production Protection section (typically `dev` or `main`).

3. Analyze ALL commits in the branch (not just the latest) to understand the full scope of changes.

4. Generate PR content:
   - **Title:** conventional commit format, under 70 characters
   - **Summary:** 1-3 bullet points covering the key changes
   - **Test plan:** checklist of what should be tested

5. Show the proposed PR to the user for approval before creating it.

6. Push and create the PR:
   ```bash
   git push -u origin $(git branch --show-current)
   ```
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   - <bullet 1>
   - <bullet 2>

   ## Changes
   - <file/module>: <what changed>

   ## Test Plan
   - [ ] <test step 1>
   - [ ] <test step 2>
   EOF
   )"
   ```

7. Return the PR URL.

## Notes

- Analyze ALL commits, not just the most recent
- Keep the title short — use the body for details
- Always push with `-u` flag to set upstream tracking
- Get user confirmation before creating the PR
