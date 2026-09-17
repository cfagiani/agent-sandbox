# AGENTS.md

This repo is a set of bash scripts plus one Dockerfile that run a coding agent (Claude Code or OpenCode) against a local llama.cpp server. There is no application code, no test suite, and no lint/typecheck.

## Commands

- `./scripts/agent-workspace.sh` — main entrypoint. Starts colima and llama-server if needed, builds the image if missing, runs the agent in a container with the current directory mounted at `/workspace`.
- `./scripts/localAgent.sh` — same, but runs the agent directly on the host (no Docker).
- `./scripts/build-image.sh` — builds `<IMAGE_NAME>-claude` and `<IMAGE_NAME>-opencode` (both by default; `--agent <name>` for one; `--no-cache` to pick up new agent versions).
- `./scripts/start-llama.sh [MODEL_ALIAS]` — starts or reuses the llama server; kills and restarts it if a different model alias is serving on the port.

Verify script changes with `bash -n <script>` (and shellcheck if available).

## Configuration

- `scripts/.env` (gitignored, machine-specific) — copy from `scripts/.env.example`. `MODEL_DIR`, `LLAMA_SERVER`, and `MODEL_ALIAS` are required; scripts hard-fail (`:?`) without them. `AGENT` defaults to `claude`.
- `MODEL_ALIAS` is dual-purpose: it selects the model file + sampling options in the `case` block of `start-llama.sh`, and it becomes the llama-server `--alias` and the model id in the generated OpenCode config. Adding a new model means adding a case there.
- The `qwen3.8-27B` alias additionally depends on `scripts/qwenChatTemplate.jinja` (`--chat-template-file` + `--jinja`).

## Gotchas

- One common Dockerfile, two images: the agent is selected at build time via `--build-arg AGENT=claude|opencode`. `agent-workspace.sh` skips the build if the image already exists — `docker rmi <image>` or `build-image.sh --no-cache` to force a rebuild.
- OpenCode's `opencode.json` is generated at runtime by `docker/entrypoint.sh` (or `localAgent.sh`) because it depends on the resolved host IP and `MODEL_ALIAS`. Never check it in.
- Per-workspace sandbox: `~/.agent-sandbox/workspaces/<sha256(pwd)[:16]>` is mounted as the agent's config dir. For claude, `settings.json` is seeded from `claude/initial_settings.json` on first run.
- `agent-workspace.sh` assumes macOS colima (`colima start --memory 6`); on a Linux host without colima it will fail at that step.
- `docker/entrypoint.sh` resolves the host address: `host.docker.internal` if it resolves, otherwise the default-route IP.
- `start-llama.sh` works both sourced (caller sets `MODEL_ALIAS` first) and run directly (positional arg overrides `.env`). Preserve that dual mode when editing.
- Every script loads `scripts/.env` itself and uses `set -euo pipefail`; keep new scripts self-contained in the same style.

## Conventions

- Commit messages are short and lowercase (see `git log`).
- Never commit `scripts/.env` (contains local paths); keep `scripts/.env.example` in sync when adding variables.
- `.idea/` is untracked IDE config — do not commit it.
