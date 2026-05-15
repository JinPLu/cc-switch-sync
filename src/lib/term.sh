#!/usr/bin/env bash
# lib/term.sh — terminal output: colors, icons, status, layout, spinner, menu.

# -------- colors (respect NO_COLOR / CCR_THEME=plain / non-tty) --------

_ccr_supports_color() {
    [ -n "${NO_COLOR:-}" ] && return 1
    [ "${CCR_THEME:-}" = "plain" ] && return 1
    [ ! -t 1 ] && return 1
    case "${TERM:-}" in dumb|"") return 1 ;; esac
    return 0
}

if _ccr_supports_color; then
    CCR_RESET=$'\033[0m'; CCR_BOLD=$'\033[1m'; CCR_DIM=$'\033[2m'
    CCR_RED=$'\033[31m'; CCR_GREEN=$'\033[32m'; CCR_YELLOW=$'\033[33m'
    CCR_BLUE=$'\033[34m'; CCR_MAGENTA=$'\033[35m'; CCR_CYAN=$'\033[36m'
    CCR_GRAY=$'\033[90m'; CCR_BRIGHT_CYAN=$'\033[96m'
else
    CCR_RESET=""; CCR_BOLD=""; CCR_DIM=""
    CCR_RED=""; CCR_GREEN=""; CCR_YELLOW=""
    CCR_BLUE=""; CCR_MAGENTA=""; CCR_CYAN=""
    CCR_GRAY=""; CCR_BRIGHT_CYAN=""
fi

ccr_color_for_plugin() {
    case "$1" in
        claude) printf '%s' "$CCR_MAGENTA" ;;
        codex)  printf '%s' "$CCR_BRIGHT_CYAN" ;;
        *)      printf '%s' "$CCR_CYAN" ;;
    esac
}

# -------- icons (Unicode with ASCII fallback) --------

_ccr_supports_unicode() {
    case "${CCR_ICON_SET:-auto}" in
        unicode) return 0 ;;
        ascii)   return 1 ;;
    esac
    case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
        *UTF-8*|*utf-8*|*UTF8*|*utf8*) return 0 ;;
        *) return 1 ;;
    esac
}

if _ccr_supports_unicode; then
    CCR_ICON_OK="✓"; CCR_ICON_ERR="✗"; CCR_ICON_WARN="⚠"
    CCR_ICON_INFO="→"; CCR_ICON_SKIP="·"; CCR_ICON_WORK="⟳"
    CCR_ICON_DOT="•"; CCR_ICON_ARROW="❯"
else
    CCR_ICON_OK="[OK]"; CCR_ICON_ERR="[ERR]"; CCR_ICON_WARN="[!]"
    CCR_ICON_INFO="[i]"; CCR_ICON_SKIP="[-]"; CCR_ICON_WORK="[..]"
    CCR_ICON_DOT="*";   CCR_ICON_ARROW=">"
fi

ccr_status() {
    local level="$1"; shift
    local icon color
    case "$level" in
        OK)        icon="$CCR_ICON_OK";   color="$CCR_GREEN"  ;;
        ERR|ERROR) icon="$CCR_ICON_ERR";  color="$CCR_RED"    ;;
        WARN)      icon="$CCR_ICON_WARN"; color="$CCR_YELLOW" ;;
        INFO)      icon="$CCR_ICON_INFO"; color="$CCR_CYAN"   ;;
        SKIP)      icon="$CCR_ICON_SKIP"; color="$CCR_GRAY"   ;;
        WORK)      icon="$CCR_ICON_WORK"; color="$CCR_BLUE"   ;;
        *)         icon="$CCR_ICON_DOT";  color=""            ;;
    esac
    printf '  %s%s%s %s\n' "$color" "$icon" "$CCR_RESET" "$*"
}

# -------- layout (cached width + rule + logo + title) --------

CCR_TERM_W=$(tput cols 2>/dev/null || echo 80)
[ "$CCR_TERM_W" -gt 100 ] && CCR_TERM_W=100
[ "$CCR_TERM_W" -lt 40 ]  && CCR_TERM_W=40
CCR_RULE_LINE=""
_i=0
while [ $_i -lt $CCR_TERM_W ]; do CCR_RULE_LINE="$CCR_RULE_LINE─"; _i=$((_i+1)); done
unset _i

ccr_rule() {
    printf '%s%s%s\n' "${1:-$CCR_GRAY}" "$CCR_RULE_LINE" "$CCR_RESET"
}

ccr_logo() {
    local c="$CCR_BRIGHT_CYAN" d="$CCR_DIM" r="$CCR_RESET"
    printf '\n'
    printf '%s   ██████╗ ██████╗     ███████╗ ██╗ ██╗ ███╗  ██╗ ██████╗ %s\n' "$c" "$r"
    printf '%s  ██╔════╝██╔════╝     ██╔════╝ ╚██╗██╔╝ ████╗ ██║██╔════╝%s\n' "$c" "$r"
    printf '%s  ██║     ██║          ███████╗  ╚███╔╝  ██╔██╗██║██║     %s\n' "$c" "$r"
    printf '%s  ██║     ██║          ╚════██║  ██╔██╗  ██║╚████║██║     %s\n' "$c" "$r"
    printf '%s  ╚██████╗╚██████╗     ███████║ ██╔╝ ██╗ ██║ ╚███║╚██████╗%s\n' "$c" "$r"
    printf '%s   ╚═════╝ ╚═════╝     ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚══╝ ╚═════╝%s\n' "$c" "$r"
    printf '%s      remote sync kit for Claude Code / Codex providers%s\n\n' "$d" "$r"
}

