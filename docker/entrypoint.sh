#!/usr/bin/env bash
set -euo pipefail

# Resolve the host machine's address from inside the container.
# Docker Desktop (Mac / Windows) exposes host.docker.internal automatically.
# On Linux we derive it from the default route if the name isn't pre-set.
if ! getent hosts host.docker.internal &>/dev/null; then
    HOST_IP=$(ip route show default | awk '/default/ {print $3; exit}')
else
    HOST_IP="host.docker.internal"
fi

# PORT must be provided by the caller, e.g.  -e PORT=8080
: "${PORT:?Environment variable PORT must be set to your proxy port}"

export ANTHROPIC_BASE_URL="http://${HOST_IP}:${PORT}"
export ANTHROPIC_AUTH_TOKEN="none"
export CLAUDE_CODE_ATTRIBUTION_HEADER=0
export COLORTERM=truecolor

exec claude --dangerously-skip-permissions "$@"
