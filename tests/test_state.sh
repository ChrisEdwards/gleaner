#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
source "$GLEANER_SCRIPT"

tmpdir=$(create_temp_dir)
OUTPUT_DIR="$tmpdir/gleanings"
mkdir -p "$OUTPUT_DIR"

# save_state creates .gleaner-state.json with correct structure
SPEC_FILE="my-spec.md"
BASE_SESSION_ID="base-123"
save_state "discovery" ""
assert_file_exists "$OUTPUT_DIR/.gleaner-state.json" "state file created"

content=$(cat "$OUTPUT_DIR/.gleaner-state.json")
assert_contains "$content" '"base_session_id": "base-123"' "state has base session"
assert_contains "$content" '"spec_file": "my-spec.md"' "state has spec file"
assert_contains "$content" '"phase": "discovery"' "state has phase"

# load_state_field reads back correctly
loaded_phase=$(load_state_field ".phase")
assert_equals "discovery" "$loaded_phase" "load_state reads phase"

loaded_base=$(load_state_field ".base_session_id")
assert_equals "base-123" "$loaded_base" "load_state reads base session"

# update_repo_state tracks per-repo state
update_repo_state "m-bain/whisperx" "in-progress" "sess-456" "initial-analysis" 0
content=$(cat "$OUTPUT_DIR/.gleaner-state.json")
assert_contains "$content" "m-bain/whisperx" "repo state saved"
assert_contains "$content" '"status": "in-progress"' "repo status saved"
assert_contains "$content" '"session_id": "sess-456"' "repo session saved"

# update_repo_state can update existing repo
update_repo_state "m-bain/whisperx" "complete" "sess-456" "critique" 3
loaded_status=$(load_state_field '.repos["m-bain/whisperx"].status')
assert_equals "complete" "$loaded_status" "repo status updated"
loaded_passes=$(load_state_field '.repos["m-bain/whisperx"].critique_passes')
assert_equals "3" "$loaded_passes" "critique passes updated"

cleanup_temp_dir
report_results "test_state"
