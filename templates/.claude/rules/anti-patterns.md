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

## Running and Observing External Processes

Both of these fail *silently and misleadingly*: neither produces an error that
points at the real cause, so the time lost goes into diagnosing the wrong thing.

- **NEVER launch a long-running process with `start //wait` (Git Bash) or `Start-Process` (PowerShell)** — both return before the process exits, so the agent's background task is marked complete and the process is torn down with it. The symptom is a run that appears to die at a different point each time, with no crash in the system event log and no shutdown sequence in its own log. Run the executable attached inside a long-lived background task, so the task stays alive until the process exits.
- **NEVER `tail -f` a log file while the process that writes it is running** — the reader holds the file open, the writer then fails to open its own log, and the run continues writing nothing. You end up diagnosing a **stale log from a previous run**. Read the log after the process exits. Stopping the monitor may also leave the `tail` orphaned and still holding the handle, so check for survivors before re-running.
