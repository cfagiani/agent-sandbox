#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# build-image.sh
#
# Builds the agent dev image(s) from the common base in docker/.
# By default builds both agents:
#   <IMAGE_NAME>-claude and <IMAGE_NAME>-opencode
#
# Usage:
#   ./build-image.sh                 # build both agents
#   ./build-image.sh --agent claude  # build only one agent
#   ./build-image.sh --no-cache      # bypass the Docker build cache
# ────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ── load .env ────────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

IMAGE_NAME="${IMAGE_NAME:-agent-dev}"
DOCKER_DIR="$PROJECT_DIR/docker"

# Parse flags
BUILD_ARGS=()
AGENTS=(claude opencode)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-cache) BUILD_ARGS+=(--no-cache); shift ;;
        --agent)
            case "${2:-}" in
                claude|opencode) AGENTS=("$2") ;;
                *) echo "Invalid --agent: '${2:-}' (expected 'claude' or 'opencode')" >&2; exit 1 ;;
            esac
            shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

for AGENT in "${AGENTS[@]}"; do
    echo "→ Building ${IMAGE_NAME}-${AGENT}..."
    docker build \
        ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"} \
        --build-arg AGENT="$AGENT" \
        -t "${IMAGE_NAME}-${AGENT}" \
        "$DOCKER_DIR"
done

echo "→ Done. Built: ${AGENTS[*]/#/${IMAGE_NAME}-}"
