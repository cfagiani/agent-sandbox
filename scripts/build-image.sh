#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# build-image.sh
#
# Builds the agent dev image(s) on top of the common base in docker/.
# Always builds the base first (<IMAGE_NAME>-base, from
# docker/base.Dockerfile) — a cached no-op unless that file changes —
# then the agent image(s):
#   <IMAGE_NAME>-claude and <IMAGE_NAME>-opencode
#
# Usage:
#   ./build-image.sh                 # build the agents named in
#                                    # BUILD_AGENTS (scripts/.env; default:
#                                    # both, e.g. BUILD_AGENTS="claude
#                                    # opencode"; set a single agent to
#                                    # build only that)
#   ./build-image.sh --agent claude  # build only one agent (overrides
#                                    # BUILD_AGENTS from .env)
#   ./build-image.sh --no-cache      # bypass the cache for the agent
#                                    # image only (e.g. to pick up a new
#                                    # agent version); the base always
#                                    # uses its cache
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
BASE_IMAGE="${IMAGE_NAME}-base"
DOCKER_DIR="$PROJECT_DIR/docker"

# Parse flags
BUILD_ARGS=()
# BUILD_AGENTS may be set in .env (space-separated, e.g. BUILD_AGENTS=opencode
# to build only one agent image); defaults to both. --agent overrides it.
if [ -n "${BUILD_AGENTS:-}" ]; then
    read -r -a AGENTS <<< "$BUILD_AGENTS"
    for AGENT in "${AGENTS[@]}"; do
        case "$AGENT" in
            claude|opencode) ;;
            *) echo "Invalid BUILD_AGENTS: '${BUILD_AGENTS}' (expected 'claude' and/or 'opencode')" >&2; exit 1 ;;
        esac
    done
else
    AGENTS=(claude opencode)
fi
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

# ── base image (always cached; --no-cache intentionally not passed) ──
echo "→ Building base ${BASE_IMAGE} (cached unless docker/base.Dockerfile changed)..."
docker build -t "$BASE_IMAGE" -f "$DOCKER_DIR/base.Dockerfile" "$DOCKER_DIR"

for AGENT in "${AGENTS[@]}"; do
    echo "→ Building ${IMAGE_NAME}-${AGENT}..."
    docker build \
        ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"} \
        --build-arg AGENT="$AGENT" \
        --build-arg BASE_IMAGE="$BASE_IMAGE" \
        -t "${IMAGE_NAME}-${AGENT}" \
        "$DOCKER_DIR"
done

echo "→ Done. Built: ${AGENTS[*]/#/${IMAGE_NAME}-}"
