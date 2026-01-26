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

# Extract PS1 from host's interactive bash (with timeout to prevent hanging)
HOST_PS1=$(timeout 2 bash -i -c 'echo "$PS1"' 2>/dev/null || echo "")

# Build podman exec command
EXEC_CMD=(podman exec -it)

# Only pass PS1 if we successfully extracted one
if [ -n "$HOST_PS1" ]; then
    EXEC_CMD+=(-e "CONTAINER_PS1=${HOST_PS1}")
fi

"${EXEC_CMD[@]}" "$CONTAINER_NAME" /bin/bash
