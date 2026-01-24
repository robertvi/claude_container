#!/bin/bash
set -e

SHARED_FOLDER="${1:-$(pwd)}"
CONTAINER_NAME="claude-sandbox"

# Check if container already exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' already exists."
    echo "To restart, first run: podman rm -f ${CONTAINER_NAME}"
    exit 1
fi

# Start the container
podman run -d \
  --name "$CONTAINER_NAME" \
  --userns=keep-id \
  -v "$SHARED_FOLDER:/workspace:Z" \
  claude-sandbox \
  sleep infinity

echo "Container started: ${CONTAINER_NAME}"
echo "Shared folder: ${SHARED_FOLDER} -> /workspace"
echo "Access with: ./scripts/exec.sh"
