#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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
  -f "$PROJECT_DIR/Containerfile.test" "$PROJECT_DIR" 2>&1 | tee "$LOG_FILE"

echo "Build complete. Image tagged as: claude-sandbox-test"
