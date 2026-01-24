#!/bin/bash
set -e

LOG_FILE="/tmp/claude-sandbox-build.log"

# Get current user's UID and GID
USER_UID=$(id -u)
USER_GID=$(id -g)

# Clear the log file
> "$LOG_FILE"

# Build the container image with user's UID/GID
echo "Building container image for UID:GID ${USER_UID}:${USER_GID}... (logging to ${LOG_FILE})"
podman build \
  --no-cache \
  --build-arg USER_UID="${USER_UID}" \
  --build-arg USER_GID="${USER_GID}" \
  -t claude-sandbox \
  -f Containerfile . 2>&1 | tee "$LOG_FILE"

echo "Build complete. Image tagged as: claude-sandbox"
echo "Built with UID:GID ${USER_UID}:${USER_GID}"
echo "Full build log saved to: ${LOG_FILE}"
