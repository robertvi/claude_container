#!/bin/bash
set -e

CONTAINER_NAME="claude-sandbox-test"
LOG_FILE="/tmp/claude-sandbox-test-exec.log"

> "$LOG_FILE"

if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Test container '${CONTAINER_NAME}' is not running."
    echo "Start it with: ./scripts/run-test.sh"
    exit 1
fi

echo "[$(date)] Accessing test container: ${CONTAINER_NAME}" >> "$LOG_FILE"

podman exec -it "$CONTAINER_NAME" /bin/bash
