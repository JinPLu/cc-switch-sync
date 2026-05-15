#!/usr/bin/env bash
# tools/create-shortcut.sh — create a Desktop shortcut on macOS / Linux.
# Drops ~/Desktop/CC Switch Remote.command that runs the installed cc-remote.
# Pass --uninstall to remove.

set -e

NAME="${CCR_SHORTCUT_NAME:-CC Switch Remote}"
DESK="$HOME/Desktop"
TARGET="$DESK/$NAME.command"
# Prefer the symlink the installer creates; fall back to PATH lookup.
BIN="${CCR_BIN:-$HOME/.local/bin/cc-remote}"
[ -x "$BIN" ] || BIN="$(command -v cc-remote 2>/dev/null || true)"

if [ "${1:-}" = "--uninstall" ]; then
    [ -f "$TARGET" ] && rm -f "$TARGET" && echo "Removed $TARGET"
    exit 0
fi

if [ ! -d "$DESK" ]; then
    echo "No Desktop dir at $DESK; skipping shortcut."
    exit 0
fi
if [ -z "$BIN" ]; then
    echo "cc-remote not found on PATH; cannot create shortcut."
    exit 0
fi

cat > "$TARGET" <<EOF
#!/bin/bash
exec "$BIN"
EOF
chmod +x "$TARGET"
echo "Shortcut: $TARGET"
