#!/bin/bash
set -e

SHARED_FOLDER="${1:-$(pwd)}"
CONTAINER_NAME="claude-sandbox-test"
LOG_FILE="/tmp/claude-sandbox-test-run.log"
USER_UID=$(id -u)
USER_GID=$(id -g)

> "$LOG_FILE"

if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Test container '${CONTAINER_NAME}' already exists."
    echo "To restart, first run: podman rm -f ${CONTAINER_NAME}"
    exit 1
fi

echo "Starting TEST container..."
podman run -d \
  --name "$CONTAINER_NAME" \
  --hostname claude-sandbox-test \
  --userns=keep-id:uid=${USER_UID},gid=${USER_GID} \
  -v "$SHARED_FOLDER:/workspace:Z" \
  claude-sandbox-test \
  sleep infinity 2>&1 | tee "$LOG_FILE"

echo "Test container started: ${CONTAINER_NAME}"
echo "Access with: ./scripts/exec-test.sh"
