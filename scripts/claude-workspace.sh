#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# claude-workspace.sh
#
# Builds (if needed) and runs the Claude Code dev container,
# mounting the current directory as /workspace inside the container.
#
# Usage:
#   ./claude-workspace.sh
# ────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. load .env ─────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

# ── 1b. config ───────────────────────────────────────────────────
IMAGE_NAME="${IMAGE_NAME:-claude-code-dev}"
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

# Override MODEL_ALIAS to use qwen3.6-27B regardless of .env value
MODEL_ALIAS="qwen3.6-27B"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/start-llama.sh"

# ── 4. build image if missing or if Dockerfile changed ──────────
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "→ Building Docker image '${IMAGE_NAME}'..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
else
    echo "→ Image '${IMAGE_NAME}' already exists. Skipping build."
    echo "  (Run 'docker rmi ${IMAGE_NAME}' first to force a rebuild.)"
fi

# ── 5. ensure ~/.claude-sandbox/workspaces exists ──────────────────
CLAUDE_SANDBOX="$HOME/.claude-sandbox"
CLAUDE_WORKSPACES="$CLAUDE_SANDBOX/workspaces"
if [ ! -d "$CLAUDE_WORKSPACES" ]; then
    echo "→ Creating $CLAUDE_WORKSPACES"
    mkdir -p "$CLAUDE_WORKSPACES"
fi

# ── 5b. compute workspace-specific sandbox dir from pwd hash ──────
WORKSPACE_HASH=$(echo "$(pwd)" | sha256sum | awk '{print $1}' | cut -c1-16)
WORKSPACE_SANDBOX="$CLAUDE_WORKSPACES/$WORKSPACE_HASH"
if [ ! -d "$WORKSPACE_SANDBOX" ]; then
    echo "→ Creating workspace sandbox: $WORKSPACE_SANDBOX"
    mkdir -p "$WORKSPACE_SANDBOX"
fi

echo "→ Workspace hash: $WORKSPACE_HASH ($(pwd))"

# ── 6. run container ─────────────────────────────────────────────
echo "→ Launching Claude Code in $(pwd)"
echo "  ANTHROPIC_BASE_URL will point to http://localhost:${PORT}"
echo ""

docker run --rm -it \
    --network=host \
    -e PORT="${PORT}" \
    -e ANTHROPIC_BASE_URL="http://localhost:${PORT}" \
    -e ANTHROPIC_AUTH_TOKEN="none" \
    -e CLAUDE_CODE_ATTRIBUTION_HEADER=0 \
    -e COLORTERM=truecolor \
    -v "$(pwd):/workspace" \
    -v "$WORKSPACE_SANDBOX:/home/claude/.claude:rw" \
    -w /workspace \
    "$IMAGE_NAME"
