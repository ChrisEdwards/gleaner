#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
source "$GLEAN_SCRIPT"

# Basic: spec file only
parse_args "myspec.md"
assert_equals "myspec.md" "$SPEC_FILE" "spec file parsed"
assert_equals "./gleanings" "$OUTPUT_DIR" "default output dir"
assert_equals "false" "$CONTINUE_MODE" "default continue mode"
assert_equals "opus" "$MODEL" "default model"
assert_equals "high" "$EFFORT" "default effort"
assert_equals "3" "$WORKERS" "default workers"
assert_equals "10" "$MAX_REPOS" "default max repos"
assert_equals "false" "$GREENFIELD" "default greenfield"
assert_equals "false" "$VERBOSE" "default verbose"
assert_equals "0" "${#PRESEEDED_REPOS[@]}" "no preseeded repos"

# All flags
parse_args --continue --output-dir /tmp/out --model sonnet --effort max \
    --workers 5 --max-repos 20 --greenfield --verbose \
    --repos https://github.com/foo/bar https://github.com/baz/qux \
    spec.md
assert_equals "spec.md" "$SPEC_FILE" "spec file with all flags"
assert_equals "/tmp/out" "$OUTPUT_DIR" "custom output dir"
assert_equals "true" "$CONTINUE_MODE" "--continue parsed"
assert_equals "sonnet" "$MODEL" "custom model"
assert_equals "max" "$EFFORT" "custom effort"
assert_equals "5" "$WORKERS" "custom workers"
assert_equals "20" "$MAX_REPOS" "custom max repos"
assert_equals "true" "$GREENFIELD" "--greenfield parsed"
assert_equals "true" "$VERBOSE" "--verbose parsed"
assert_equals "2" "${#PRESEEDED_REPOS[@]}" "two preseeded repos"
assert_equals "https://github.com/foo/bar" "${PRESEEDED_REPOS[0]}" "first repo URL"

# Missing spec file should exit 2
output=$(parse_args --verbose 2>&1; echo "EXIT:$?") ; rc="${output##*EXIT:}" ; output="${output%EXIT:*}"
assert_exit_code "2" "$rc" "missing spec file exits 2"

# Unknown flag should exit 2
output=$(parse_args --bogus spec.md 2>&1; echo "EXIT:$?") ; rc="${output##*EXIT:}" ; output="${output%EXIT:*}"
assert_exit_code "2" "$rc" "unknown flag exits 2"

report_results "test_parse_args"
