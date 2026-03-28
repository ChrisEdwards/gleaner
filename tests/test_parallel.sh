#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
setup_mocks
source "$GLEAN_SCRIPT"

tmpdir=$(create_temp_dir)
OUTPUT_DIR="$tmpdir/gleanings"
SPEC_FILE="$tmpdir/spec.md"
echo "test spec" > "$SPEC_FILE"
setup_logging
BASE_SESSION_ID="base-mock"
WORKERS=2
MODEL="opus"
EFFORT="high"
GREENFIELD=false

# Create state file
save_state "deep-dives" ""

# run_parallel_analysis with 3 repos and 2 workers should process all
REPO_URLS=(
    "https://github.com/fake/repo-a"
    "https://github.com/fake/repo-b"
    "https://github.com/fake/repo-c"
)

run_parallel_analysis
rc=$?

# All 3 repos should be in state file
count=$(jq '.repos | length' "$OUTPUT_DIR/.glean-state.json")
assert_equals "3" "$count" "all 3 repos tracked in state"

# Check that analysis files were referenced (mock claude doesn't actually write them,
# but state should show complete for each)
for repo in "fake/repo-a" "fake/repo-b" "fake/repo-c"; do
    status=$(jq -r --arg r "$repo" '.repos[$r].status' "$OUTPUT_DIR/.glean-state.json")
    assert_equals "complete" "$status" "$repo marked complete"
done

cleanup_temp_dir
report_results "test_parallel"
