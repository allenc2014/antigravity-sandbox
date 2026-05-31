# antigravity-sandbox

A browser-accessible Linux desktop sandbox powered by [linuxserver/webtop](https://docs.linuxserver.io/images/docker-webtop/), pre-loaded with Antigravity IDE and a curated developer toolset.

## What's included

| Tool | Details |
|---|---|
| **Antigravity IDE** | Latest version, installed via `update_antigravity_ide.sh` at build time |
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

## Configuration

### User mapping (PUID / PGID)

The desktop session runs as user `abc`. Map it to your host user to avoid file permission issues on volume-mounted directories:

```yaml
# docker-compose.yml
environment:
  - PUID=1000   # output of: id -u
  - PGID=1000   # output of: id -g
```

### Changing the password

```yaml
environment:
  - PASSWORD=your-secure-password
```

### Timezone

```yaml
environment:
  - TZ=America/New_York
```

### Resolution

Resize the browser window — webtop adjusts dynamically. You can also set a fixed resolution via the KasmVNC settings panel inside the desktop.

## Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./config` | `/config` | `abc` user's home directory — persists settings, extensions, dotfiles |
| `./workspace` | `/workspace` | Shared project files |

## Docker-in-Docker

The container runs with `privileged: true`, which allows a nested Docker daemon. Inside the desktop:

```bash
# Start the Docker daemon (if not already running)
sudo dockerd &

# Use Docker and Compose normally
docker ps
docker compose up
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
