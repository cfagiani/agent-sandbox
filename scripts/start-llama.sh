#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# start-llama.sh
#
# Shared logic: ensure llama-server is running on the configured port.
# Both localClaude.sh and claude-workspace.sh source this script
# after loading .env so that PORT, MODEL_DIR, LLAMA_SERVER,
# MODEL_ALIAS, and CONTEXT_SIZE are already set.
# MODEL_FILE and LLM_OPTIONS are selected inside this script based on MODEL_ALIAS.
# ────────────────────────────────────────────────────────────────

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
