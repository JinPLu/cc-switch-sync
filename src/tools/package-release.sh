#!/usr/bin/env bash
# tools/package-release.sh — build a release tarball.
# Usage: tools/package-release.sh [version]

set -e

VERSION="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STAGING="$ROOT/release/cc-switch-remote-kit-$VERSION"
ARCHIVE="$STAGING.tar.gz"
ZIP="$STAGING.zip"

rm -rf "$STAGING" "$ARCHIVE" "$ZIP"
mkdir -p "$STAGING"

INCLUDE=(
    src
    "安装 Windows.bat"
    "安装 macOS.command"
    "打开 CC Switch Remote.bat"
    "使用说明.md"
)

for item in "${INCLUDE[@]}"; do
    src="$ROOT/$item"
    if [ -e "$src" ]; then
        cp -R "$src" "$STAGING/"
    fi
done

# Ensure shell scripts are executable.
chmod +x "$STAGING/src/bin/cc-remote" "$STAGING/src/install.sh" "$STAGING/安装 macOS.command" 2>/dev/null || true

# Build archives.
tar -czf "$ARCHIVE" -C "$ROOT/release" "cc-switch-remote-kit-$VERSION"
if command -v zip >/dev/null 2>&1; then
    (cd "$ROOT/release" && zip -qr "$(basename "$ZIP")" "cc-switch-remote-kit-$VERSION")
fi

echo "Release built:"
echo "  $ARCHIVE"
[ -f "$ZIP" ] && echo "  $ZIP"
