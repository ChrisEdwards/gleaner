#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
setup_mocks
source "$GLEAN_SCRIPT"

tmpdir=$(create_temp_dir)
OUTPUT_DIR="$tmpdir/gleanings"
setup_logging

# run_claude_session extracts session_id from JSON output
export MOCK_CLAUDE_RESPONSE='{"session_id":"abc-123","result":"done","cost_usd":0.01}'
session_id=$(run_claude_session "test prompt")
assert_equals "abc-123" "$session_id" "extracts session_id"

# run_claude_fork passes --resume and --fork-session
export MOCK_CLAUDE_LOG="$tmpdir/claude.log"
export MOCK_CLAUDE_RESPONSE='{"session_id":"fork-456","result":"forked"}'
session_id=$(run_claude_fork "base-session-id" "fork prompt" "Read,Write")
assert_equals "fork-456" "$session_id" "fork returns new session_id"
log_content=$(cat "$tmpdir/claude.log")
assert_contains "$log_content" "--resume base-session-id" "fork passes --resume"
assert_contains "$log_content" "--fork-session" "fork passes --fork-session"

# run_claude_resume passes --resume without --fork-session
export MOCK_CLAUDE_LOG="$tmpdir/claude2.log"
export MOCK_CLAUDE_RESPONSE='{"session_id":"fork-456","result":"resumed"}'
result=$(run_claude_resume "fork-456" "resume prompt" "Read,Edit,Write")
log_content=$(cat "$tmpdir/claude2.log")
assert_contains "$log_content" "--resume fork-456" "resume passes --resume"
assert_not_contains "$log_content" "--fork-session" "resume does not pass --fork-session"

unset MOCK_CLAUDE_RESPONSE MOCK_CLAUDE_LOG MOCK_CLAUDE_EXIT_CODE
cleanup_temp_dir
report_results "test_session"
