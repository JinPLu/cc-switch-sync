#!/usr/bin/env bash
# install.sh — one-line Mac/Linux installer.
#   curl -fsSL https://raw.githubusercontent.com/farion1231/cc-switch-sync/main/src/install.sh | bash

set -e

REPO="${CCR_REPO:-https://github.com/farion1231/cc-switch-sync.git}"
BRANCH="${CCR_BRANCH:-main}"
DIR="${CCR_INSTALL_DIR:-$HOME/.cc-remote}"
BIN="${CCR_BIN_DIR:-$HOME/.local/bin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
LOCAL_SOURCE=""
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/cc-remote" ]; then
    LOCAL_SOURCE="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

say() { printf '\033[36m%s\033[0m\n' "$1"; }
err() { printf '\033[31m%s\033[0m\n' "$1" >&2; }

say "CC Switch Remote Kit — installer"

for tool in ssh scp tar python3; do
    command -v "$tool" >/dev/null || { err "Missing: $tool"; exit 1; }
done
if [ -z "$LOCAL_SOURCE" ]; then
    command -v git >/dev/null || { err "Missing: git"; exit 1; }
fi

if [ -n "$LOCAL_SOURCE" ] && [ "$LOCAL_SOURCE" != "$DIR" ]; then
    say "Installing from local copy: $LOCAL_SOURCE"
    mkdir -p "$DIR"
    for old in "$DIR"/* "$DIR"/.[!.]* "$DIR"/..?*; do
        [ -e "$old" ] || continue
        case "$(basename "$old")" in
            config.ini|servers.conf|history-downloads) continue ;;
        esac
        rm -rf "$old"
    done
    for item in src "打开 CC Switch Remote.bat" "安装 Windows.bat" "安装 macOS.command" "使用说明.md"; do
        if [ -e "$LOCAL_SOURCE/$item" ]; then
            cp -R "$LOCAL_SOURCE/$item" "$DIR/"
        fi
    done
elif [ -d "$DIR/.git" ]; then
    say "Updating $DIR"
    git -C "$DIR" fetch --depth 1 origin "$BRANCH" >/dev/null
    git -C "$DIR" reset --hard "origin/$BRANCH" >/dev/null
elif [ -d "$DIR" ] && [ -z "$LOCAL_SOURCE" ]; then
    err "$DIR exists and is not a git checkout. Remove or set CCR_INSTALL_DIR."
    exit 1
elif [ -z "$LOCAL_SOURCE" ]; then
    say "Cloning into $DIR"
    git clone --depth 1 --branch "$BRANCH" "$REPO" "$DIR" >/dev/null
fi
chmod +x "$DIR/src/bin/cc-remote"

mkdir -p "$BIN"
ln -sf "$DIR/src/bin/cc-remote" "$BIN/cc-remote"

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) say "Add to your shell rc:  export PATH=\"$BIN:\$PATH\"" ;;
esac

if [ -x "$DIR/src/tools/create-shortcut.sh" ]; then
    CCR_BIN="$BIN/cc-remote" bash "$DIR/src/tools/create-shortcut.sh" || true
fi

printf '\033[32m%s\033[0m\n' "Done. Starting first-time setup. Later, run: cc-remote"
if [ -z "${CCR_NO_LAUNCH:-}" ] && [ -t 0 ] && [ -t 1 ]; then
    exec "$BIN/cc-remote" setup
fi
