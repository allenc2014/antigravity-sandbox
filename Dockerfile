FROM kasmweb/core-ubuntu-jammy:1.16.0

USER root

# Install basic tools and add PPA for native Chromium
RUN apt-get update && apt-get install -y \
    curl gnupg wget apt-transport-https ca-certificates \
    git python3 python3-pip python3-venv build-essential \
    vim htop unzip zip software-properties-common \
    && add-apt-repository -y ppa:xtradeb/apps \
    && apt-get update && apt-get install -y chromium \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Fix Chromium sandbox issues inside Kasm/Docker containers
ENV CHROMIUM_FLAGS="--no-sandbox"

# Set it as the default browser globally
ENV BROWSER=/usr/bin/chromium

# Python 3.12 (via deadsnakes PPA)
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.12 python3.12-venv python3.12-dev \
    && apt-get clean

# Node.js (Latest LTS)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install nodejs -y

# VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && apt-get install -y code

# 1Password
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' > /etc/apt/sources.list.d/1password.list && \
    mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
    mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
    apt-get update && apt-get install -y 1password

# Antigravity
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" > /etc/apt/sources.list.d/antigravity.list && \
    apt-get update && apt-get install -y antigravity

# Create workspace
RUN mkdir -p /workspace && chown -R kasm-user:kasm-user /workspace

USER kasm-user
