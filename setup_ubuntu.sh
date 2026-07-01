#!/usr/bin/env bash

# setup_ubuntu.sh
# 
# Installs development dependencies, IDE environments, and a browser-accessible
# desktop directly on Ubuntu 26 LTS based on the environment defined in the 
# sandbox Dockerfile.
#
# Usage: sudo ./setup_ubuntu.sh [options]

set -euo pipefail

# ── Color logging helpers ────────────────────────────────────────────────────
log_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}
log_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}
log_warn() {
    echo -e "\e[33m[WARNING]\e[0m $1"
}
log_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
}

# ── Root checks ──────────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run with sudo or as root."
    echo "Usage: sudo ./setup_ubuntu.sh [options]"
    exit 1
fi

# Detect non-root invoking user and home directory
TARGET_USER="${SUDO_USER:-$(whoami)}"
if [ "$TARGET_USER" = "root" ]; then
    TARGET_HOME="/root"
else
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
fi

# ── Parse arguments ──────────────────────────────────────────────────────────
INSTALL_VSCODE=false
INSTALL_WINDSURF=false
INSTALL_DESKTOP=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-desktop)
            INSTALL_DESKTOP=false
            shift
            ;;
        --with-vscode)
            INSTALL_VSCODE=true
            shift
            ;;
        --with-windsurf)
            INSTALL_WINDSURF=true
            shift
            ;;
        --all)
            INSTALL_VSCODE=true
            INSTALL_WINDSURF=true
            shift
            ;;
        -h|--help)
            echo "Usage: sudo ./setup_ubuntu.sh [options]"
            echo "Options:"
            echo "  --no-desktop     Skip installing browser-accessible XFCE desktop (noVNC)"
            echo "  --with-vscode    Also install VS Code"
            echo "  --with-windsurf  Also install Windsurf IDE"
            echo "  --all            Install all optional IDEs (VS Code & Windsurf)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

echo "========================================================="
echo " Installing Sandbox Tools & Desktop Directly on Ubuntu"
echo " Target User: $TARGET_USER"
echo " Home Directory: $TARGET_HOME"
echo " Install Desktop: $INSTALL_DESKTOP"
echo "========================================================="

# Ensure apt is ready and non-interactive
export DEBIAN_FRONTEND=noninteractive

# ── 1. Basic tools + Chromium ──────────────────────────────────────────────────
log_info "Installing basic tools..."
apt-get update
apt-get install -y \
    curl gnupg wget apt-transport-https ca-certificates \
    git python3 python3-pip python3-venv build-essential \
    vim htop unzip zip software-properties-common openssl

log_info "Adding xtradeb PPA and installing Chromium..."
add-apt-repository -y ppa:xtradeb/apps
apt-get update
apt-get install -y chromium

# Set default browser environment variable
if ! grep -q "BROWSER=" /etc/environment; then
    echo "BROWSER=/usr/bin/chromium" >> /etc/environment
    log_info "Set system-wide BROWSER=/usr/bin/chromium in /etc/environment"
fi

# ── 2. Python 3.12 ─────────────────────────────────────────────────────────────
log_info "Adding deadsnakes PPA and installing Python 3.12..."
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.12 python3.12-venv python3.12-dev

# ── 3. Node.js 20 LTS ──────────────────────────────────────────────────────────
log_info "Adding NodeSource repository and installing Node.js 20..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs

# ── 4. VS Code (Optional) ──────────────────────────────────────────────────────
if [ "$INSTALL_VSCODE" = true ]; then
    log_info "Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list
    apt-get update
    apt-get install -y code
else
    log_info "Skipping VS Code installation. (Pass --with-vscode to install)"
fi

# ── 5. Windsurf (Optional) ─────────────────────────────────────────────────────
if [ "$INSTALL_WINDSURF" = true ]; then
    log_info "Installing Windsurf..."
    wget -qO- https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg \
        | gpg --dearmor --yes -o /etc/apt/keyrings/windsurf-stable.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" \
        > /etc/apt/sources.list.d/windsurf.list
    apt-get update
    apt-get install -y windsurf
else
    log_info "Skipping Windsurf installation. (Pass --with-windsurf to install)"
fi

# ── 6. Antigravity IDE ──────────────────────────────────────────────────────────
log_info "Setting up Antigravity IDE..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/update_antigravity_ide.sh" ]; then
    cp "$SCRIPT_DIR/update_antigravity_ide.sh" /usr/local/bin/update_antigravity_ide.sh
    chmod +x /usr/local/bin/update_antigravity_ide.sh
    log_info "Running update_antigravity_ide.sh..."
    /usr/local/bin/update_antigravity_ide.sh
