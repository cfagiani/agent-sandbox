# Agent Dev Container

Run a coding agent — **[Claude Code](https://claude.ai/code)** or **[OpenCode](https://opencode.ai)** — in an isolated Docker container (or directly on the host) that talks to a local LLM instead of a cloud API.

The agent is **pluggable**: a single common base image is built for each supported agent, and a `AGENT` setting in `scripts/.env` selects which one the runtime scripts launch.

## What's inside

| Directory / File | Purpose |
|---|---|
| `docker/Dockerfile` | Common base image (Java 21, Maven, Python 3 + uv, Node.js LTS) plus the agent, selected at build time via `--build-arg AGENT=claude\|opencode`. |
| `docker/entrypoint.sh` | Container entrypoint: resolves the host IP, then launches the selected agent (`claude` or `opencode`) pointed at the local LLM proxy. For OpenCode it generates `opencode.json` at runtime. |
| `scripts/agent-workspace.sh` | Main entry point: reads `scripts/.env`, starts colima (if needed), starts llama-server (if needed), builds the Docker image (if missing), and runs the container with the current directory mounted as `/workspace` and a workspace-specific config directory mounted into the container. |
| `scripts/localAgent.sh` | Lightweight alternative that skips Docker entirely — just starts llama-server and runs the selected agent directly on the host. |
| `scripts/build-image.sh` | Builds the Docker image(s) from the common base. Builds **both** agents by default; use `--agent <name>` to build just one. |
| `scripts/start-llama.sh` | Starts (or reuses) a local llama.cpp server with model-specific options. |
| `scripts/.env.example` | Template for local configuration — copy to `.env` and set `AGENT`, `MODEL_DIR`, `LLAMA_SERVER`, `PORT`, `IMAGE_NAME`, and `MODEL_ALIAS`. |
| `claude/initial_settings.json` | Default Claude Code settings seeded into a new workspace's config directory. |

## Supported agents

| `AGENT` | Package | Talks to llama.cpp via |
|---|---|---|
| `claude` | `@anthropic-ai/claude-code` | Anthropic-compatible endpoint (`/v1/messages`, `ANTHROPIC_BASE_URL`) |
| `opencode` | `opencode-ai` | OpenAI-compatible endpoint (`/v1`, a custom provider in `opencode.json`) |

## How it works

The selected agent runs against a local [llama.cpp](https://github.com/ggerganov/llama.cpp) server (default: `localhost:11434`). The entrypoint dynamically resolves the correct host address so the container can reach the proxy, whether you're on Docker Desktop (Mac/Windows) or Linux.

- **Claude Code** is pointed at the proxy with `ANTHROPIC_BASE_URL`.
- **OpenCode** is given an `opencode.json` with a custom OpenAI-compatible provider whose `baseURL` points at the proxy's `/v1` endpoint. This config is generated at runtime (in the entrypoint, or by `localAgent.sh`) because it depends on the resolved host address and the `MODEL_ALIAS`. It uses `--auto` / `"permission": "allow"` so no interactive permission prompts appear.

## Prerequisites

- Docker (or Colima on macOS)
- A compatible GGUF model
- A local llama-server binary

## Configuration

Copy `scripts/.env.example` to `scripts/.env` and set the paths:

```bash
cp scripts/.env.example scripts/.env
# Edit scripts/.env with your agent, model, and llama-server paths
```

- `AGENT` — which agent to run: `claude` or `opencode` (default: `claude`)
- `MODEL_DIR` — directory containing your GGUF model files (filename is derived from `MODEL_ALIAS`)
- `LLAMA_SERVER` — absolute path to your llama-server binary
- `PORT` — port for the llama.cpp server (default: `11434`)
- `IMAGE_NAME` — base name for the Docker images (default: `agent-dev`; built as `<IMAGE_NAME>-claude` and `<IMAGE_NAME>-opencode`)
- `MODEL_ALIAS` — model alias; selects LLM options in `start-llama.sh` and, for OpenCode, the model id

## Usage

```bash
# Build the images (both agents by default)
./scripts/build-image.sh

# Build just one agent
./scripts/build-image.sh --agent opencode

# Run the selected agent in a container (mounts current dir as /workspace)
./scripts/agent-workspace.sh

# Or run the selected agent directly on the host (no Docker)
./scripts/localAgent.sh
```

To switch agents, change `AGENT` in `scripts/.env` (and build the corresponding image if it isn't present).

By default, the scripts expect colima and llama-server to be running. If they are not, `agent-workspace.sh` will start them automatically.

## Workspace-specific config directory

Each working directory gets its own isolated agent config directory inside the container. The directory is computed by hashing the full path of the directory from which `agent-workspace.sh` is launched, so revisiting the same project always maps to the same sandbox.

Sandbox directories are stored at `~/.agent-sandbox/workspaces/<hash>`. Inside the container the sandbox is mounted at the agent's config location:

- `claude` → `/home/develop/.claude` (seeded from `claude/initial_settings.json` on first run)
- `opencode` → `/home/develop/.config/opencode` (the entrypoint generates `opencode.json` here at runtime)

This keeps agent settings, history, and sessions isolated per project — no cross-contamination between workspaces.

## Future Enhancements
Some potential future enhancements:
* Profile support - make the docker file a template and install a different set of tools based on the type of dev work it should support
* MCP/Skill integration - pre-seed the docker file with specific skills and MCPs
* Template for base set of agent configuration that is seeded into the workspace config home on first start
* Support for skipping local llm configuration and using cloud models
