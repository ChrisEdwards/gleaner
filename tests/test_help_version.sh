#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"

# --help prints usage and exits 0
output=$(bash "$GLEAN_SCRIPT" --help 2>&1)
rc=$?
assert_exit_code "0" "$rc" "--help exits 0"
assert_contains "$output" "Usage: glean" "--help shows usage"
assert_contains "$output" "spec-file" "--help mentions spec-file"
assert_contains "$output" "--continue" "--help mentions --continue"
assert_contains "$output" "--greenfield" "--help mentions --greenfield"

# --version prints version and exits 0
output=$(bash "$GLEAN_SCRIPT" --version 2>&1)
rc=$?
assert_exit_code "0" "$rc" "--version exits 0"
assert_contains "$output" "0.1.0" "--version shows version"

report_results "test_help_version"
