# syntax=docker/dockerfile:1
# ────────────────────────────────────────────────────────────────
# Claude Code dev container
#   • Java 26 (Eclipse Temurin)
#   • Maven (latest)
#   • Python 3 + uv
#   • Node.js LTS
#   • Claude Code (npm)
# ────────────────────────────────────────────────────────────────
FROM eclipse-temurin:26-jdk-noble

# ---------- system deps ----------
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

# ---------- Claude Code ----------
RUN npm install -g @anthropic-ai/claude-code

# ---------- non-root user ----------
RUN useradd -m -s /bin/bash claude
RUN mkdir -p /workspace /home/claude/.claude && chmod 777 /workspace

USER claude
WORKDIR /workspace

# ---------- runtime env ----------
# PORT must be set by the caller (host proxy port).
# ANTHROPIC_BASE_URL is built dynamically in the entrypoint so that
# host.docker.internal resolves correctly at runtime.
ENV ANTHROPIC_AUTH_TOKEN="none"
ENV CLAUDE_CODE_ATTRIBUTION_HEADER=0
ENV COLORTERM=truecolor

# ---------- entrypoint ----------
COPY --chown=claude:claude entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
