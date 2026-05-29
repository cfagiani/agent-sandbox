#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# start-llama.sh
#
# Ensures llama-server is running on the configured port.
# Can be sourced by localClaude.sh / claude-workspace.sh (which
# load .env before sourcing) or run directly (loads .env itself).
# ────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── load .env ────────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
fi

# ── model-specific file name and LLM options ──────────────────────
# Falls back to generic values when MODEL_ALIAS is unrecognized.
case "$MODEL_ALIAS" in
  qwen3.6-27B)
    MODEL_FILE="Qwen3.6-27B-UD-Q4_K_XL.gguf"
    LLM_OPTIONS=(
                  -fa on
                  -np 1
                  --temp 0.7
                  --top-p 0.95
                  --top-k 20
                  --presence-penalty 1.0
                  --min-p 0.01
                  --spec-type draft-mtp
                  --spec-draft-n-max 2
                )
    ;;
  qwen3.6-35B-A3B)
      MODEL_FILE="Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf"
      LLM_OPTIONS=(
                    -fa on
                    -np 1
                    -ngl 99
                    --temp 0.7
                    --top-p 0.95
                    --top-k 20
                    --presence-penalty 1.0
                  )
      ;;

  *)
    MODEL_FILE="${MODEL_ALIAS}.gguf"
    LLM_OPTIONS=(
                  -fa on
                  -np 1
                  --temp 0.7
                  --top-p 0.95
                  --top-k 20
                  --presence-penalty 1.0
                )
    ;;
esac

PATH_TO_MODEL="${MODEL_DIR}/${MODEL_FILE}"

start_server() {
    echo "→ Starting llama-server on port $PORT with $MODEL_FILE..."
    nohup "$LLAMA_SERVER" \
        -m "$PATH_TO_MODEL" \
        --alias "$MODEL_ALIAS" \
        --port "$PORT" \
        -c "$CONTEXT_SIZE" \
        "${LLM_OPTIONS[@]}" \
        > /tmp/llama-server.log 2>&1 &
    sleep 2
    echo "→ llama-server started"
}

if lsof -iTCP:"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    # Something is on the port — check whether it's serving the model we want.
    CURRENT_ALIAS="$(curl -sf "http://localhost:$PORT/v1/models" 2>/dev/null \
        | jq -r '.data[0].id // .data[0] // empty' 2>/dev/null || true)"

    if [ "$CURRENT_ALIAS" = "$MODEL_ALIAS" ]; then
        echo "→ llama-server already running on port $PORT with $MODEL_FILE"
    else
        echo "→ Wrong model on port $PORT (expected $MODEL_ALIAS, found ${CURRENT_ALIAS:-unknown}) — killing"
        lsof -iTCP:"$PORT" -sTCP:LISTEN -t | xargs kill >/dev/null 2>&1 || true
        sleep 1
        start_server
    fi
else
    start_server
fi
