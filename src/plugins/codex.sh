#!/usr/bin/env bash
# plugins/codex.sh — Codex provider sync plugin.

PLUGIN_NAME="codex"
PLUGIN_TITLE="Codex"
PLUGIN_ENABLED_BY_DEFAULT=true

_ccr_codex_local_config() { printf '%s' "$HOME/.codex/config.toml"; }
_ccr_codex_local_auth()   { printf '%s' "$HOME/.codex/auth.json"; }

codex_doctor() {
    local cfg auth rc=0
    cfg="$(_ccr_codex_local_config)"
    auth="$(_ccr_codex_local_auth)"
    if [ -f "$cfg" ]; then
        ccr_status OK "Codex config found: $cfg"
    else
        ccr_status WARN "Codex config not found; Codex sync will be skipped."
        rc=1
    fi
    if [ -f "$auth" ]; then
        ccr_status OK "Codex auth.json found."
    else
        ccr_status WARN "Codex auth.json not found; Codex auth sync will be skipped."
    fi
    return $rc
}

codex_sync() {
    if [ "${1:-}" = "--summary" ]; then
        printf 'Codex:  overwrite ~/.codex/config.toml (auth.json optional)\n'
        return 0
    fi

    # Honor config flags.
    case "${CFG_sync_codex:-true}" in
        true|1|yes) : ;;
        *) ccr_status SKIP "Codex sync disabled by config.ini."; return 0 ;;
    esac

    local cfg auth
    cfg="$(_ccr_codex_local_config)"
    auth="$(_ccr_codex_local_auth)"

    if [ ! -f "$cfg" ]; then
        ccr_status WARN "Codex config.toml missing; skipping Codex sync."
        return 0
    fi
    ccr_spin "Uploading Codex config.toml" \
        ccr_upload "$cfg" "/tmp/ccrk-config.toml" || return $?

    local upload_auth=0
    if [ -f "$auth" ]; then
        case "${CFG_sync_codex_auth:-confirm}" in
            true|1|yes) upload_auth=1 ;;
            false|0|no) upload_auth=0 ;;
            confirm|*)
                if ccr_confirm "Upload and overwrite remote Codex auth.json?" 0; then
                    upload_auth=1
                fi
                ;;
        esac
    fi
    if [ "$upload_auth" = "1" ]; then
        ccr_spin "Uploading Codex auth.json" \
            ccr_upload "$auth" "/tmp/ccrk-auth.json" || return $?
    fi

    ccr_spin "Installing Codex config on remote" ccr_remote "$(cat <<'EOSH'
set -e
mkdir -p ~/.codex
if [ -f /tmp/ccrk-config.toml ]; then
  cp /tmp/ccrk-config.toml ~/.codex/config.toml
  chmod 600 ~/.codex/config.toml
  rm -f /tmp/ccrk-config.toml
fi
if [ -f /tmp/ccrk-auth.json ]; then
  cp /tmp/ccrk-auth.json ~/.codex/auth.json
  chmod 600 ~/.codex/auth.json
  rm -f /tmp/ccrk-auth.json
fi
EOSH
)" || return $?

    # Verify.
    ccr_remote "$(cat <<'EOSH'
if [ -f ~/.codex/config.toml ]; then
  grep -E '^(model_provider|model|base_url) = ' ~/.codex/config.toml | sed 's/^/    /' || true
else
  echo '    config.toml: NOT SET'
fi
[ -f ~/.codex/auth.json ] && echo '    auth.json: present' || echo '    auth.json: missing'
EOSH
)"
}

codex_history_paths() {
    local include_codex="${CFG_history_include_codex:-false}"
    if [ "${CCR_HISTORY_INCLUDE_CODEX:-$include_codex}" = "true" ]; then
        printf '%s\n' \
            '.codex/sessions' \
            '.codex/archived_sessions' \
            '.codex/history.jsonl' \
            '.codex/session_index.jsonl'
    fi
}
