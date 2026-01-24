# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project creates scripts to set up a rootless Podman container running Claude Code CLI in sandbox mode (using bubblewrap). The goal is to simplify the previous complex network filtering approach by leveraging Claude's built-in sandboxing capabilities.

## Project Requirements (from README)

Create three main scripts:
1. **Image creation script** - Build Ubuntu-based container with Claude Code installed
2. **Container run script** - Start container with shared folder mounting (default: current directory, or specified path)
3. **Interactive exec script** - Open terminal session inside running container

Key requirements:
- **Rootless Podman** (no sudo for container operations)
- **Ubuntu base image**
- **Claude Code installed as limited user** (not root) to enable auto-updates
- **Sandbox mode enabled** (requires bubblewrap in container)
- **Passwordless sudo** option inside container
- **Shared folder mounting** with proper UID mapping

## Architecture Approach

```
Host Machine
└── Rootless Podman Container
    ├── Ubuntu base
    ├── bubblewrap (for Claude sandbox mode)
    ├── Claude Code CLI installed as non-root user (UID 1000)
    ├── Passwordless sudo configured
    ├── /workspace → host shared folder (:Z for SELinux)
    └── UID mapping via --userns=keep-id
```

## Implementation Guidelines

### Container Image (Containerfile/Dockerfile)

- Base: Ubuntu (latest LTS recommended)
- Create non-root user `claude` with UID 1000
- Install dependencies:
  - `bubblewrap` (required for Claude sandbox mode)
  - `curl` or `wget` (for Claude installation)
  - `sudo` (for passwordless sudo option)
  - `git`, `build-essential` (common development tools)
- Install Claude Code as the `claude` user:
  - Follow Claude Code installation instructions for Linux
  - Install to user's home directory (typically `~/.local/bin/claude`)
  - Do NOT install as root to ensure auto-updates work correctly
- Configure passwordless sudo for `claude` user
- Set container to run indefinitely (e.g., `sleep infinity` or similar)

### Build Script

```bash
#!/bin/bash
# Build the container image using Podman
podman build -t claude-sandbox -f Containerfile .
```

### Run Script

```bash
#!/bin/bash
# Start container with shared folder
# Usage: ./run.sh [/path/to/folder]
# Default: Share current working directory

SHARED_FOLDER="${1:-$(pwd)}"
CONTAINER_NAME="claude-sandbox"

podman run -d \
  --name "$CONTAINER_NAME" \
  --userns=keep-id \
  -v "$SHARED_FOLDER:/workspace:Z" \
  claude-sandbox \
  sleep infinity
```

Key flags:
- `--userns=keep-id`: Maps host UID to container UID for seamless file permissions
- `-v "$FOLDER:/workspace:Z"`: Mount shared folder with SELinux relabeling
- `-d`: Detached mode (run in background)

### Exec Script

```bash
#!/bin/bash
# Open interactive shell in running container
# Usage: ./exec.sh

CONTAINER_NAME="claude-sandbox"

podman exec -it "$CONTAINER_NAME" /bin/bash
```

### Claude Sandbox Mode

Claude Code has built-in sandbox mode that uses bubblewrap:
- Enabled with `--sandbox` flag or via settings
- Requires `bubblewrap` package installed in container
- Provides process isolation for bash commands
- No additional network filtering setup needed

## File Structure

Expected repository layout:
```
claude_container/
├── Containerfile          # Container image definition
├── README.md             # Project description
├── CLAUDE.md             # This file
└── scripts/
    ├── build.sh          # Build container image
    ├── run.sh            # Run container with shared folder
    └── exec.sh           # Access container shell
```

## Development Notes

### UID Mapping
- Container user `claude` should be UID 1000
- Host user should also be UID 1000 for seamless file permissions
- Use `--userns=keep-id` flag with `podman run`

### Shared Folder Mounting
- Mount point: `/workspace` inside container
- Use `:Z` suffix for SELinux compatibility (auto-relabeling)
- Files created in container appear with host user ownership

### Claude Installation
- **Critical**: Install Claude Code as the non-root user, not as root
- Installation typically goes to `~/.local/bin/claude`
- Auto-updates will only work if installed as regular user
- First run requires authentication: `claude auth login`

### Container Lifecycle
- Container runs `sleep infinity` to stay alive
- Access via `podman exec` (no SSH needed)
- Stop with: `podman stop claude-sandbox`
- Remove with: `podman rm claude-sandbox`
- Logs via: `podman logs claude-sandbox`

## Differences from Previous Implementation

This simplified approach:
- **Removes**: Tinyproxy, iptables firewall, network filtering, seccomp profiles
- **Relies on**: Claude's built-in sandbox mode (bubblewrap) for process isolation
- **Simpler**: No host-side proxy or firewall setup required
- **Trusts**: Claude Code's sandbox implementation for security

## Testing the Setup

After creating the scripts, test:
1. Build image: `./scripts/build.sh`
2. Start container: `./scripts/run.sh /path/to/test/project`
3. Verify container running: `podman ps | grep claude-sandbox`
4. Access container: `./scripts/exec.sh`
5. Inside container:
   - Check user: `whoami` (should be `claude`)
   - Check sudo: `sudo -v` (should not require password)
   - Check bubblewrap: `which bwrap`
   - Check Claude: `which claude`
   - Test Claude: `claude --version`
   - Navigate to workspace: `cd /workspace`
   - Verify file access: `ls -la`
