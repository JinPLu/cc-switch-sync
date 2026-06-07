#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file() {
    [ -f "$1" ] || fail "missing file: $1"
}

assert_contains() {
    local file="$1" needle="$2"
    grep -Fq "$needle" "$file" || fail "$file does not contain: $needle"
}

assert_executable() {
    [ -x "$1" ] || fail "$1 is not executable"
}

assert_file README.md
assert_contains README.md "安装 macOS.command"
assert_contains README.md "cc-remote"

assert_file "安装 macOS.command"
assert_executable "安装 macOS.command"
assert_contains "安装 macOS.command" '/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH'
assert_contains "安装 macOS.command" "按回车"

assert_file src/install.sh
assert_contains src/install.sh "https://github.com/JinPLu/cc-switch-sync.git"
assert_contains src/install.sh "cc-switch-remote-kit PATH"

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
mkdir -p "$tmp_home/Desktop" "$tmp_home/bin"
touch "$tmp_home/bin/cc-remote"
chmod +x "$tmp_home/bin/cc-remote"

HOME="$tmp_home" CCR_BIN="$tmp_home/bin/cc-remote" bash src/tools/create-shortcut.sh >/dev/null
shortcut="$tmp_home/Desktop/CC Switch Remote.command"
assert_file "$shortcut"
assert_executable "$shortcut"
assert_contains "$shortcut" '/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH'
assert_contains "$shortcut" 'exec "$BIN" menu'

for script in "安装 macOS.command" src/install.sh src/bin/cc-remote src/tools/create-shortcut.sh; do
    bash -n "$script"
done

cmd_home="$tmp_home/cmd-home"
mkdir -p "$cmd_home"
HOME="$cmd_home" src/bin/cc-remote --help >/dev/null

printf 'macOS terminal entry checks passed.\n'
