#!/usr/bin/env bash
# lib/config.sh — parse servers.conf and ~/.cc-remote/config.ini.

# Trim leading/trailing whitespace using bash builtins only.
# Usage: _ccr_trim varname
_ccr_trim() {
    eval "local _v=\$$1"
    _v="${_v#"${_v%%[![:space:]]*}"}"
    _v="${_v%"${_v##*[![:space:]]}"}"
    eval "$1=\$_v"
}

CCR_CONFIG_DIR="${CCR_CONFIG_DIR:-$HOME/.cc-remote}"
CCR_CONFIG_FILE="${CCR_CONFIG_FILE:-$CCR_CONFIG_DIR/config.ini}"
CCR_HISTORY_DIR="${CCR_HISTORY_DIR:-$CCR_CONFIG_DIR/history-downloads}"

# Default config values.
ccr_default_config() {
    cat <<'EOF'
language=auto
theme=color
icon_set=auto
default_server=
sync_codex=true
sync_codex_auth=confirm
history_include_codex=false
enable_plugins=claude,codex
EOF
}

# Read config into shell variables prefixed CFG_*.
ccr_load_config() {
    local k v
    # Apply defaults first.
    while IFS='=' read -r k v; do
        [ -z "$k" ] && continue
        printf -v "CFG_${k}" '%s' "$v" 2>/dev/null || eval "CFG_${k}=\$v"
    done <<EOF
$(ccr_default_config)
EOF
    # Overlay user config if present.
    if [ -f "$CCR_CONFIG_FILE" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            # Strip CR (Windows line endings) and trim.
            line="${line%$'\r'}"
            # Skip comments / blanks.
            local _trim="$line"
            _ccr_trim _trim
            case "$_trim" in
                ''|'#'*|';'*) continue ;;
            esac
            k="${line%%=*}"
            v="${line#*=}"
            _ccr_trim k
            _ccr_trim v
            [ -z "$k" ] && continue
            printf -v "CFG_${k}" '%s' "$v" 2>/dev/null || eval "CFG_${k}=\$v"
        done < "$CCR_CONFIG_FILE"
    fi
    # Apply environment overrides for theme/icons/language.
    CCR_LANGUAGE="${CCR_LANGUAGE:-$CFG_language}"
    CCR_ICON_SET="${CCR_ICON_SET:-$CFG_icon_set}"
    CCR_THEME="${CCR_THEME:-$CFG_theme}"
}

ccr_ensure_config_file() {
    mkdir -p "$CCR_CONFIG_DIR"
    if [ ! -f "$CCR_CONFIG_FILE" ]; then
        ccr_default_config > "$CCR_CONFIG_FILE"
    fi
}

# Parse servers.conf into arrays.
# Result: CCR_SERVERS_COUNT + CCR_SRV_<i>_NAME / HOST / PORT / USER / WORKDIR / PROXY / IDENTITY
ccr_read_servers() {
    local conf="${1:-$CCR_CONFIG_DIR/servers.conf}"
    CCR_SERVERS_COUNT=0
    if [ ! -f "$conf" ]; then return 0; fi
    local current=0 key val line trimmed
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        trimmed="$line"
        _ccr_trim trimmed
        case "$trimmed" in ''|'#'*) continue ;; esac
        key="${trimmed%% *}"
        val="${trimmed#"$key"}"
        _ccr_trim val
        case "$key" in
            [Hh][Oo][Ss][Tt])
                current=$((current+1))
                CCR_SERVERS_COUNT=$current
                eval "CCR_SRV_${current}_NAME=\$val"
                eval "CCR_SRV_${current}_HOST="
                eval "CCR_SRV_${current}_PORT=22"
                eval "CCR_SRV_${current}_USER=root"
                eval "CCR_SRV_${current}_WORKDIR=~"
                eval "CCR_SRV_${current}_PROXY="
                eval "CCR_SRV_${current}_IDENTITY="
                ;;
            [Hh][Oo][Ss][Tt][Nn][Aa][Mm][Ee]) eval "CCR_SRV_${current}_HOST=\$val" ;;
            [Pp][Oo][Rr][Tt])     eval "CCR_SRV_${current}_PORT=\$val" ;;
            [Uu][Ss][Ee][Rr])     eval "CCR_SRV_${current}_USER=\$val" ;;
            [Ww][Oo][Rr][Kk][Dd][Ii][Rr])  eval "CCR_SRV_${current}_WORKDIR=\$val" ;;
            [Pp][Rr][Oo][Xx][Yy])    eval "CCR_SRV_${current}_PROXY=\$val" ;;
            [Ii][Dd][Ee][Nn][Tt][Ii][Tt][Yy][Ff][Ii][Ll][Ee]) eval "CCR_SRV_${current}_IDENTITY=\$val" ;;
        esac
    done < "$conf"
}

# Set CCR_SRV_* (no index) by index. Result: CCR_SRV_NAME / HOST / etc.
ccr_select_server_by_index() {
    local i="$1"
    eval "CCR_SRV_NAME=\$CCR_SRV_${i}_NAME"
    eval "CCR_SRV_HOST=\$CCR_SRV_${i}_HOST"
    eval "CCR_SRV_PORT=\$CCR_SRV_${i}_PORT"
    eval "CCR_SRV_USER=\$CCR_SRV_${i}_USER"
    eval "CCR_SRV_WORKDIR=\$CCR_SRV_${i}_WORKDIR"
    eval "CCR_SRV_PROXY=\$CCR_SRV_${i}_PROXY"
    eval "CCR_SRV_IDENTITY=\$CCR_SRV_${i}_IDENTITY"
}

ccr_select_server_by_name() {
    local target="$1"
    local i=1
    while [ "$i" -le "$CCR_SERVERS_COUNT" ]; do
        local n; eval "n=\$CCR_SRV_${i}_NAME"
        if [ "$n" = "$target" ]; then
            ccr_select_server_by_index "$i"
            return 0
        fi
        i=$((i+1))
    done
    return 1
}

# Append a server block to servers.conf.
ccr_append_server() {
    local name="$1" host="$2" port="$3" user="$4" workdir="$5" proxy="$6" identity="$7"
    local conf="$CCR_CONFIG_DIR/servers.conf"
    {
        printf '\n'
        printf 'Host %s\n' "$name"
        printf '  HostName %s\n' "$host"
        printf '  Port %s\n' "$port"
        printf '  User %s\n' "$user"
        printf '  WorkDir %s\n' "$workdir"
        [ -n "$proxy" ]    && printf '  Proxy %s\n' "$proxy"
        [ -n "$identity" ] && printf '  IdentityFile %s\n' "$identity"
    } >> "$conf"
}