else
    log_warn "update_antigravity_ide.sh not found in script directory ($SCRIPT_DIR). Skipping Antigravity IDE installation."
fi

# ── 7. Docker Engine ───────────────────────────────────────────────────────────
log_info "Installing Docker Engine..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Setup group permissions for target user
log_info "Configuring Docker group membership for user: $TARGET_USER..."
groupadd -f docker
usermod -aG docker "$TARGET_USER"

# ── 8. Create workspace directory ──────────────────────────────────────────────
log_info "Creating /workspace directory..."
mkdir -p /workspace
chown -R "$TARGET_USER:$TARGET_USER" /workspace

# ── 9. Native Browser-Accessible Desktop Setup (noVNC + TigerVNC) ──────────────
if [ "$INSTALL_DESKTOP" = true ]; then
    log_info "Installing native XFCE Desktop, TigerVNC, and noVNC..."
    apt-get install -y \
        xfce4 xfce4-goodies \
        tigervnc-standalone-server tigervnc-common \
        novnc python3-websockify python3-numpy

    # Create VNC directories for target user
    log_info "Configuring XFCE startup script for user '$TARGET_USER'..."
    sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.vnc"
    
    # Write xstartup script
    cat << 'EOF' > "$TARGET_HOME/.vnc/xstartup"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xrdb $HOME/.Xresources 2>/dev/null || true
xsetroot -solid grey
exec startxfce4
EOF
    chmod +x "$TARGET_HOME/.vnc/xstartup"
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.vnc/xstartup"

    # Set default VNC password ('antigravity') if not already configured
    if [ ! -f "$TARGET_HOME/.vnc/passwd" ]; then
        log_info "Setting default VNC password ('antigravity') for user '$TARGET_USER'..."
        echo -e "antigravity\nantigravity\nn" | sudo -u "$TARGET_USER" vncpasswd >/dev/null 2>&1 || true
        chmod 600 "$TARGET_HOME/.vnc/passwd" 2>/dev/null || true
        chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.vnc/passwd" 2>/dev/null || true
    fi

    # Generate self-signed SSL certificate for HTTPS
    if [ ! -f "$TARGET_HOME/.vnc/novnc.pem" ]; then
        log_info "Generating self-signed SSL certificate for noVNC HTTPS..."
        openssl req -new -x509 -days 365 -nodes \
            -out "$TARGET_HOME/.vnc/novnc.pem" \
            -keyout "$TARGET_HOME/.vnc/novnc.pem" \
            -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=localhost" >/dev/null 2>&1 || true
        chmod 600 "$TARGET_HOME/.vnc/novnc.pem" 2>/dev/null || true
        chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.vnc/novnc.pem" 2>/dev/null || true
    fi

    # Create start-desktop command-line tool
    log_info "Creating '/usr/local/bin/start-desktop' command..."
    cat << 'EOF' > /usr/local/bin/start-desktop
#!/usr/bin/env bash
#
# start-desktop
# Starts VNC server and dual noVNC proxies to serve a browser-accessible XFCE desktop
# over HTTP (port 3000) and HTTPS (port 3001).

set -euo pipefail

# Rerun as target user if called via sudo/root
if [ "$(id -u)" -eq 0 ]; then
    RUN_USER="${SUDO_USER:-}"
    if [ -z "$RUN_USER" ] || [ "$RUN_USER" = "root" ]; then
        # Find first non-root UID >= 1000
        RUN_USER=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1; exit}' /etc/passwd)
    fi
    if [ -z "$RUN_USER" ]; then
        echo "Error: No standard non-root user found. Cannot start desktop." >&2
        exit 1
    fi
    exec sudo -u "$RUN_USER" HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)" "$0" "$@"
fi

DISPLAY_NUM=":1"
VNC_PORT="5901"
WEB_PORT_HTTP="3000"
WEB_PORT_HTTPS="3001"
CERT_FILE="$HOME/.vnc/novnc.pem"

echo "========================================================="
echo " Starting Native Desktop Sandbox"
echo " User:         $(whoami)"
echo " Display:      $DISPLAY_NUM (VNC Port: $VNC_PORT)"
echo " HTTP Server:  http://localhost:$WEB_PORT_HTTP/vnc.html"
echo " HTTPS Server: https://localhost:$WEB_PORT_HTTPS/vnc.html"
echo "========================================================="

