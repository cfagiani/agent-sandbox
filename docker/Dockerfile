# syntax=docker/dockerfile:1
# ────────────────────────────────────────────────────────────────
# Agent dev container (pluggable: claude | opencode)
#   Common base: Java 21 (Eclipse Temurin), Maven, Python 3 + uv, Node.js LTS
#   Agent (selected via --build-arg AGENT=claude|opencode):
#     • claude   -> @anthropic-ai/claude-code
#     • opencode -> opencode-ai
# ────────────────────────────────────────────────────────────────
ARG AGENT=claude
FROM eclipse-temurin:21-jdk-noble

ARG AGENT

# ---------- system deps (common) ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        bash \
        unzip \
        gnupg \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ---------- uv (fast Python package manager) ----------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# ---------- Maven ----------
ARG MAVEN_VERSION=3.9.9
RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    | tar -xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

# ---------- Node.js LTS ----------
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------- agent (selected by build arg) ----------
RUN case "${AGENT}" in \
        claude)   npm install -g @anthropic-ai/claude-code ;; \
        opencode) npm install -g opencode-ai ;; \
        *) echo "Unknown AGENT: ${AGENT} (expected claude or opencode)" >&2 && exit 1 ;; \
    esac

# ---------- non-root user ----------
RUN useradd -m -s /bin/bash develop
RUN mkdir -p /workspace /home/develop/.claude /home/develop/.config/opencode && chmod 777 /workspace

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
