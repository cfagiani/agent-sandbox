#!/usr/bin/env bash

set -euo pipefail

########################################
# Configuration
########################################

# ── load .env ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

PORT="${PORT:-11434}"

PATH_TO_MODEL="${PATH_TO_MODEL:?PATH_TO_MODEL is not set in .env}"
LLAMA_SERVER="${LLAMA_SERVER:?LLAMA_SERVER is not set in .env}"

########################################
# Check if llama-server is already running
########################################

if lsof -iTCP:"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "llama-server already running on port $PORT"
else
    echo "Starting llama-server on port $PORT..."

    nohup "$LLAMA_SERVER" \
        -m "$PATH_TO_MODEL" \
        --port "$PORT" \
        -c "$CONTEXT_SIZE" \
        "${LLM_OPTIONS[@]}" \
        > /tmp/llama-server.log 2>&1 &

    # Optional: wait briefly for startup
    sleep 2

    echo "llama-server started"
fi

########################################
# Claude environment variables
########################################

export ANTHROPIC_BASE_URL="http://localhost:$PORT"
export ANTHROPIC_AUTH_TOKEN="none"
export CLAUDE_CODE_ATTRIBUTION_HEADER=0
export COLORTERM=truecolor

########################################
# Run claude with forwarded arguments
########################################

claude "$@"
