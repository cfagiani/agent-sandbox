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

MODEL_DIR="${MODEL_DIR:?MODEL_DIR is not set in .env}"
LLAMA_SERVER="${LLAMA_SERVER:?LLAMA_SERVER is not set in .env}"
MODEL_ALIAS="${MODEL_ALIAS:-local}"

########################################
# Ensure llama-server is running
########################################

# shellcheck disable=SC1091
source "$SCRIPT_DIR/start-llama.sh"

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
