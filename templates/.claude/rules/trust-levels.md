# Trust Levels — Progressive Autonomy

Not all code deserves equal scrutiny. Areas with good test coverage and stable interfaces can be modified with more autonomy. Fragile or critical areas require extra caution.

## Trust Tiers

<!-- CUSTOMIZE: Replace these example directories with your actual project structure.
     Assign trust levels based on test coverage, blast radius, and change frequency. -->

### High Autonomy (well-tested, stable, low blast radius)

- `utils/`, `components/ui/`, `helpers/`
- Edit freely, run unit tests before commit
- These areas have good test coverage and limited downstream impact

### Medium Autonomy (moderate risk, integration points)

- `api/`, `services/`, `routes/`
- Require integration tests before commit
- Changes here affect multiple consumers — verify callers still work

### Low Autonomy (fragile, critical, or poorly tested)

- `auth/`, `payments/`, `migrations/`, `config/`
- Require human review — never auto-commit changes here
- Always present a plan before modifying
- Run full test suite, not just unit tests

## How to Use This

1. **Before editing a file**, consider which tier it falls into
2. **Match your verification effort to the tier** — don't over-verify trivial UI changes, don't under-verify auth logic
3. **When test coverage improves**, promote modules to higher trust tiers
4. **When bugs escape**, demote the affected module until coverage improves

## Updating Trust Levels

Trust levels should change based on evidence:

| Event | Action |
|-------|--------|
| Module has 0 bugs for 3+ sprints | Consider promoting to higher trust |
| Bug escapes from a "high autonomy" module | Demote to medium until test gap is filled |
| New critical feature added to a module | Re-evaluate tier based on blast radius |
| Test coverage drops below 70% | Demote to medium autonomy at minimum |
