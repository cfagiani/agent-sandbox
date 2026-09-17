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

export COLORTERM=truecolor

case "${AGENT:-claude}" in
    claude)
        # Claude Code talks to llama.cpp's Anthropic-compatible endpoint.
        export ANTHROPIC_BASE_URL="http://${HOST_IP}:${PORT}"
        export ANTHROPIC_AUTH_TOKEN="none"
        export CLAUDE_CODE_ATTRIBUTION_HEADER=0
        exec claude --dangerously-skip-permissions "$@"
        ;;
    opencode)
        # OpenCode talks to llama.cpp's OpenAI-compatible endpoint (/v1).
        # The config is generated here (not checked in) because the base URL
        # depends on the host IP resolved above and on MODEL_ALIAS.
        : "${MODEL_ALIAS:?MODEL_ALIAS must be set for the opencode agent}"
        CONFIG_DIR="/home/develop/.config/opencode"
        mkdir -p "$CONFIG_DIR"
        cat > "${CONFIG_DIR}/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "llama.cpp/${MODEL_ALIAS}",
  "permission": "allow",
  "provider": {
    "llama.cpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama-server (local)",
      "options": {
        "baseURL": "http://${HOST_IP}:${PORT}/v1",
        "apiKey": "none"
      },
      "models": {
        "${MODEL_ALIAS}": { "name": "${MODEL_ALIAS} (local)" }
      }
    }
  }
}
EOF
        export OPENCODE_CONFIG="${CONFIG_DIR}/opencode.json"
        exec opencode --auto "$@"
        ;;
    *)
        echo "Unknown AGENT: '${AGENT}' (expected 'claude' or 'opencode')" >&2
        exit 1
        ;;
esac
