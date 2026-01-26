#!/bin/bash
set -e

LOG_FILE="/tmp/claude-sandbox-test-build.log"
USER_UID=$(id -u)
USER_GID=$(id -g)

> "$LOG_FILE"

echo "Building TEST container image for UID:GID ${USER_UID}:${USER_GID}..."
podman build \
  --no-cache \
  --build-arg USER_UID="${USER_UID}" \
  --build-arg USER_GID="${USER_GID}" \
  -t claude-sandbox-test \
  -f Containerfile.test . 2>&1 | tee "$LOG_FILE"

echo "Build complete. Image tagged as: claude-sandbox-test"
