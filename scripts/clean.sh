#!/bin/bash
set -e

CONTAINER_NAME="claude-sandbox"
IMAGE_NAME="claude-sandbox"
LOG_FILE="/tmp/claude-sandbox-clean.log"

# Clear the log file
> "$LOG_FILE"

echo "Cleaning up Claude sandbox containers and images..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "Full clean log saved to: ${LOG_FILE}"

podman container stop -ai | tee -a "$LOG_FILE"
podman image rm -af | tee -a "$LOG_FILE"

echo "Cleanup complete!" | tee -a "$LOG_FILE"

