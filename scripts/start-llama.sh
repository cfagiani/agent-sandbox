#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# start-llama.sh
#
# Shared logic: ensure llama-server is running on the configured port.
# Both localClaude.sh and claude-workspace.sh source this script
# after loading .env so that PORT, PATH_TO_MODEL, LLAMA_SERVER,
# MODEL_ALIAS, CONTEXT_SIZE, and LLM_OPTIONS are already set.
# ────────────────────────────────────────────────────────────────

if lsof -iTCP:"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "→ llama-server already running on port $PORT"
else
    echo "→ Starting llama-server on port $PORT..."
    nohup "$LLAMA_SERVER" \
        -m "$PATH_TO_MODEL" \
        --alias "$MODEL_ALIAS" \
        --port "$PORT" \
        -c "$CONTEXT_SIZE" \
        "${LLM_OPTIONS[@]}" \
        > /tmp/llama-server.log 2>&1 &
    sleep 2
    echo "→ llama-server started"
fi
