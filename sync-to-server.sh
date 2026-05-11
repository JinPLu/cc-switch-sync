#!/usr/bin/env bash
set -euo pipefail

SERVERS_FILE="${HOME}/.cc-switch-sync/servers.json"
CC_DB="${HOME}/.cc-switch/cc-switch.db"
WAIT_SECONDS=7
XVFB_DISPLAY=":99"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

banner() {
    echo ""
    echo -e "${CYAN}============================================="
    echo "  CC Switch - Sync Provider Config to Server"
    echo -e "=============================================${NC}"
    echo ""
}

die() { echo -e "${RED}  [ERROR] $*${NC}" >&2; exit 1; }
info() { echo -e "  $*"; }
ok() { echo -e "  ${GREEN}$*${NC}"; }
warn() { echo -e "  ${YELLOW}$*${NC}"; }

banner

# --- Pre-checks ---
[[ -f "$CC_DB" ]] || die "CC Switch database not found: $CC_DB
  Install and configure CC Switch first: https://github.com/farion1231/cc-switch/releases"

[[ -f "$SERVERS_FILE" ]] || die "Server list not found: $SERVERS_FILE
  Run install.sh first, or copy examples/servers.example.json to $SERVERS_FILE and edit it."

command -v jq >/dev/null 2>&1 || die "jq is required. Install: apt install jq / brew install jq"

# --- Parse servers ---
SERVER_COUNT=$(jq '.servers | length' "$SERVERS_FILE")
[[ "$SERVER_COUNT" -gt 0 ]] || die "No servers configured in $SERVERS_FILE"

get_field() { jq -r ".servers[$1].$2" "$SERVERS_FILE"; }

sync_one() {
    local idx=$1
    local name; name=$(get_field "$idx" name)
    local user; user=$(get_field "$idx" user)
    local host; host=$(get_field "$idx" host)
    local port; port=$(get_field "$idx" port)

    echo -e "  Target: ${CYAN}${user}@${host}:${port}${NC}  [${name}]"
    echo ""

    # Step 1
    info "[1/4] Copying CC Switch DB to server..."
    scp -P "$port" -o ConnectTimeout=10 "$CC_DB" "${user}@${host}:~/.cc-switch/cc-switch.db" 2>/dev/null \
        || die "SCP failed. Try: ssh -p $port $user@$host"
    ok "  DB copied successfully."
    echo ""

    # Step 2
    info "[2/4] Starting CC Switch on server (Xvfb) to write configs..."
    info "  Waiting ${WAIT_SECONDS}s for configs to be written..."
    ssh -p "$port" -o ConnectTimeout=10 "${user}@${host}" bash -s <<REMOTE_EOF
pkill -f "Xvfb ${XVFB_DISPLAY}" 2>/dev/null || true
sleep 0.5
Xvfb ${XVFB_DISPLAY} -screen 0 1024x768x24 >/dev/null 2>&1 &
sleep 1
DISPLAY=${XVFB_DISPLAY} cc-switch >/dev/null 2>&1 &
sleep ${WAIT_SECONDS}
pkill -f cc-switch 2>/dev/null || true
pkill -f "Xvfb ${XVFB_DISPLAY}" 2>/dev/null || true
echo "  done"
REMOTE_EOF
    echo ""

    # Step 3
    info "[3/4] Patching codex config (remove local proxy references)..."
    ssh -p "$port" -o ConnectTimeout=10 "${user}@${host}" bash -s <<'PATCH_EOF'
if [ -f ~/.codex/config.toml ]; then
    if grep -q "http://127.0.0.1:15721" ~/.codex/config.toml; then
        echo "  WARNING: Found local proxy URL in codex config. This won't work on remote."
        echo "  You should set enableLocalProxy=off in CC Switch settings and re-sync."
    fi
fi
chmod 600 ~/.codex/auth.json ~/.claude/settings.json ~/.cc-switch/cc-switch.db 2>/dev/null || true
echo "  Permissions tightened."
PATCH_EOF
    echo ""

    # Step 4
    info "[4/4] Verifying..."
    echo "  --- Claude Code ---"
    ssh -p "$port" -o ConnectTimeout=10 "${user}@${host}" \
        "grep -E 'ANTHROPIC_BASE_URL|ANTHROPIC_AUTH_TOKEN' ~/.claude/settings.json 2>/dev/null | head -4 | sed 's/^/  /'" \
        || warn "  (no Claude settings found)"
    echo "  --- Codex ---"
    ssh -p "$port" -o ConnectTimeout=10 "${user}@${host}" \
        "grep -E 'base_url|model =' ~/.codex/config.toml 2>/dev/null | head -6 | sed 's/^/  /'" \
        || warn "  (no Codex config found)"

    echo ""
    echo -e "${GREEN}============================================="
    echo "  Done! Provider config synced to [${name}]."
    echo "  - claude: takes effect immediately"
    echo "  - codex:  restart terminal to apply"
    echo -e "=============================================${NC}"
}

# --- Handle arguments ---
if [[ "${1:-}" == "--all" ]]; then
    info "Syncing to ALL $SERVER_COUNT server(s)..."
    echo ""
    for ((i=0; i<SERVER_COUNT; i++)); do
        sync_one "$i"
        echo ""
    done
    exit 0
fi

if [[ -n "${1:-}" ]]; then
    for ((i=0; i<SERVER_COUNT; i++)); do
        n=$(get_field "$i" name)
        if [[ "$n" == "$1" ]]; then
            sync_one "$i"
            exit 0
        fi
    done
    die "Server \"$1\" not found in $SERVERS_FILE"
fi

# --- Interactive menu ---
info "Available servers:"
info "-------------------"
for ((i=0; i<SERVER_COUNT; i++)); do
    n=$(get_field "$i" name)
    u=$(get_field "$i" user)
    h=$(get_field "$i" host)
    p=$(get_field "$i" port)
    echo "  $((i+1)). $n  ($u@$h:$p)"
done
ADD_IDX=$((SERVER_COUNT+1))
echo "  $ADD_IDX. [+ Add new server]"
echo ""

read -rp "  Select [1-$ADD_IDX]: " CHOICE

if [[ "$CHOICE" == "$ADD_IDX" ]]; then
    read -rp "  Name (e.g. lab-gpu): " NEW_NAME
    read -rp "  Host (e.g. 10.0.1.50): " NEW_HOST
    read -rp "  Port (default 22): " NEW_PORT
    read -rp "  User (default root): " NEW_USER
    NEW_PORT=${NEW_PORT:-22}
    NEW_USER=${NEW_USER:-root}
    TMP=$(mktemp)
    jq --arg n "$NEW_NAME" --arg h "$NEW_HOST" --argjson p "$NEW_PORT" --arg u "$NEW_USER" \
        '.servers += [{"name":$n,"host":$h,"port":$p,"user":$u}]' "$SERVERS_FILE" > "$TMP" \
        && mv "$TMP" "$SERVERS_FILE"
    ok "  Server added: $NEW_NAME ($NEW_USER@$NEW_HOST:$NEW_PORT)"
    info "  Re-run sync-to-server to sync to the new server."
    exit 0
fi

IDX=$((CHOICE-1))
if [[ $IDX -lt 0 || $IDX -ge $SERVER_COUNT ]]; then
    die "Invalid selection."
fi
sync_one "$IDX"