ccr_title() {
    local subtitle="${2:-}"
    printf '\n'
    ccr_rule "$CCR_BRIGHT_CYAN"
    printf '  %s%s%s' "$CCR_BOLD" "$1" "$CCR_RESET"
    [ -n "$subtitle" ] && printf '   %s%s%s' "$CCR_DIM" "$subtitle" "$CCR_RESET"
    printf '\n'
    ccr_rule "$CCR_BRIGHT_CYAN"
}

ccr_list_item() {
    local n="$1" label="$2" desc="${3:-}"
    printf '  %s%2s.%s %s' "$CCR_BRIGHT_CYAN" "$n" "$CCR_RESET" "$label"
    [ -n "$desc" ] && printf '   %s%s%s' "$CCR_DIM" "$desc" "$CCR_RESET"
    printf '\n'
}

ccr_kv() {
    local key="$1"; shift
    printf '    %s%-22s%s %s\n' "$CCR_DIM" "$key" "$CCR_RESET" "$*"
}

# -------- spinner --------

CCR_SPINNER_PID=""
CCR_SPINNER_MSG=""

_ccr_spinner_frames() {
    if _ccr_supports_unicode 2>/dev/null; then
        printf '%s' "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    else
        printf '%s' "|/-\\"
    fi
}

_ccr_spinner_loop() {
    local msg="$1"
    local frames; frames=$(_ccr_spinner_frames)
    local n=${#frames} i=0
    printf '\033[?25l' 2>/dev/null
    while :; do
        printf '\r  %s%s%s %s ' "$CCR_BRIGHT_CYAN" "${frames:$((i % n)):1}" "$CCR_RESET" "$msg"
        i=$((i+1))
        sleep 0.1
    done
}

ccr_spinner_start() {
    if [ ! -t 1 ]; then ccr_status INFO "$1"; return; fi
    CCR_SPINNER_MSG="$1"
    _ccr_spinner_loop "$1" &
    CCR_SPINNER_PID=$!
    trap 'ccr_spinner_stop 1 >/dev/null 2>&1; exit 130' INT TERM
}

ccr_spinner_stop() {
    local rc="${1:-0}"
    if [ -n "$CCR_SPINNER_PID" ]; then
        kill "$CCR_SPINNER_PID" >/dev/null 2>&1 || true
        wait "$CCR_SPINNER_PID" 2>/dev/null || true
        CCR_SPINNER_PID=""
        printf '\r\033[K\033[?25h'
        [ "$rc" -eq 0 ] && ccr_status OK "$CCR_SPINNER_MSG" || ccr_status ERR "$CCR_SPINNER_MSG"
        CCR_SPINNER_MSG=""
    fi
    return "$rc"
}

ccr_spin() {
    local msg="$1"; shift
    ccr_spinner_start "$msg"
    "$@"; local rc=$?
    ccr_spinner_stop "$rc"
    return $rc
}

# -------- menu / prompts --------

ccr_menu() {
    local title="$1" subtitle="$2"; shift 2
    ccr_title "$title" "$subtitle"
    local item num rest label desc
    for item in "$@"; do
        num="${item%%:*}"; rest="${item#*:}"
        label="${rest%%:*}"; desc=""
        [ "$rest" != "$label" ] && desc="${rest#*:}"
        ccr_list_item "$num" "$label" "$desc"
    done
    printf '\n  %s%s%s %s%s%s ' "$CCR_BRIGHT_CYAN" "$CCR_ICON_ARROW" "$CCR_RESET" "$CCR_BOLD" "$(t select_prompt)" "$CCR_RESET"
    local choice
    IFS= read -r choice
    choice="${choice%$'\r'}"
    CCR_MENU_CHOICE="${choice// /}"
}

ccr_confirm() {
    [ "${CCR_ASSUME_YES:-0}" = "1" ] && return 0
    local prompt="$1" default_yes="${2:-1}" suffix
    [ "$default_yes" = "1" ] && suffix="[Y/n]" || suffix="[y/N]"
    printf '  %s%s%s %s %s ' "$CCR_BRIGHT_CYAN" "$CCR_ICON_ARROW" "$CCR_RESET" "$prompt" "$suffix"
    local ans
    IFS= read -r ans
    ans="${ans%$'\r'}"
    case "$ans" in
        ''|' '*) [ "$default_yes" = "1" ] && return 0 || return 1 ;;
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

ccr_prompt() {
    local __var="$1" label="$2" default="${3:-}"
    if [ -n "$default" ]; then
        printf '  %s%s%s %s %s[%s]%s ' "$CCR_BRIGHT_CYAN" "$CCR_ICON_ARROW" "$CCR_RESET" "$label" "$CCR_DIM" "$default" "$CCR_RESET"
    else
        printf '  %s%s%s %s ' "$CCR_BRIGHT_CYAN" "$CCR_ICON_ARROW" "$CCR_RESET" "$label"
    fi
    local v
    IFS= read -r v
    v="${v%$'\r'}"
    [ -z "$v" ] && [ -n "$default" ] && v="$default"
    printf -v "$__var" '%s' "$v" 2>/dev/null || eval "$__var=\$v"
}

ccr_pause() {
    printf '\n  %s%s%s ' "$CCR_DIM" "$(t press_enter)..." "$CCR_RESET"
    IFS= read -r _ || true
}
