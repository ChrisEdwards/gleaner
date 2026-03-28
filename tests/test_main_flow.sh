#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
setup_mocks

tmpdir=$(create_temp_dir)
spec="$tmpdir/spec.md"
echo "# Test Spec" > "$spec"
outdir="$tmpdir/gleanings"

# Fresh run should: create base session, run discovery, hit checkpoint (exit 10)
# Mock claude to also create reference-projects.md
export MOCK_CLAUDE_RESPONSE='{"session_id":"mock-base-001","result":"understood","cost_usd":0.01}'

# We need discovery to create the file. Since mock claude doesn't actually call tools,
# we simulate this by pre-creating the output dir and checking behavior.
mkdir -p "$outdir"

# Test: --repos skips discovery and goes to deep-dives
# (will process repos with mock claude and exit 0)
export MOCK_CLAUDE_RESPONSE='{"session_id":"mock-sess","result":"cosmetic changes only","cost_usd":0.01}'
output=$(bash "$GLEANER_SCRIPT" --repos https://github.com/fake/test-repo \
    --output-dir "$outdir" --workers 1 "$spec" 2>&1)
rc=$?
# Should succeed (exit 0) since we have repos and mock claude works
assert_exit_code "0" "$rc" "pre-seeded repos run completes"

# State file should exist
assert_file_exists "$outdir/.gleaner-state.json" "state file created"

# Repo should be marked complete in state
status=$(jq -r '.repos["fake/test-repo"].status' "$outdir/.gleaner-state.json" 2>/dev/null)
assert_equals "complete" "$status" "repo marked complete"

unset MOCK_CLAUDE_RESPONSE
cleanup_temp_dir
report_results "test_main_flow"
