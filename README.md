# Claude Code Dev Container

Run [Claude Code](https://claude.ai/code) in an isolated Docker container that talks to a local LLM proxy instead of the Anthropic API.

## What's inside

| Directory / File | Purpose |
|---|---|
| `docker/Dockerfile` | Builds the `claude-code-dev` image: Java 26, Maven, Python 3 + uv, Node.js LTS, and Claude Code (npm). |
| `docker/entrypoint.sh` | Container entrypoint that resolves the host IP and launches `claude`. |
| `scripts/claude-workspace.sh` | Main entry point: reads `scripts/.env`, starts colima (if needed), starts llama-server (if needed), builds the Docker image (if missing), and runs the container with the current directory mounted as `/workspace` and a workspace-specific config directory mounted at `/home/claude/.claude`. |
| `scripts/.env.example` | Template for local configuration — copy to `.env` and set `PATH_TO_MODEL`, `LLAMA_SERVER`, `PORT`, and `IMAGE_NAME`. |
| `scripts/localClaude.sh` | Lightweight alternative that skips Docker entirely — just starts llama-server and runs `claude` directly on the host. |
| `scripts/build-image.sh` | Standalone script to build the `claude-code-dev` Docker image. |

## How it works

The container runs Claude Code with `ANTHROPIC_BASE_URL` pointing to a local [llama.cpp](https://github.com/ggerganov/llama.cpp) server (default: `localhost:11434`). The entrypoint dynamically resolves the correct host IP so the container can reach the proxy, whether you're on Docker Desktop (Mac/Windows) or Linux.

## Prerequisites

- Docker (or Colima on macOS)
- A compatible GGUF model
- A local llama-server binary

## Configuration

Copy `scripts/.env.example` to `scripts/.env` and set the paths:

```bash
cp scripts/.env.example scripts/.env
# Edit scripts/.env with your model and llama-server paths
```

- `PATH_TO_MODEL` — absolute path to your GGUF model file
- `LLAMA_SERVER` — absolute path to your llama-server binary
- `PORT` — port for the llama.cpp server (default: `11434`)
- `IMAGE_NAME` — name for the Docker image (default: `claude-code-dev`)

## Usage

```bash
# Build the image
./scripts/build-image.sh

# Run Claude Code in a container (mounts current dir as /workspace)
./scripts/claude-workspace.sh

# Or run directly on the host (no Docker)
./scripts/localClaude.sh
```

By default, the scripts expect colima and llama-server to be running. If they are not, `claude-workspace.sh` will start them automatically.

## Workspace-specific config directory

Each working directory gets its own isolated Claude config directory inside the container at `/home/claude/.claude`. The directory is computed by hashing the full path of the directory from which `claude-workspace.sh` is launched, so revisiting the same project always maps to the same sandbox.

Sandbox directories are stored at `~/.claude-sandbox/workspaces/<hash>`. This keeps Claude Code settings, history, and agent sessions isolated per project — no cross-contamination between workspaces.

## Future Enhancements
Some potential future enhancements:                                                                                                                                                                                                                     
* Profile support - make the docker file a template and install a different set of tools based on the type of dev work it should support                                                                                                                
* MCP/SKill integration - pre-seed the docker file with specific skills and MCPs                                                                                                                                                                        
* Template for base set of Claude configuration that is seeded into the workspace config home on first start                                                                                                                                            
* Support for skipping local llm configuration and using cloud models                   