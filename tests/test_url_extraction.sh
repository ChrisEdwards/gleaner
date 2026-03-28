#!/usr/bin/env bash
source "$(dirname "$0")/helpers.sh"
source "$GLEAN_SCRIPT"

tmpdir=$(create_temp_dir)

# Create a sample reference-projects.md
cat > "$tmpdir/reference-projects.md" <<'EOF'
# Reference Projects

## WhisperX
A great ASR tool: https://github.com/m-bain/whisperX
Relevant for audio processing.

## Auto-Editor
https://github.com/WyattBlue/auto-editor - automated video editing

## Audapolis
Check out https://github.com/bugbakery/audapolis for transcript editing.

## Not a repo
This line has no GitHub URL.

## Duplicate
https://github.com/m-bain/whisperX mentioned again
EOF

# extract_github_urls should find unique repo URLs
urls=$(extract_github_urls "$tmpdir/reference-projects.md")
url_count=$(echo "$urls" | wc -l | tr -d ' ')
assert_equals "3" "$url_count" "found 3 unique URLs"
assert_contains "$urls" "m-bain/whisperX" "found whisperX"
assert_contains "$urls" "WyattBlue/auto-editor" "found auto-editor"
assert_contains "$urls" "bugbakery/audapolis" "found audapolis"

# Empty file returns nothing
echo "" > "$tmpdir/empty.md"
urls=$(extract_github_urls "$tmpdir/empty.md")
assert_equals "" "$urls" "empty file returns empty"

cleanup_temp_dir
report_results "test_url_extraction"
