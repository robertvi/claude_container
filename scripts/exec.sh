#!/bin/bash
set -e

CONTAINER_NAME="claude-sandbox"
LOG_FILE="/tmp/claude-sandbox-exec.log"

# Clear the log file
> "$LOG_FILE"

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is not running."
    echo "Start it with: ./scripts/run.sh"
    exit 1
fi

# Log the exec attempt
echo "[$(date)] Accessing container: ${CONTAINER_NAME}" >> "$LOG_FILE"

# Execute interactive bash shell
podman exec -it "$CONTAINER_NAME" /bin/bash