# 1. Clear any stale VNC socket
vncserver -kill "$DISPLAY_NUM" >/dev/null 2>&1 || true

# 2. Start VNC server (listening on localhost only for security)
vncserver "$DISPLAY_NUM" -geometry 1280x800 -localhost yes

# 3. Launch noVNC HTTP proxy (port 3000) in the background
echo "Launching HTTP browser proxy on port $WEB_PORT_HTTP..."
HTTP_PID=""
if [ -f /usr/share/novnc/utils/novnc_proxy ]; then
    /usr/share/novnc/utils/novnc_proxy --vnc localhost:"$VNC_PORT" --listen "$WEB_PORT_HTTP" >/dev/null 2>&1 &
    HTTP_PID=$!
elif command -v websockify >/dev/null 2>&1; then
    websockify --web=/usr/share/novnc/ "$WEB_PORT_HTTP" localhost:"$VNC_PORT" >/dev/null 2>&1 &
    HTTP_PID=$!
fi

# Define cleanup trap to stop VNC and the background proxy
cleanup() {
    echo "Stopping desktop proxies..."
    if [ -n "$HTTP_PID" ]; then
        kill "$HTTP_PID" 2>/dev/null || true
    fi
    vncserver -kill "$DISPLAY_NUM" >/dev/null 2>&1 || true
}
trap cleanup EXIT SIGINT SIGTERM

# 4. Launch noVNC HTTPS proxy (port 3001) in the foreground
echo "Launching HTTPS browser proxy on port $WEB_PORT_HTTPS..."
if [ -f "$CERT_FILE" ]; then
    if [ -f /usr/share/novnc/utils/novnc_proxy ]; then
        /usr/share/novnc/utils/novnc_proxy --vnc localhost:"$VNC_PORT" --listen "$WEB_PORT_HTTPS" --cert "$CERT_FILE"
    elif command -v websockify >/dev/null 2>&1; then
        exec websockify --web=/usr/share/novnc/ --cert="$CERT_FILE" --key="$CERT_FILE" "$WEB_PORT_HTTPS" localhost:"$VNC_PORT"
    else
        echo "Error: noVNC proxy script/websockify not found." >&2
        exit 1
    fi
else
    echo "Warning: SSL Certificate $CERT_FILE not found. HTTPS server cannot start."
    # If no cert, sleep in foreground to keep script alive and maintain trap
    while true; do sleep 1; done
fi
EOF
    chmod +x /usr/local/bin/start-desktop
    log_success "Desktop environment configured! You can run 'start-desktop' to launch it."
else
    log_info "Skipping desktop environment configuration (passed --no-desktop)."
fi

# ── 10. Install Extensions ──────────────────────────────────────────────────────
log_info "Installing IDE extensions for user: $TARGET_USER..."

EXTENSIONS=(
    "ms-vscode.live-server"
    "yzhang.markdown-all-in-one"
    "robole.marky-stats"
)

# Install to VS Code if code CLI is available
if command -v code >/dev/null 2>&1; then
    log_info "Installing extensions for VS Code..."
    for ext in "${EXTENSIONS[@]}"; do
        sudo -u "$TARGET_USER" HOME="$TARGET_HOME" code --install-extension "$ext" --force || true
    done
fi

# Install to Antigravity IDE if CLI is available
if command -v antigravity-ide >/dev/null 2>&1; then
    log_info "Installing extensions for Antigravity IDE..."
    for ext in "${EXTENSIONS[@]}"; do
        sudo -u "$TARGET_USER" HOME="$TARGET_HOME" antigravity-ide --install-extension "$ext" || true
    done
fi

# Install to Windsurf if CLI is available
if command -v windsurf >/dev/null 2>&1; then
    log_info "Installing extensions for Windsurf..."
    for ext in "${EXTENSIONS[@]}"; do
        sudo -u "$TARGET_USER" HOME="$TARGET_HOME" windsurf --install-extension "$ext" || true
    done
fi

echo "========================================================="
log_success "Installation complete!"
if [ "$INSTALL_DESKTOP" = true ]; then
    log_info "To access your desktop via web browser:"
    log_info "  1. Run the command:  start-desktop"
    log_info "  2. Open HTTP link:   http://localhost:3000/vnc.html"
    log_info "  3. Open HTTPS link:  https://localhost:3001/vnc.html"
    log_info "  4. Use VNC password: antigravity"
fi
log_warn "IMPORTANT: To run Docker commands without sudo, please log out"
log_warn "and log back in, or run: newgrp docker"
echo "========================================================="
