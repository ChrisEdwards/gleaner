#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
source "$GLEAN_SCRIPT"

# "cosmetic" in response means converged
assert_equals "true" "$(is_cosmetic "Changes were COSMETIC: minor wording fixes")" "detects COSMETIC"
assert_equals "true" "$(is_cosmetic "These changes are cosmetic in nature")" "detects lowercase cosmetic"
assert_equals "false" "$(is_cosmetic "Changes were SUBSTANTIVE: restructured arguments")" "SUBSTANTIVE is not cosmetic"
assert_equals "false" "$(is_cosmetic "Made significant revisions throughout")" "no keyword is not cosmetic"

report_results "test_convergence"
