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

BIN_ESCAPED="$(printf '%s' "$BIN" | sed 's/[\"\\$`]/\\&/g')"
cat > "$TARGET" <<EOF
#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:\$HOME/.local/bin:\$PATH"
BIN="$BIN_ESCAPED"
if [ ! -x "\$BIN" ]; then
    printf '[ERROR] cc-remote not found: %s\n' "\$BIN" >&2
    printf '\nPress Enter to close...'
    IFS= read -r _ || true
    exit 1
fi
exec "\$BIN" menu
EOF
chmod +x "$TARGET"
echo "Shortcut: $TARGET"
