#!/bin/bash
# =============================================================================
# generic-reporter.sh - TDD Guard reporter template
# =============================================================================
# Converts test output from any test framework into TDD Guard JSON format.
#
# CUSTOMIZE: Replace TEST_CMD and the parsing logic for your test framework.
#
# This script:
# 1. Runs your test command
# 2. Parses the output into TDD Guard's testModules JSON format
# 3. Writes to .claude/tdd-guard/data/test.json
# 4. Passes through original output to stdout
#
# Usage:
#   bash .claude/tdd-guard/reporters/generic-reporter.sh              # default command
#   bash .claude/tdd-guard/reporters/generic-reporter.sh <test_cmd>   # specific test
#
# TDD Guard JSON format:
#   {
#     "testModules": [{
#       "moduleId": "module_name",
#       "tests": [
#         { "name": "test_name", "fullName": "module/test_name", "state": "passed"|"failed", "errors": [] }
#       ]
#     }],
#     "reason": "passed"|"failed"
#   }
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/.claude/tdd-guard/data"
OUTPUT_FILE="$OUTPUT_DIR/test.json"
TEMP_FILE="$OUTPUT_FILE.tmp"

mkdir -p "$OUTPUT_DIR"

# --- CUSTOMIZE THIS SECTION ---
# Replace with your project's test command
TEST_CMD="${1:-npm test}"
# --- END CUSTOMIZE ---

# Run tests and capture output. Capture the status on the same statement:
# a trailing `|| true` would reset $? (and PIPESTATUS) to 0, making the
# exit-code fallback below unreachable.
TEST_EXIT=0
TEST_OUTPUT=$(cd "$PROJECT_ROOT" && eval "$TEST_CMD" 2>&1) || TEST_EXIT=$?

# --- CUSTOMIZE: Parse output into arrays ---
# Replace this parsing logic with patterns for your test framework.
# You need to populate these arrays:
#   TEST_NAMES[i]  = name of each test
#   TEST_STATES[i] = "passed" or "failed"
#   TEST_ERRORS[i] = error message (empty string if passed)

declare -a TEST_NAMES=()
declare -a TEST_STATES=()
declare -a TEST_ERRORS=()

# Example patterns (adapt for your framework):
#
# pytest:    "PASSED test_name" / "FAILED test_name - AssertionError: ..."
# jest:      "PASS src/test.js" / "FAIL src/test.js"
# go test:   "--- PASS: TestName" / "--- FAIL: TestName"
# cargo:     "test test_name ... ok" / "test test_name ... FAILED"
# C++ (test_framework.h): "[TEST] name... OK" / "[TEST] name... FAILED: ..."

# shellcheck disable=SC2034  # `line` is used by the parsing you add below.
while IFS= read -r line; do
    # --- Replace these patterns with your framework's output format ---

    # Pattern: test passed
    # if [[ "$line" =~ YOUR_PASS_PATTERN ]]; then
    #     TEST_NAMES+=("${BASH_REMATCH[1]}")
    #     TEST_STATES+=("passed")
    #     TEST_ERRORS+=("")
    # fi

    # Pattern: test failed
    # if [[ "$line" =~ YOUR_FAIL_PATTERN ]]; then
    #     TEST_NAMES+=("${BASH_REMATCH[1]}")
    #     TEST_STATES+=("failed")
    #     TEST_ERRORS+=("$line")
    # fi

    : # placeholder — remove when you add real parsing
done <<< "$TEST_OUTPUT"

# --- END CUSTOMIZE ---

# Derive moduleId from test command
MODULE_ID=$(basename "$TEST_CMD" | sed 's/\.[^.]*$//' | tr ' ' '_')

# Determine overall reason
REASON="passed"
for state in "${TEST_STATES[@]:-}"; do
    if [ "$state" = "failed" ]; then
        REASON="failed"
        break
    fi
done

# Check exit code as fallback
if [ "$TEST_EXIT" -ne 0 ] && [ "$REASON" = "passed" ]; then
    REASON="failed"
    if [ ${#TEST_NAMES[@]} -eq 0 ]; then
        TEST_NAMES+=("test_command")
        TEST_STATES+=("failed")
        TEST_ERRORS+=("Test command exited with code $TEST_EXIT")
    fi
fi

# Build JSON (no jq dependency)
{
    printf '{\n  "testModules": [\n    {\n'
    printf '      "moduleId": "%s",\n' "$MODULE_ID"
    printf '      "tests": [\n'

    for i in "${!TEST_NAMES[@]}"; do
        NAME="${TEST_NAMES[$i]}"
        STATE="${TEST_STATES[$i]}"
        ERROR="${TEST_ERRORS[$i]}"
        ERROR=$(printf '%s' "$ERROR" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

        printf '        {\n'
        printf '          "name": "%s",\n' "$NAME"
        printf '          "fullName": "%s/%s",\n' "$MODULE_ID" "$NAME"
        printf '          "state": "%s",\n' "$STATE"
        if [ -n "$ERROR" ]; then
            printf '          "errors": ["%s"]\n' "$ERROR"
        else
            printf '          "errors": []\n'
        fi

        if [ "$i" -lt $(( ${#TEST_NAMES[@]} - 1 )) ]; then
            printf '        },\n'
        else
            printf '        }\n'
        fi
    done

    printf '      ]\n'
    printf '    }\n'
    printf '  ],\n'
    printf '  "reason": "%s"\n' "$REASON"
    printf '}\n'
} > "$TEMP_FILE"

mv "$TEMP_FILE" "$OUTPUT_FILE"

# Passthrough original output
echo "$TEST_OUTPUT"

# Preserve original exit code
exit "$TEST_EXIT"
