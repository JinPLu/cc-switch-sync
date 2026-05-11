#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_DIR="${HOME}/.cc-switch-sync"
SCRIPTS_DIR="${HOME}/.cc-switch/scripts"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo ""
echo -e "${CYAN}============================================="
echo "  cc-switch-sync Installer (macOS / Linux)"
echo -e "=============================================${NC}"
echo ""

# 1. Create config directory
mkdir -p "$SYNC_DIR"
echo -e "  ${GREEN}[+]${NC} Ensured $SYNC_DIR exists"

# 2. Copy servers template
if [[ ! -f "$SYNC_DIR/servers.json" ]]; then
    cp "$SCRIPT_DIR/examples/servers.example.json" "$SYNC_DIR/servers.json"
    echo -e "  ${GREEN}[+]${NC} Created $SYNC_DIR/servers.json (edit this with your servers)"
else
    echo -e "  ${YELLOW}[=]${NC} $SYNC_DIR/servers.json already exists, skipping"
fi

# 3. Install sync script
mkdir -p "$SCRIPTS_DIR"
cp "$SCRIPT_DIR/sync-to-server.sh" "$SCRIPTS_DIR/sync-to-server"
chmod +x "$SCRIPTS_DIR/sync-to-server"
echo -e "  ${GREEN}[+]${NC} Installed sync-to-server -> $SCRIPTS_DIR"

# 4. Add to PATH via shell profile
SHELL_RC=""
if [[ -f "${HOME}/.zshrc" ]]; then
    SHELL_RC="${HOME}/.zshrc"
elif [[ -f "${HOME}/.bashrc" ]]; then
    SHELL_RC="${HOME}/.bashrc"
elif [[ -f "${HOME}/.bash_profile" ]]; then
    SHELL_RC="${HOME}/.bash_profile"
fi

if [[ -n "$SHELL_RC" ]]; then
    PATH_LINE="export PATH=\"\${HOME}/.cc-switch/scripts:\$PATH\""
    if ! grep -qF ".cc-switch/scripts" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# cc-switch-sync" >> "$SHELL_RC"
        echo "$PATH_LINE" >> "$SHELL_RC"
        echo -e "  ${GREEN}[+]${NC} Added to PATH in $(basename "$SHELL_RC")"
        echo -e "  ${YELLOW}    (restart terminal for PATH to take effect)${NC}"
    else
        echo -e "  ${YELLOW}[=]${NC} PATH entry already in $(basename "$SHELL_RC")"
    fi
else
    echo -e "  ${YELLOW}[!]${NC} Could not detect shell config. Manually add to PATH:"
    echo "      export PATH=\"\${HOME}/.cc-switch/scripts:\$PATH\""
fi

# 5. Check dependencies
echo ""
echo "  Checking dependencies..."
for cmd in ssh scp jq; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${YELLOW}✗${NC} $cmd (install with: apt install $cmd / brew install $cmd)"
    fi
done

echo ""
echo -e "${GREEN}============================================="
echo "  Installation complete!"
echo ""
echo "  Next steps:"
echo -e "    1. Edit your server list:${NC}"
echo -e "       ${CYAN}\$EDITOR ~/.cc-switch-sync/servers.json${NC}"
echo ""
echo -e "${GREEN}    2. Open a NEW terminal, then run:"
echo -e "       ${CYAN}sync-to-server${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
