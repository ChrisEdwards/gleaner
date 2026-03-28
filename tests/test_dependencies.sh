#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"

# Source gleaner to get access to check_dependencies function
source "$GLEANER_SCRIPT"

# With real tools available, check_dependencies should pass
output=$(check_dependencies 2>&1)
rc=$?
assert_exit_code "0" "$rc" "deps pass when tools exist"

# With claude missing, should fail with exit 3
old_path="$PATH"
export PATH="/usr/bin:/bin"  # strip claude from path
output=$(check_dependencies 2>&1; echo "EXIT:$?") ; rc="${output##*EXIT:}" ; output="${output%EXIT:*}"
assert_exit_code "3" "$rc" "deps fail when claude missing"
assert_contains "$output" "claude" "error mentions claude"
export PATH="$old_path"

report_results "test_dependencies"
