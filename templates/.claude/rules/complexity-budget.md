# Complexity Budget — Code Health Metrics

Measurable thresholds that trigger action. These make "code quality" concrete rather than aspirational.

<!-- CUSTOMIZE: Adjust these thresholds for your language and project.
     These defaults are reasonable for most TypeScript/Python/Go projects. -->

## Thresholds

| Metric | Limit | Action When Exceeded |
|--------|-------|---------------------|
| File length | 300 lines | Split by responsibility (see Splitting Strategies in CLAUDE.md) |
| Function/method length | 40 lines | Extract helper functions |
| Function parameters | 4 params | Introduce an options/config object |
| Nesting depth | 3 levels | Use early returns, extract conditions |
| Dependencies per module | 5 imports from project | Re-evaluate module boundaries |
| Cyclomatic complexity | 10 per function | Simplify control flow, extract branches |

## Hotspot Detection

If a file is edited **3+ times in a single sprint**, it's a hotspot that likely needs refactoring. Flag it during `/retro`.

Signs a module is over-budget:
- Every bug fix in module A requires changes in module B (tight coupling)
- New features require modifying the same file (god module)
- Test setup for the module is complex (too many dependencies)
- The module appears in most merge conflicts (change magnet)

## Responding to Threshold Violations

1. **Don't fix it immediately** — if you're working on something else, use `/document-bug` to log the complexity issue
2. **Propose a splitting plan** — during the next refactoring session, present a plan before restructuring
3. **Update thresholds if needed** — some files legitimately need to be larger (e.g., generated code, protocol handlers). Document exceptions in this file.

## Exceptions

<!-- Add justified exceptions here as they arise -->
<!-- Example:
- `src/protocol/messages.ts` — 500 lines OK, auto-generated from schema
- `tests/integration/full-flow.test.ts` — 400 lines OK, sequential test steps
-->
