# Anti-Pattern Registry

Explicit "don't do this" rules with context on why. Each entry documents a mistake pattern and its consequences.

## Code Anti-Patterns

<!-- CUSTOMIZE: Replace these examples with patterns specific to your project.
     Each entry should document a known mistake pattern and its consequences. -->

- **NEVER use `any` to silence type errors** — find the real type. `any` hides bugs that surface in production.
- **NEVER catch and swallow errors silently** — always log + rethrow or handle explicitly. Silent failures are the hardest bugs to diagnose.
- **NEVER mutate function arguments** — clone first. Mutation causes action-at-a-distance bugs that are invisible at the call site.
- **NEVER add retry logic without backoff** — unbounded retries cause cascading failures under load.
- **NEVER hardcode secrets, URLs, or environment-specific values** — use config/env vars. Hardcoded values break on deploy.

## Process Anti-Patterns

- **NEVER "fix" code you're reading for context** — if it's not in scope, use `/document-bug` and move on. Drive-by fixes introduce regressions.
- **NEVER skip the failing test step in TDD** — writing the test after the implementation defeats the purpose. The red-green-refactor cycle catches design issues early.
- **NEVER commit with "fix tests" as the message** — describe what was actually wrong. Vague commit messages make `git bisect` useless.
- **NEVER start implementing without understanding the current state** — read the relevant code, check recent git history, run the existing tests first.
- **NEVER apply the same fix a third time** — if it didn't work twice, the mental model is wrong. STOP and re-diagnose.

## Architecture Anti-Patterns

- **NEVER create a "utils" or "helpers" grab-bag module** — name modules by what they do, not by what they are. Utility modules grow unbounded.
- **NEVER add a dependency for something achievable in <20 lines** — each dependency is a maintenance and security liability.
- **NEVER bypass the dependency direction** — lower layers must not import from upper layers. Violating this creates circular dependencies that are painful to untangle.
