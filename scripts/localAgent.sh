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

AGENT="${AGENT:-claude}"
PORT="${PORT:-11434}"

MODEL_DIR="${MODEL_DIR:?MODEL_DIR is not set in .env}"
LLAMA_SERVER="${LLAMA_SERVER:?LLAMA_SERVER is not set in .env}"
MODEL_ALIAS="${MODEL_ALIAS:?MODEL_ALIAS is not set in .env}"

########################################
# Ensure llama-server is running
########################################

# shellcheck disable=SC1091
source "$SCRIPT_DIR/start-llama.sh"

export COLORTERM=truecolor

########################################
# Run the selected agent with forwarded arguments
########################################

case "$AGENT" in
    claude)
        # Claude Code talks to llama.cpp's Anthropic-compatible endpoint.
        export ANTHROPIC_BASE_URL="http://localhost:$PORT"
        export ANTHROPIC_AUTH_TOKEN="none"
        export CLAUDE_CODE_ATTRIBUTION_HEADER=0
        exec claude "$@"
        ;;
    opencode)
        # OpenCode talks to llama.cpp's OpenAI-compatible endpoint (/v1).
        # Both run on the host, so localhost is the correct base URL.
        OCODE_DIR="$HOME/.agent-sandbox/local"
        mkdir -p "$OCODE_DIR"
        cat > "$OCODE_DIR/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "llama.cpp/${MODEL_ALIAS}",
  "permission": "allow",
  "provider": {
    "llama.cpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama-server (local)",
      "options": {
        "baseURL": "http://localhost:${PORT}/v1",
        "apiKey": "none"
      },
      "models": {
        "${MODEL_ALIAS}": { "name": "${MODEL_ALIAS} (local)" }
      }
    }
  }
}
EOF
        export OPENCODE_CONFIG="$OCODE_DIR/opencode.json"
        exec opencode --auto "$@"
        ;;
    *)
        echo "Unknown AGENT: '${AGENT}' (expected 'claude' or 'opencode')" >&2
        exit 1
        ;;
esac
