#!/bin/bash
set -e

CONTAINER_NAME="claude-sandbox"

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is not running."
    echo "Start it with: ./scripts/run.sh"
    exit 1
fi

# Execute interactive bash shell
podman exec -it "$CONTAINER_NAME" /bin/bash
