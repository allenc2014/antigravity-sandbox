#!/bin/bash
# /custom-cont-init.d/20-git-config.sh
#
# Configures git identity and credential storage for "abc" from env vars.
# Values are written to /config/.gitconfig (persisted via volume mount).
# Update the .env file and restart the container to apply changes.
#
# GIT_CREDENTIAL_HELPER options:
#   store  — saves credentials in plaintext at /config/.git-credentials
#            (persisted by the volume mount; convenient but not encrypted)
#   cache  — keeps credentials in memory for the session only
#            (add GIT_CREDENTIAL_CACHE_TIMEOUT=<seconds> to tune, default 900)
#   <unset/empty> — no helper; git will prompt for credentials every time

set -euo pipefail

# ── Identity ─────────────────────────────────────────────────────────────────
CONFIGURED=0

if [ -n "${GIT_USER_NAME:-}" ]; then
    sudo -u abc HOME=/config git config --global user.name "$GIT_USER_NAME"
    echo "[init] git user.name  → $GIT_USER_NAME"
    CONFIGURED=1
fi

if [ -n "${GIT_USER_EMAIL:-}" ]; then
    sudo -u abc HOME=/config git config --global user.email "$GIT_USER_EMAIL"
    echo "[init] git user.email → $GIT_USER_EMAIL"
    CONFIGURED=1
fi

if [ "$CONFIGURED" -eq 0 ]; then
    echo "[init] GIT_USER_NAME / GIT_USER_EMAIL not set — skipping git identity config."
fi

# ── Credential helper ────────────────────────────────────────────────────────
case "${GIT_CREDENTIAL_HELPER:-}" in
    store)
        sudo -u abc HOME=/config git config --global credential.helper \
            "store --file /config/.git-credentials"
        echo "[init] git credential.helper → store (/config/.git-credentials)"
        ;;
    cache)
        TIMEOUT="${GIT_CREDENTIAL_CACHE_TIMEOUT:-900}"
        sudo -u abc HOME=/config git config --global credential.helper \
            "cache --timeout=$TIMEOUT"
        echo "[init] git credential.helper → cache (timeout: ${TIMEOUT}s)"
        ;;
    "")
        # Clear any previously configured helper so git prompts every time
        sudo -u abc HOME=/config git config --global --unset credential.helper 2>/dev/null || true
        echo "[init] git credential.helper → none (will prompt for credentials)"
        ;;
    *)
        echo "[init] WARNING: unknown GIT_CREDENTIAL_HELPER '${GIT_CREDENTIAL_HELPER}' — skipping. Use 'store', 'cache', or leave unset."
        ;;
esac
