#!/bin/bash
set -e

SHARED_FOLDER="${1:-$(pwd)}"
CONTAINER_NAME="claude-sandbox"
LOG_FILE="/tmp/claude-sandbox-run.log"

# Get current user's UID and GID
USER_UID=$(id -u)
USER_GID=$(id -g)

# Clear the log file
> "$LOG_FILE"

# Check if container already exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' already exists."
    echo "To restart, first run: podman rm -f ${CONTAINER_NAME}"
    exit 1
fi

# Start the container
echo "Starting container with UID:GID ${USER_UID}:${USER_GID}... (logging to ${LOG_FILE})"
podman run -d \
  --name "$CONTAINER_NAME" \
  --hostname claude-sandbox \
  --userns=keep-id:uid=${USER_UID},gid=${USER_GID} \
  -v "$SHARED_FOLDER:/workspace:Z" \
  claude-sandbox \
  sleep infinity 2>&1 | tee "$LOG_FILE"

echo "Container started: ${CONTAINER_NAME}"
echo "Shared folder: ${SHARED_FOLDER} -> /workspace"
echo "Access with: ./scripts/exec.sh"
echo "Full run log saved to: ${LOG_FILE}"
