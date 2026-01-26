#!/bin/bash
set -e

LOG_FILE="/tmp/claude-sandbox-test-build.log"
USER_UID=$(id -u)
USER_GID=$(id -g)

> "$LOG_FILE"

# Extract PS1 from host's interactive bash (with timeout to prevent hanging)
HOST_PS1=$(timeout 2 bash -i -c 'echo "$PS1"' 2>/dev/null || echo "")

if [ -n "$HOST_PS1" ]; then
    echo "Captured host PS1: $HOST_PS1"
else
    echo "No host PS1 found, using container default"
fi

echo "Building TEST container image for UID:GID ${USER_UID}:${USER_GID}..."
podman build \
  --no-cache \
  --build-arg USER_UID="${USER_UID}" \
  --build-arg USER_GID="${USER_GID}" \
  --build-arg HOST_PS1="${HOST_PS1}" \
  -t claude-sandbox-test \
  -f Containerfile.test . 2>&1 | tee "$LOG_FILE"

echo "Build complete. Image tagged as: claude-sandbox-test"
