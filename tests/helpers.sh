#!/usr/bin/env bash
# Lightweight test harness for gleaner

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
GLEANER_SCRIPT="$PROJECT_DIR/gleaner"

_PASS_COUNT=0
_FAIL_COUNT=0
_TEST_TMPDIR=""

setup_mocks() {
    export PATH="$TESTS_DIR/mocks:$PATH"
}

create_temp_dir() {
    _TEST_TMPDIR="$(mktemp -d)"
    echo "$_TEST_TMPDIR"
}

cleanup_temp_dir() {
    [[ -n "$_TEST_TMPDIR" && -d "$_TEST_TMPDIR" ]] && rm -rf "$_TEST_TMPDIR"
    _TEST_TMPDIR=""
}

assert_equals() {
    local expected="$1" actual="$2" msg="${3:-}"
    if [[ "$expected" == "$actual" ]]; then
        _PASS_COUNT=$((_PASS_COUNT + 1))
    else
        _FAIL_COUNT=$((_FAIL_COUNT + 1))
        echo "  FAIL: ${msg:-assert_equals}"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    if [[ "$haystack" == *"$needle"* ]]; then
        _PASS_COUNT=$((_PASS_COUNT + 1))
    else
        _FAIL_COUNT=$((_FAIL_COUNT + 1))
        echo "  FAIL: ${msg:-assert_contains}"
        echo "    expected to contain: $needle"
        echo "    in: $haystack"
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    if [[ "$haystack" != *"$needle"* ]]; then
        _PASS_COUNT=$((_PASS_COUNT + 1))
    else
        _FAIL_COUNT=$((_FAIL_COUNT + 1))
        echo "  FAIL: ${msg:-assert_not_contains}"
        echo "    expected NOT to contain: $needle"
        echo "    in: $haystack"
    fi
}

assert_exit_code() {
    local expected="$1" actual="$2" msg="${3:-}"
    if [[ "$expected" == "$actual" ]]; then
        _PASS_COUNT=$((_PASS_COUNT + 1))
    else
        _FAIL_COUNT=$((_FAIL_COUNT + 1))
        echo "  FAIL: ${msg:-assert_exit_code}"
        echo "    expected exit code: $expected"
        echo "    actual exit code:   $actual"
    fi
}

assert_file_exists() {
    local filepath="$1" msg="${2:-}"
    if [[ -f "$filepath" ]]; then
        _PASS_COUNT=$((_PASS_COUNT + 1))
    else
        _FAIL_COUNT=$((_FAIL_COUNT + 1))
        echo "  FAIL: ${msg:-assert_file_exists}"
        echo "    file not found: $filepath"
    fi
}

report_results() {
    local test_name="$1"
    echo "$test_name: $_PASS_COUNT passed, $_FAIL_COUNT failed"
    return "$_FAIL_COUNT"
}
