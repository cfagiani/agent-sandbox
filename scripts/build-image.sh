#!/usr/bin/env bash
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

IMAGE_NAME="${IMAGE_NAME:-claude-code-dev}"

# Parse flags
BUILD_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-cache) BUILD_ARGS+=(--no-cache); shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

docker build "${BUILD_ARGS[@]}" -t "$IMAGE_NAME" "$PROJECT_DIR/docker"
