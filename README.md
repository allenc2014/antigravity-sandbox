# antigravity-sandbox

A browser-accessible Linux desktop sandbox powered by [linuxserver/webtop](https://docs.linuxserver.io/images/docker-webtop/), pre-loaded with Antigravity IDE and a curated developer toolset.

> [!CAUTION]
> **Safety Disclaimer & Motivation**
>
> AI coding agents (like Antigravity) are highly agentic and possess broad command-line execution privileges. If not carefully isolated, a misbehaving agent or a misinterpreted prompt can run destructive commands, potentially causing irreparable damage or deleting files on your host system. 
> 
> This sandbox project was created after a real-world incident where the Antigravity agent deleted entire projects on my home server. Running the agent inside this containerized, isolated desktop environment ensures that any accidental file deletion or system alteration is safely contained within the sandbox.
> 
> **Use at your own risk. This project is provided "as is" without warranty of any kind.**

## What's included

| Tool | Details |
|---|---|
| **Antigravity IDE** | Latest 2.0.x, installed via `update_antigravity_ide.sh` at build time |
| **Windsurf** | Latest stable, with Live Server, Markdown All-in-One, Marky Stats extensions |
| **VS Code** | Latest stable, with Live Server, Markdown All-in-One, Marky Stats extensions |
| **Chromium** | Native (via xtradeb PPA), sandboxing disabled for container compatibility |
| **Python** | `python3` (system) + Python 3.12 (via deadsnakes PPA) |
| **Node.js** | v20 LTS |
| **Docker** | Docker Engine + Compose plugin (Docker-in-Docker via `--privileged`) |
| **Desktop** | XFCE4, accessible in the browser via webtop (KasmVNC) |

## Quick start

```bash
# Clone the repo
git clone <repo-url>
cd antigravity-sandbox

# Build and start
docker compose up -d --build

# Open the desktop in your browser (Must use HTTP, not HTTPS)
# Default Username: abc
# Default Password: antigravity  (set PASSWORD= in docker-compose.yml to change)
open http://localhost:3000
```

> **First run:** VS Code and Antigravity IDE extensions are installed automatically
> on the first container start. This takes ~30 seconds before the desktop is fully ready.

## Running on Windows (WSL 2 with Ubuntu)

To run this sandbox on Windows, use **WSL 2** with **Ubuntu**.

1. **Clone in the Linux filesystem**: For optimal performance and to avoid file permission issues, do not clone the repository in the Windows host mount (`/mnt/c/...`). Instead, clone it inside your WSL user home directory:
   ```bash
   cd ~
   git clone <repo-url>
   cd antigravity-sandbox
   ```
2. **Setup Docker**:
   * **If using Docker Desktop**: Ensure Docker Desktop is running on Windows and WSL integration is enabled for your Ubuntu distro under **Settings > Resources > WSL integration**.
   * **If using Docker Engine installed directly in WSL**: Ensure the docker service is running inside Ubuntu:
     ```bash
     sudo service docker start
     ```
3. **Build and start**:
   ```bash
   docker compose up -d --build
   ```
4. **Access the desktop**: Open your Windows web browser and navigate to `http://localhost:3000`.

## Native Ubuntu 26 LTS Setup (Without Docker)

If you prefer to install these tools directly on your Ubuntu 26 LTS host (or inside an Ubuntu WSL 2 instance) instead of running them via Docker, a setup script is provided.

This script installs all the packages and configurations matching the Docker container setup:
* XFCE Desktop, TigerVNC, and noVNC (enabled by default, provides browser-based desktop access on port 3000)
* Basic utilities & PPA repositories
* Chromium browser (via `xtradeb/apps` PPA)
* Python 3.12 (via `deadsnakes/ppa` PPA)
* Node.js 20 LTS
* Antigravity IDE (via `update_antigravity_ide.sh`)
* Docker Engine (with user group configurations)
* Pre-configured extensions for VS Code, Windsurf, and Antigravity IDE (if the IDEs are installed)

To run the installation:

```bash
# Run the script with sudo
sudo ./setup_ubuntu.sh [options]
```

### Options:
* `--no-desktop`: Skip installing browser-accessible XFCE desktop environment and noVNC.
* `--with-vscode`: Install VS Code IDE alongside other tools.
* `--with-windsurf`: Install Windsurf IDE alongside other tools.
* `--all`: Install all optional IDEs (VS Code & Windsurf).

### Launching the Browser-Accessible Desktop:
If the desktop environment was installed, you can start the native sandbox desktop from your terminal:

```bash
# Start the VNC server & noVNC web proxy
start-desktop
```

Then open your browser and navigate to one of the following URLs:
* **HTTP:** `http://localhost:3000/vnc.html`
* **HTTPS:** `https://localhost:3001/vnc.html`

* Default Password: `antigravity`

## Configuration

To customize your sandbox settings, copy the example environment file to `.env`:

```bash
cp .env.example .env
```

### Environment Variables (`.env`)

Modify `.env` to configure the desktop session and Git identity:

| Variable | Description | Default / Example |
|---|---|---|
| `TZ` | Timezone database name | `America/New_York` |
| `PASSWORD` | Password for browser login (`abc` user) | `antigravity` |
| `GIT_USER_NAME` | Git name configured on container startup | `Your Name` |
| `GIT_USER_EMAIL` | Git email configured on container startup | `you@example.com` |
| `GIT_CREDENTIAL_HELPER` | Git credential storage method (`store`, `cache`, or leave blank) | `store` |
| `GIT_CREDENTIAL_CACHE_TIMEOUT` | Time in seconds `cache` helper remembers credentials | `900` |

### User mapping (PUID / PGID)

The desktop session runs as user `abc`. If your host user UID and GID are not `1000`, map them in `docker-compose.yml` to avoid file permission issues on volume-mounted directories:

```yaml
# docker-compose.yml
environment:
  - PUID=1000   # output of: id -u
  - PGID=1000   # output of: id -g
```

### Resolution

Resize the browser window — webtop adjusts dynamically. You can also set a fixed resolution via the KasmVNC settings panel inside the desktop.

## Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./config` | `/config` | `abc` user's home directory — persists settings, extensions, dotfiles |
| `./workspace` | `/workspace` | Shared project files |

> [!WARNING]
> When running in WSL 2, the `./workspace` and `./config` folders reside entirely inside the WSL Ubuntu virtual machine. If you unregister or remove your WSL distribution, this volume data will be permanently deleted. Always commit and push your project code to a remote Git repository before removing or resetting the WSL VM.


## Docker-in-Docker

The container runs with `privileged: true`, which allows a nested Docker daemon. Inside the desktop:

```bash
# Start the Docker daemon (if not already running)
sudo dockerd &

# Use Docker and Compose normally
docker ps
docker compose up -d
```

## Updating Antigravity IDE

To pull the latest Antigravity release into a running container:

```bash
docker exec -it antigravity-desktop bash
sudo update_antigravity_ide.sh
```

Or rebuild the image:

```bash
docker compose build --no-cache
docker compose up -d
```

## Project structure

```
.
├── Dockerfile                          # Image definition
├── docker-compose.yml                  # Runtime configuration
├── update_antigravity_ide.sh           # Fetches latest Antigravity IDE tarball
├── custom-cont-init.d/
│   └── 10-install-extensions.sh       # Installs IDE extensions on first container start
├── config/                             # Persisted abc home (gitignored)
└── workspace/                          # Shared workspace files
```

## Credits & Acknowledgments

* The `update_antigravity_ide.sh` script is adapted from the guide on [LinuxCapable: How to Install Google Antigravity on Ubuntu Linux](https://linuxcapable.com/how-to-install-google-antigravity-on-ubuntu-linux/).
