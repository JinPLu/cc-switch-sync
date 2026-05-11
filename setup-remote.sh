#!/usr/bin/env bash
# Run this ON the remote server (one-time setup).
# Or from local: ssh -p PORT user@host 'bash -s' < setup-remote.sh
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo ""
echo -e "${CYAN}============================================="
echo "  cc-switch-sync: Remote Server Setup"
echo -e "=============================================${NC}"
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  DEB_ARCH="x86_64" ;;
    aarch64) DEB_ARCH="aarch64" ;;
    *)       echo -e "${RED}  [ERROR] Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

CC_VERSION="3.14.1"
DEB_URL="https://github.com/farion1231/cc-switch/releases/download/v${CC_VERSION}/CC-Switch-v${CC_VERSION}-Linux-${DEB_ARCH}.deb"
DEB_FILE="/tmp/CC-Switch-v${CC_VERSION}-Linux-${DEB_ARCH}.deb"

# 1. Install system dependencies
echo -e "  ${CYAN}[1/4]${NC} Installing system dependencies (xvfb, dbus-x11)..."
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq xvfb dbus-x11 >/dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} xvfb and dbus-x11 installed"
else
    echo -e "  ${YELLOW}[!]${NC} apt-get not found. Install xvfb and dbus-x11 manually."
fi

# 2. Download CC Switch
echo -e "  ${CYAN}[2/4]${NC} Downloading CC Switch v${CC_VERSION} (${DEB_ARCH})..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$DEB_URL" -o "$DEB_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$DEB_URL" -O "$DEB_FILE"
else
    echo -e "  ${RED}[ERROR]${NC} Neither curl nor wget found."
    echo "  Download manually: $DEB_URL"
    exit 1
fi

if [[ ! -s "$DEB_FILE" ]]; then
    echo -e "  ${RED}[ERROR]${NC} Download failed or file is empty."
    echo "  If behind a firewall, set https_proxy and retry, or download manually:"
    echo "    $DEB_URL"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Downloaded $(du -h "$DEB_FILE" | cut -f1)"

# 3. Install CC Switch
echo -e "  ${CYAN}[3/4]${NC} Installing CC Switch..."
dpkg -i "$DEB_FILE" 2>/dev/null || apt-get install -f -y -qq 2>/dev/null
if command -v cc-switch >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} CC Switch installed at $(which cc-switch)"
else
    echo -e "  ${RED}[ERROR]${NC} CC Switch installation failed."
    echo "  Try: dpkg -i $DEB_FILE && apt-get install -f -y"
    exit 1
fi

# 4. Create directories and set permissions
echo -e "  ${CYAN}[4/4]${NC} Creating directories..."
mkdir -p ~/.cc-switch ~/.claude ~/.codex
chmod 700 ~/.cc-switch ~/.claude ~/.codex
echo -e "  ${GREEN}✓${NC} Directories ready with secure permissions"

# Cleanup
rm -f "$DEB_FILE"

echo ""
echo -e "${GREEN}============================================="
echo "  Remote setup complete!"
echo ""
echo "  This server is ready to receive configs"
echo "  from cc-switch-sync."
echo ""
echo "  From your local machine, run:"
echo "    sync-to-server"
echo -e "=============================================${NC}"
echo ""
