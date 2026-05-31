FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# All build steps run as root (linuxserver default during build).
# The desktop session user is "abc" — consistent everywhere, no hyphen/underscore ambiguity.
# Configure PUID / PGID at runtime to map "abc" to your host UID:
#   docker run -e PUID=1000 -e PGID=1000 ...

# ── Basic tools + Chromium ───────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
        curl gnupg wget apt-transport-https ca-certificates \
        git python3 python3-pip python3-venv build-essential \
        vim htop unzip zip software-properties-common \
    && add-apt-repository -y ppa:xtradeb/apps \
    && apt-get update && apt-get install -y chromium \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Fix Chromium sandbox issues inside Docker containers
ENV CHROMIUM_FLAGS="--no-sandbox"
ENV BROWSER=/usr/bin/chromium

# ── Python 3.12 ─────────────────────────────────────────────────────────────
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
        python3.12 python3.12-venv python3.12-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Node.js 20 LTS ──────────────────────────────────────────────────────────
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── VS Code ──────────────────────────────────────────────────────────────────
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && apt-get install -y code && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Windsurf ─────────────────────────────────────────────────────────────────
RUN wget -qO- https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg \
        | gpg --dearmor > /etc/apt/keyrings/windsurf-stable.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" \
        > /etc/apt/sources.list.d/windsurf.list && \
    apt-get update && apt-get install -y windsurf && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Antigravity IDE ──────────────────────────────────────────────────────────
COPY update_antigravity_ide.sh /usr/local/bin/update_antigravity_ide.sh
RUN chmod +x /usr/local/bin/update_antigravity_ide.sh && \
    /usr/local/bin/update_antigravity_ide.sh

# ── Docker Engine (Docker-in-Docker) ─────────────────────────────────────────
# Requires --privileged at runtime (see docker-compose.yml).
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Allow abc to use docker without sudo
RUN groupadd -f docker && usermod -aG docker abc

# ── Workspace ────────────────────────────────────────────────────────────────
RUN mkdir -p /workspace && chown -R abc:abc /workspace

# ── First-run init: install IDE extensions for abc ───────────────────────────
# /custom-cont-init.d/ scripts run as root at every container start (before the
# desktop session). The marker file prevents re-installing on subsequent starts.
COPY --chmod=755 custom-cont-init.d/10-install-extensions.sh /custom-cont-init.d/10-install-extensions.sh
