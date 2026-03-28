#!/usr/bin/env bash
set -euo pipefail

REPO="owner/glean"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

echo "Installing glean..."

mkdir -p "$INSTALL_DIR"

# Download glean script and VERSION
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

curl -fsSL "$BASE_URL/glean" -o "$INSTALL_DIR/glean"
curl -fsSL "$BASE_URL/VERSION" -o "$INSTALL_DIR/.glean-version"
chmod +x "$INSTALL_DIR/glean"

# Verify
if "$INSTALL_DIR/glean" --version >/dev/null 2>&1; then
    echo "glean installed to $INSTALL_DIR/glean"
else
    echo "Installation failed." >&2
    exit 1
fi

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "Add $INSTALL_DIR to your PATH:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi
