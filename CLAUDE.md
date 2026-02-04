# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rootless Podman container setup for running Claude Code CLI in sandbox mode (bubblewrap). Ubuntu 24.04 base image with a non-root `claude` user (UID matched to host). The container mounts a host directory at `/workspace` and runs indefinitely via a sleep loop.

## Build and Run

```bash
./scripts/build.sh                              # Build production image
./scripts/build.sh --test                        # Build test image
./scripts/build.sh --no-sudo --no-cache          # No sudo, no layer cache

./scripts/run.sh                                 # Run with cwd as shared folder
./scripts/run.sh --name foo ~/project            # Named instance, custom path
./scripts/run.sh --test --name bar /tmp/test     # Test container

./scripts/exec.sh                               # Auto-detect single running container
./scripts/exec.sh --name foo                     # Specific container

./scripts/list.sh                                # Show all containers + status
./scripts/stop.sh --name foo                     # Stop (preserves state)
./scripts/start.sh --name foo                    # Restart stopped container
./scripts/rm.sh --name foo --force               # Remove (--force if running)
./scripts/rmi.sh --test --force                  # Remove image
./scripts/nuke.sh --test --force                 # Remove all test resources
./scripts/nuke.sh --force                        # Remove ALL resources
```

All scripts accept `--test`, `--name <name>`, `--force` in any order.

## Architecture

```
scripts/common.sh          # Shared library: arg parsing, naming, container queries
scripts/build.sh            # podman build with host UID/GID as build args
scripts/run.sh              # podman run -d with --userns=keep-id and -v mount
scripts/exec.sh             # podman exec -it with auto-detection
scripts/{stop,start,rm,rmi,list,nuke}.sh  # Lifecycle management
Containerfile               # Production image definition
Containerfile.test          # Symlink to Containerfile (test differs only by image tag)
bashrc-additions            # Appended to claude user's .bashrc in image
```

### common.sh API

All scripts source `common.sh` and call `parse_common_args "$@"` which sets globals: `TEST_MODE`, `INSTANCE_NAME`, `FORCE_MODE`, `NO_SUDO_MODE`, `NO_CACHE_MODE`, `REMAINING_ARGS`.

Key functions:
- `get_image_name(is_test)` - returns `claude-sandbox` or `claude-sandbox-test`
- `build_container_name(is_test, suffix)` - returns `claude-sandbox-<suffix>` or `claude-sandbox-test-<suffix>`
- `container_exists(name)`, `container_running(name)`, `image_exists(name)` - status checks
- `list_sandbox_containers([test_only])`, `list_running_containers([test_only])` - listing helpers

### Naming Convention

- Images: `claude-sandbox` (prod), `claude-sandbox-test` (test)
- Containers: `claude-sandbox-<name>` (default name: `default`)
- Log files: `/tmp/claude-sandbox-{build,run}.log` (or `*-test-*` variants)

### Containerfile Details

Build args: `USER_UID`, `USER_GID` (from host `id -u`/`id -g`), `NO_SUDO` (true/false). Note: `build.sh` passes this as `--build-arg NOSUDO=` (not `NO_SUDO`), but the Containerfile declares `ARG NO_SUDO` and re-declares it before the conditional - the actual arg name received from build.sh is `NOSUDO`.

Installed packages: `bubblewrap`, `socat`, `curl`, `sudo`, `nano`, `git`, `build-essential`, `ca-certificates`.

Claude Code is installed as user `claude` via `curl -fsSL https://claude.ai/install.sh | bash` to enable auto-updates. Path: `~/.local/bin/claude`.

Container stays alive with: `trap 'exit 0' SIGTERM; while :; do sleep 1; done`

### Key Podman Flags (in run.sh)

- `--userns=keep-id:uid=${UID},gid=${GID}` - maps host user to container `claude` user
- `-v "$FOLDER:/workspace:Z"` - shared folder mount with SELinux relabeling
- `--hostname "$CONTAINER_NAME"` - sets hostname to match container name

## Development Patterns

- All scripts use `set -e` and source `common.sh` via `SCRIPT_DIR` relative path
- Arguments are order-independent (parsed by `parse_common_args`)
- Error handling uses `die()` for fatal errors, `info()` for status messages
- Scripts validate preconditions (image exists, container exists/not exists, running state) before acting
- `bashrc-additions` adds the alias `claude="claude --allow-dangerously-skip-permissions"` and custom PS1/LS_COLORS

## Gitignored Paths

`chats/` and `instructions/` are gitignored. The `instructions/` folder contains local-only guidance docs (standing instructions, GPU passthrough notes).

## Safety Notes

- `nuke.sh --test` only removes test resources - safe to run from inside a production container
- `nuke.sh` without `--test` removes ALL claude-sandbox resources - never run from inside a production container
- `Containerfile.test` is a symlink to `Containerfile`, so test and prod images are built from the same definition
