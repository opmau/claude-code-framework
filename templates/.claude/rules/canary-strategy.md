# Canary Strategy for Cross-Cutting Changes

When a change affects multiple files with the same pattern (rename, refactor, dependency upgrade, migration), use a canary approach to de-risk it.

## The Rule

For any change that will touch **3+ files with the same transformation**:

1. **Apply to ONE file first** — pick a representative file (not the simplest, not the most complex)
2. **Run the full test suite** — verify nothing breaks
3. **Review the diff** — is the pattern right? Any edge cases?
4. **Only then apply to remaining files** — now that the pattern is proven

## Why This Matters

- A wrong pattern applied to 1 file is a quick revert. Applied to 20 files, it's a painful cleanup.
- The first file often reveals edge cases (imports, naming conflicts, test updates) that change the approach.
- Reviewing 1 diff is easy. Reviewing 20 identical diffs after the fact catches nothing.

## Examples

| Change Type | Canary Target | What to Verify |
|------------|---------------|----------------|
| Rename function across codebase | File with the most call sites | All callers updated, tests pass |
| Migrate API v1 → v2 | An endpoint with typical complexity | Request/response shapes, error handling |
| Update import paths after restructure | File that imports from multiple moved modules | All paths resolve, no circular deps |
| Add error handling pattern | A module with mixed success/error paths | Both paths work, no swallowed errors |

## When to Skip the Canary

- Change touches only 1-2 files (just do it)
- Automated tooling handles the transformation (e.g., IDE rename refactor with full test run)
- The change is purely additive (new files, no modifications to existing)
