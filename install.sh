#!/usr/bin/env bash
set -euo pipefail

REPO="ChrisEdwards/gleaner"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

echo "Installing gleaner..."

mkdir -p "$INSTALL_DIR"

# Download gleaner script and VERSION
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

curl -fsSL "$BASE_URL/gleaner" -o "$INSTALL_DIR/gleaner"
curl -fsSL "$BASE_URL/VERSION" -o "$INSTALL_DIR/.gleaner-version"
chmod +x "$INSTALL_DIR/gleaner"

# Verify
if "$INSTALL_DIR/gleaner" --version </dev/null >/dev/null 2>&1; then
    echo "gleaner installed to $INSTALL_DIR/gleaner"
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
