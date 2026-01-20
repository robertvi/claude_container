#!/bin/bash
##
## Connect Script for Claude Code Container
## Connects to the container via SSH
##

CONTAINER_NAME="claude-sandbox"

echo "=== Connecting to Claude Code Container ==="
echo ""

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    echo "ERROR: podman is not installed"
    exit 1
fi

# Check if container is running
if ! podman ps | grep -q "$CONTAINER_NAME"; then
    echo "ERROR: Container '$CONTAINER_NAME' is not running"
    echo ""
    echo "Start it with: ./scripts/run.sh /path/to/shared/folder"
    exit 1
fi

echo "Connecting via SSH..."
echo "Using key-based authentication"
echo ""

# Determine which SSH key to use (prefer ed25519)
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    SSH_KEY_PATH="$HOME/.ssh/id_rsa"
else
    echo "ERROR: No SSH key found at ~/.ssh/id_ed25519 or ~/.ssh/id_rsa"
    exit 1
fi

# Connect via SSH and change to /workspace directory
ssh -p 2222 -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t claude@localhost "cd /workspace && exec bash -l"
