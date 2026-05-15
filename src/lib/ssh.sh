#!/usr/bin/env bash
# lib/ssh.sh — ssh / scp wrappers with consistent timeout options.

CCR_SSH_OPTS=(-o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=3)

_ccr_ssh_args() {
    local args=("${CCR_SSH_OPTS[@]}" -p "$CCR_SRV_PORT")
    [ -n "$CCR_SRV_IDENTITY" ] && args+=(-i "$CCR_SRV_IDENTITY")
    args+=("${CCR_SRV_USER}@${CCR_SRV_HOST}")
    printf '%s\n' "${args[@]}"
}

_ccr_scp_args() {
    local args=("${CCR_SSH_OPTS[@]}" -P "$CCR_SRV_PORT")
    [ -n "$CCR_SRV_IDENTITY" ] && args+=(-i "$CCR_SRV_IDENTITY")
    printf '%s\n' "${args[@]}"
}

_ccr_read_args() {
    # Read newline-separated args into the array named by $1.
    local __name="$1"; shift
    eval "$__name=()"
    local line
    while IFS= read -r line; do
        eval "$__name+=(\"\$line\")"
    done < <("$@")
}

ccr_remote() {
    local _args
    _ccr_read_args _args _ccr_ssh_args
    ssh "${_args[@]}" "$1"
}

ccr_upload() {
    local _args
    _ccr_read_args _args _ccr_scp_args
    scp "${_args[@]}" "$1" "${CCR_SRV_USER}@${CCR_SRV_HOST}:$2"
}

ccr_download() {
    local _args
    _ccr_read_args _args _ccr_scp_args
    scp "${_args[@]}" "${CCR_SRV_USER}@${CCR_SRV_HOST}:$1" "$2"
}

ccr_ssh_interactive() {
    local _args
    _ccr_read_args _args _ccr_ssh_args
    ssh "${_args[@]}"
}

ccr_quote_remote() {
    local v="$1"
    printf "'%s'" "${v//\'/\'\\\'\'}"
}
