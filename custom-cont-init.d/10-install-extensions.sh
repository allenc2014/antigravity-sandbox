#!/bin/bash
# /custom-cont-init.d/10-install-extensions.sh
#
# Runs as root at every container start (before the XFCE desktop session).
# Installs VS Code & Antigravity IDE extensions for the "abc" user on first run.
# /config is abc's home directory (persisted via volume mount).

set -euo pipefail

MARKER="/config/.extensions-installed"

if [ -f "$MARKER" ]; then
    echo "[init] IDE extensions already installed — skipping."
    exit 0
fi

echo "[init] Installing VS Code extensions for abc..."
sudo -u abc HOME=/config code \
    --install-extension ms-vscode.live-server \
    --install-extension yzhang.markdown-all-in-one \
    --install-extension robole.marky-stats \
    --force

echo "[init] Installing Antigravity IDE extensions for abc..."
sudo -u abc HOME=/config antigravity-ide \
    --install-extension ms-vscode.live-server \
    --install-extension yzhang.markdown-all-in-one \
    --install-extension robole.marky-stats

echo "[init] Installing Windsurf extensions for abc..."
sudo -u abc HOME=/config windsurf \
    --install-extension ms-vscode.live-server \
    --install-extension yzhang.markdown-all-in-one \
    --install-extension robole.marky-stats

touch "$MARKER"
echo "[init] IDE extensions installed successfully."
