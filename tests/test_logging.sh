#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
source "$GLEAN_SCRIPT"

tmpdir=$(create_temp_dir)

# setup_logging creates log directory
OUTPUT_DIR="$tmpdir/gleanings"
setup_logging
assert_file_exists "$OUTPUT_DIR/.logs/glean.log" "glean.log created"

# log_info writes to glean.log
log_info "test message"
content=$(cat "$OUTPUT_DIR/.logs/glean.log")
assert_contains "$content" "test message" "log_info writes message"
assert_contains "$content" "INFO" "log_info includes level"

# log_error writes to glean.log with ERROR prefix
log_error "bad thing"
content=$(cat "$OUTPUT_DIR/.logs/glean.log")
assert_contains "$content" "bad thing" "log_error writes message"
assert_contains "$content" "ERROR" "log_error includes level"

# log_session writes to a named log file
log_session "discovery" "session output here"
assert_file_exists "$OUTPUT_DIR/.logs/discovery.log" "discovery.log created"
session_content=$(cat "$OUTPUT_DIR/.logs/discovery.log")
assert_contains "$session_content" "session output here" "log_session writes content"

cleanup_temp_dir
report_results "test_logging"
