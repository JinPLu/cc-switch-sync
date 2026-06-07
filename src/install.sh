#!/usr/bin/env bash
# install.sh — one-line Mac/Linux installer.
#   curl -fsSL https://raw.githubusercontent.com/JinPLu/cc-switch-sync/main/src/install.sh | bash

set -e

REPO="${CCR_REPO:-https://github.com/JinPLu/cc-switch-sync.git}"
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

ccr_shell_profiles_for_path() {
    case "$(basename "${SHELL:-}")" in
        zsh)  printf '%s\n%s\n' "$HOME/.zprofile" "$HOME/.zshrc" ;;
        bash) printf '%s\n%s\n' "$HOME/.bash_profile" "$HOME/.bashrc" ;;
        *)    printf '%s\n' "$HOME/.profile" ;;
    esac
}

ccr_escape_double_quotes() {
    printf '%s' "$1" | sed 's/[\"\\$`]/\\&/g'
}

ccr_ensure_bin_on_path() {
    local bin_dir="$1"
    case ":$PATH:" in
        *":$bin_dir:"*) return 0 ;;
    esac
    if [ "${CCR_NO_PATH_UPDATE:-0}" = "1" ]; then
        say "Add to your shell rc:  export PATH=\"$bin_dir:\$PATH\""
        return 0
    fi

    local profile marker_start marker_end escaped_bin changed=0
    marker_start="# >>> cc-switch-remote-kit PATH >>>"
    marker_end="# <<< cc-switch-remote-kit PATH <<<"
    escaped_bin="$(ccr_escape_double_quotes "$bin_dir")"
    while IFS= read -r profile; do
        [ -n "$profile" ] || continue
        mkdir -p "$(dirname "$profile")"
        touch "$profile"

        if grep -Fq "$marker_start" "$profile"; then
            continue
        fi
        cat >> "$profile" <<EOF

$marker_start
case ":\$PATH:" in
    *":$escaped_bin:"*) ;;
    *) export PATH="$escaped_bin:\$PATH" ;;
esac
$marker_end
EOF
        say "Added cc-remote to PATH in $profile"
        changed=1
    done <<EOF
$(ccr_shell_profiles_for_path)
EOF
    [ "$changed" = "1" ] && say "Open a new terminal, then run: cc-remote"
    [ "$changed" = "0" ] && say "PATH helper already exists."

    export PATH="$bin_dir:$PATH"
}

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
    for item in src "打开 CC Switch Remote.bat" "安装 Windows.bat" "安装 macOS.command" "使用说明.md" "README.md"; do
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
ccr_ensure_bin_on_path "$BIN"

if [ -x "$DIR/src/tools/create-shortcut.sh" ]; then
    CCR_BIN="$BIN/cc-remote" bash "$DIR/src/tools/create-shortcut.sh" || true
fi

printf '\033[32m%s\033[0m\n' "Done. Starting first-time setup. Later, run: cc-remote"
if [ -z "${CCR_NO_LAUNCH:-}" ] && [ -t 0 ] && [ -t 1 ]; then
    exec "$BIN/cc-remote" setup
fi
