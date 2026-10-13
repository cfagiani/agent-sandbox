# syntax=docker/dockerfile:1
# ────────────────────────────────────────────────────────────────
# Common base for the agent dev images (built by scripts/build-image.sh).
#   Java 21 (Eclipse Temurin), Maven, Python 3 + uv, Node.js LTS
#
# Kept separate from the agent Dockerfile so that rebuilding an agent
# image never re-runs these (slow) layers. build-image.sh rebuilds it
# on every run, but it is a cached no-op unless this file changes.
# ────────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-noble

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
