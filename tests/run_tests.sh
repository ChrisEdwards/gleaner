#!/usr/bin/env bash
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

for test_file in "$TESTS_DIR"/test_*.sh; do
    [[ -f "$test_file" ]] || continue
    echo "--- $(basename "$test_file") ---"
    bash "$test_file"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        TOTAL_FAIL=$((TOTAL_FAIL + rc))
    fi
    echo ""
done

echo "================================"
if [[ $TOTAL_FAIL -eq 0 ]]; then
    echo "All tests passed."
    exit 0
else
    echo "FAILURES: $TOTAL_FAIL test file(s) had failures."
    exit 1
fi
