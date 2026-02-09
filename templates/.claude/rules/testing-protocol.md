---
paths:
  - "src/**/*"
  - "tests/**/*"
---

# Testing Protocol

## When to Run Tests

Check the test mapping table in CLAUDE.md to determine which tests to run based on what you modified. When in doubt, run the full suite.

## Bug Handling

- During refactoring: DO NOT FIX bugs. Use `/document-bug` to create a Linear issue, continue working.
- During normal development: If a bug blocks your task, fix it. If unrelated, use `/document-bug` first.
- If a test fails: Use `/document-bug` to log it in Linear. Do NOT attempt on-the-fly fixes.

## Before Every Commit

1. Run the relevant test suite
2. If tests fail, do not commit
3. Log pre-existing failures using `/document-bug` if not already tracked in Linear
