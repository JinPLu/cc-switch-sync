#!/usr/bin/env bash
# lib/plugin.sh — plugin loader and dispatcher.

CCR_PLUGINS_LOADED=""
CCR_PLUGIN_LIST=""    # space-separated list of loaded plugin names

# Discover and source plugins from $CCR_ROOT/plugins/*.sh, filtered by
# CFG_enable_plugins (comma list). Each plugin must set PLUGIN_NAME and
# define <name>_doctor / <name>_sync / <name>_history_paths directly.
ccr_load_plugins() {
    [ -n "$CCR_PLUGINS_LOADED" ] && return 0
    local dir="$CCR_ROOT/plugins"
    [ -d "$dir" ] || { CCR_PLUGINS_LOADED=1; return 0; }
    local enabled="${CFG_enable_plugins:-claude,codex}"
    # Convert comma list to space-padded form for case-matching.
    enabled=" ${enabled//,/ } "
    local f
    for f in "$dir"/*.sh; do
        [ -f "$f" ] || continue
        PLUGIN_NAME=""; PLUGIN_TITLE=""; PLUGIN_ENABLED_BY_DEFAULT=true
        # shellcheck disable=SC1090
        . "$f"
        [ -z "$PLUGIN_NAME" ] && continue
        case "$enabled" in
            *" $PLUGIN_NAME "*) ;;
            *) continue ;;
        esac
        local title="${PLUGIN_TITLE:-$PLUGIN_NAME}"
        eval "CCR_PLUGIN_TITLE_${PLUGIN_NAME}=\$title"
        CCR_PLUGIN_LIST="${CCR_PLUGIN_LIST}${CCR_PLUGIN_LIST:+ }$PLUGIN_NAME"
    done
    CCR_PLUGINS_LOADED=1
}

# Iterate enabled plugins.
ccr_plugins_each() {
    local cb="$1"
    local p
    for p in $CCR_PLUGIN_LIST; do
        "$cb" "$p"
    done
}

ccr_plugin_title() {
    local p="$1"
    local v; eval "v=\$CCR_PLUGIN_TITLE_${p}"
    [ -n "$v" ] && printf '%s' "$v" || printf '%s' "$p"
}

ccr_plugin_call() {
    local p="$1"; local fn="$2"; shift 2
    if declare -f "${p}_${fn}" >/dev/null 2>&1; then
        "${p}_${fn}" "$@"
        return $?
    fi
    return 0
}

ccr_plugin_has() {
    local p="$1"; local fn="$2"
    declare -f "${p}_${fn}" >/dev/null 2>&1
}
