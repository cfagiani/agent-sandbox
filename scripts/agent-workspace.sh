#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# agent-workspace.sh
#
# Builds (if needed) and runs the agent dev container, mounting the
# current directory as /workspace inside the container. The agent
# (claude | opencode) is selected by AGENT in scripts/.env.
#
# Usage:
#   ./agent-workspace.sh
# ────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ── 1. load .env ─────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

# ── 1b. config ───────────────────────────────────────────────────
AGENT="${AGENT:-claude}"
case "$AGENT" in
    claude|opencode) ;;
    *) echo "Invalid AGENT: '$AGENT' (expected 'claude' or 'opencode')" >&2; exit 1 ;;
esac

IMAGE_NAME="${IMAGE_NAME:-agent-dev}"
IMAGE="${IMAGE_NAME}-${AGENT}"
PORT="${PORT:-11434}"

# ── 2. ensure colima is running ──────────────────────────────────
if ! colima status &>/dev/null; then
    echo "→ Starting colima..."
    colima start --memory 6
else
    echo "→ colima already running"
fi

# ── 3. ensure llama-server is running on that port ───────────────
MODEL_DIR="${MODEL_DIR:?MODEL_DIR is not set in .env}"
LLAMA_SERVER="${LLAMA_SERVER:?LLAMA_SERVER is not set in .env}"
MODEL_ALIAS="${MODEL_ALIAS:?MODEL_ALIAS is not set in .env}"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/start-llama.sh"

# ── 4. build image if missing ────────────────────────────────────
if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "→ Building Docker image '${IMAGE}'..."
    docker build --build-arg AGENT="$AGENT" -t "$IMAGE" "$PROJECT_DIR/docker"
else
    echo "→ Image '${IMAGE}' already exists. Skipping build."
    echo "  (Run 'docker rmi ${IMAGE}' first to force a rebuild.)"
fi

# ── 5. ensure ~/.agent-sandbox/workspaces exists ──────────────────
AGENT_SANDBOX="$HOME/.agent-sandbox"
AGENT_WORKSPACES="$AGENT_SANDBOX/workspaces"
if [ ! -d "$AGENT_WORKSPACES" ]; then
    echo "→ Creating $AGENT_WORKSPACES"
    mkdir -p "$AGENT_WORKSPACES"
fi

# ── 5b. compute workspace-specific sandbox dir from pwd hash ──────
WORKSPACE_HASH=$(echo "$(pwd)" | sha256sum | awk '{print $1}' | cut -c1-16)
WORKSPACE_SANDBOX="$AGENT_WORKSPACES/$WORKSPACE_HASH"
if [ ! -d "$WORKSPACE_SANDBOX" ]; then
    echo "→ Creating workspace sandbox: $WORKSPACE_SANDBOX"
    mkdir -p "$WORKSPACE_SANDBOX"
fi

# ── 5c. agent-specific in-container config path + host-side seed ──
case "$AGENT" in
    claude)
        CONFIG_MOUNT="/home/develop/.claude"
        INITIAL_SETTINGS="${PROJECT_DIR}/claude/initial_settings.json"
        if [ -f "$INITIAL_SETTINGS" ] && [ ! -f "$WORKSPACE_SANDBOX/settings.json" ]; then
            echo "→ Copying initial settings to sandbox"
            cp "$INITIAL_SETTINGS" "$WORKSPACE_SANDBOX/settings.json"
        fi
        ;;
    opencode)
        # opencode.json is generated at runtime by the entrypoint (it needs
        # the host IP resolved inside the container).
        CONFIG_MOUNT="/home/develop/.config/opencode"
        ;;
esac

echo "→ Workspace hash: $WORKSPACE_HASH ($(pwd))"

# ── 6. run container ─────────────────────────────────────────────
echo "→ Launching ${AGENT} in $(pwd)"
echo "  The agent will talk to the local LLM proxy on port ${PORT}"
echo ""

docker run --rm -it \
    --network=host \
    -e AGENT="${AGENT}" \
    -e PORT="${PORT}" \
    -e MODEL_ALIAS="${MODEL_ALIAS}" \
    -v "$(pwd):/workspace" \
    -v "$WORKSPACE_SANDBOX:${CONFIG_MOUNT}:rw" \
    -w /workspace \
    "$IMAGE"
