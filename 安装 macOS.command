#!/usr/bin/env bash
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR" || exit 1

printf '\nCC Switch Remote macOS 安装器\n\n'

if [ ! -f "src/install.sh" ]; then
    printf '[ERROR] 找不到 src/install.sh，请确认已完整解压安装包。\n' >&2
    printf '\n按回车关闭窗口...'
    IFS= read -r _ || true
    exit 1
fi

bash src/install.sh
rc=$?

if [ "$rc" -ne 0 ]; then
    printf '\n[ERROR] 安装失败，退出码：%s\n' "$rc" >&2
fi

printf '\n按回车关闭窗口...'
IFS= read -r _ || true
exit "$rc"
