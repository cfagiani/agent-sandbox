# syntax=docker/dockerfile:1
# ────────────────────────────────────────────────────────────────
# Agent dev container (pluggable: claude | opencode)
#   Base (built separately from base.Dockerfile):
#     Java 21 (Eclipse Temurin), Maven, Python 3 + uv, Node.js LTS
#   Agent (selected via --build-arg AGENT=claude|opencode):
#     • claude   -> @anthropic-ai/claude-code
#     • opencode -> @opencode/cli
#
# The base image is supplied via --build-arg BASE_IMAGE (default
# agent-dev-base). scripts/build-image.sh builds it first, so a
# rebuild here only re-runs the agent install + user layers.
# ────────────────────────────────────────────────────────────────
ARG BASE_IMAGE=agent-dev-base
FROM ${BASE_IMAGE}

ARG AGENT=claude

# ---------- agent (selected by build arg) ----------
RUN case "${AGENT}" in \
        claude)   npm install -g @anthropic-ai/claude-code ;; \
        opencode) npm install -g @opencode/cli ;; \
        *) echo "Unknown AGENT: ${AGENT} (expected claude or opencode)" >&2 && exit 1 ;; \
    esac

# ---------- non-root user ----------
RUN useradd -m -s /bin/bash develop
RUN mkdir -p /workspace /home/develop/.claude /home/develop/.config/opencode /home/develop/.local/share/opencode \
    && chown -R develop:develop /home/develop/.local \
    && chmod 777 /workspace

USER develop
WORKDIR /workspace

# ---------- runtime env ----------
# PORT must be set by the caller (host proxy port).
# ANTHROPIC_BASE_URL / the OpenCode config are resolved dynamically in the
# entrypoint so that host.docker.internal resolves correctly at runtime.
ENV AGENT="${AGENT}"
ENV COLORTERM=truecolor
ENV DISABLE_CRASH_REPORTER=1

# ---------- entrypoint ----------
COPY --chown=develop:develop entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
