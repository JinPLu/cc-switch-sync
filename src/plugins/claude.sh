#!/usr/bin/env bash
# plugins/claude.sh — Claude Code provider sync plugin.

PLUGIN_NAME="claude"
PLUGIN_TITLE="Claude Code"
PLUGIN_ENABLED_BY_DEFAULT=true

# Local Claude paths.
_ccr_claude_local_settings() {
    printf '%s' "$HOME/.claude/settings.json"
}

claude_doctor() {
    local p; p="$(_ccr_claude_local_settings)"
    if [ -f "$p" ]; then
        ccr_status OK "Claude settings found: $p"
        return 0
    fi
    ccr_status ERR "Claude settings not found: $p"
    printf '    %sOpen Claude / CC Switch locally, pick a Provider, then retry.%s\n' "$CCR_DIM" "$CCR_RESET"
    return 1
}

# claude_sync — upload + merge env on remote.
# Echos a "summary line" first when called with --summary; performs upload otherwise.
claude_sync() {
    if [ "${1:-}" = "--summary" ]; then
        printf 'Claude: merge env block in ~/.claude/settings.json\n'
        return 0
    fi
    local local_settings; local_settings="$(_ccr_claude_local_settings)"
    if [ ! -f "$local_settings" ]; then
        ccr_status ERR "Missing local Claude settings: $local_settings"
        return 1
    fi
    ccr_spin "Uploading Claude settings.json" \
        ccr_upload "$local_settings" "/tmp/ccrk-settings.json" || return $?
    ccr_spin "Merging env on remote" ccr_remote "$(cat <<'EOSH'
set -e
python3 - <<'PY'
import json, os
src = '/tmp/ccrk-settings.json'
dst = os.path.expanduser('~/.claude/settings.json')
local = json.load(open(src))
remote = json.load(open(dst)) if os.path.exists(dst) else {}
remote['env'] = local.get('env', {})
os.makedirs(os.path.dirname(dst), exist_ok=True)
open(dst, 'w').write(json.dumps(remote, indent=2))
os.remove(src)
PY
EOSH
)" || return $?
    # Verify.
    ccr_remote "$(cat <<'EOSH'
python3 - <<'PY'
import json, os
p = os.path.expanduser('~/.claude/settings.json')
d = json.load(open(p))
env = d.get('env', {})
print('    ANTHROPIC_BASE_URL:', env.get('ANTHROPIC_BASE_URL', 'NOT SET'))
print('    ANTHROPIC_MODEL:',    env.get('ANTHROPIC_MODEL',    'NOT SET'))
PY
EOSH
)"
}

# claude_history_paths — return remote tar paths for history download.
claude_history_paths() {
    printf '%s\n' \
        '.claude/projects' \
        '.claude/sessions' \
        '.claude/history.jsonl' \
        '.claude.json'
}
