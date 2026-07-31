# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `.claude/project.conf` — per-project framework configuration, sourced by the
  hooks and never overwritten by `bin/update.sh`. This is now the supported way
  to customize framework behavior. Settings: `ALLOWED_DIRS`,
  `ALLOWED_FILES_EXTRA`, `ALLOWED_FILES`, `HEADER_LIMIT`, `IMPL_LIMIT`,
  `FUNC_LIMIT`. All optional, all falling back to the framework defaults.
- `bin/update.sh --prune` — opt-in deletion of files absent from the templates.
- CI (`.github/workflows/ci.yml`): shellcheck plus an end-to-end smoke test of
  `setup.sh`/`update.sh`, with regression guards for the fixes below.
- `.gitattributes` enforcing LF, so shell scripts stay executable under WSL and
  Linux and shellcheck is usable on a Windows checkout.
- `setup.sh` now fails with install instructions when `jq` is missing, instead
  of installing hooks that silently do nothing.

### Fixed

- **Data loss.** `update.sh --prune` deleted an entire installation, including
  project-authored skills and rules, when the project path contained `[` or `]`.
  The pattern operand of `${var#$prefix}` was unquoted, so glob metacharacters
  were parsed as a character class and the prefix strip silently no-opped
  (shellcheck SC2295). Also present in `setup.sh`, where it scattered copies
  into a mirrored absolute-path tree.
- **`--language` calibration was reverted by the next update.** `setup.sh`
  patched the limits into `.claude/hooks/check-file-size.sh`, which `update.sh`
  overwrites wholesale. Limits now live in `project.conf`.
- **`update.sh` destroyed local `settings.local.json` and `.claudeignore`**,
  taking hook registrations and per-project ignore rules with them. Both are now
  installed when absent and preserved once modified.
- **`check-scope.sh` was broken for Windows paths**: it matched forward-slash
  patterns against the raw path, so every absolute Windows path was reported
  out-of-scope, and its heredoc emitted unescaped backslashes, producing invalid
  JSON. Paths are normalized and output is built with `jq -n --arg`.
- **`check-file-size.sh` emitted two concatenated JSON objects** when a file
  breached both the size and the function-length budget. Now a single object.
- **The complexity heuristic invented function lengths.** It measured to the
  next `def`, charging trailing module-level code to the preceding function.
  Python now closes on dedent, JS/TS on brace depth.
- Scope matching is anchored. `ALLOWED_DIRS` must start the path or follow a
  slash (`src/` no longer matches `vendor/notsrc/x.py`) and `ALLOWED_FILES`
  compares basenames or path suffixes exactly (`Makefile` no longer admits
  `build/Makefile-gen/x.py`). Both were unanchored substring matches.
- `update.sh`'s summary counters always printed `0` — they were incremented
  inside a pipeline subshell and discarded, so `Removed: 0` was unconditional.
- `--language` is re-runnable: the CLAUDE.md limits table is matched by row
  rather than by one-shot `[150]`-style placeholders, and a limit the project
  has already set is left alone unless `--force`.
- Setting `ALLOWED_DIRS=""` or `ALLOWED_FILES=""` now means "match nothing"
  rather than silently restoring the default.
- Line counting uses `awk` instead of `wc -l`, which undercounted a final line
  with no trailing newline and padded its output on BSD/macOS.

### Removed

- `TOTAL_LIMIT` as a hook setting. It was written into every calibrated project
  and documented in six places, but no hook ever read it. The CLAUDE.md
  "Total per module" row remains, since `/check-sizes` uses it.
- Dead code: an unused `SESSION_MODE` pipeline that ran on every edit, and three
  unused variables in `pre-commit-check.sh`.
