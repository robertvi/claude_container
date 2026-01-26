#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Default instance name
INSTANCE_NAME="${INSTANCE_NAME:-default}"

# Shared folder is the first remaining arg, or pwd
SHARED_FOLDER="${REMAINING_ARGS[0]:-$(pwd)}"

# Build container and image names
CONTAINER_NAME=$(build_container_name "$TEST_MODE" "$INSTANCE_NAME")
IMAGE_NAME=$(get_image_name "$TEST_MODE")

if [[ "$TEST_MODE" == "true" ]]; then
    LOG_FILE="/tmp/claude-sandbox-test-run.log"
else
    LOG_FILE="/tmp/claude-sandbox-run.log"
fi

# Check if image exists
if ! image_exists "$IMAGE_NAME"; then
    die "Image '${IMAGE_NAME}' does not exist. Run: ./scripts/build.sh${TEST_MODE:+ --test}"
fi

# Check if container already exists
if container_exists "$CONTAINER_NAME"; then
    die "Container '${CONTAINER_NAME}' already exists. Use ./scripts/rm.sh to remove it first."
fi

USER_UID=$(id -u)
USER_GID=$(id -g)

> "$LOG_FILE"

info "Starting container '${CONTAINER_NAME}' with UID:GID ${USER_UID}:${USER_GID}..."
podman run -d \
  --name "$CONTAINER_NAME" \
  --hostname "$CONTAINER_NAME" \
  --userns=keep-id:uid=${USER_UID},gid=${USER_GID} \
  -v "$SHARED_FOLDER:/workspace:Z" \
  "$IMAGE_NAME" 2>&1 | tee "$LOG_FILE"

info "Container started: ${CONTAINER_NAME}"
info "Shared folder: ${SHARED_FOLDER} -> /workspace"
info "Access with: ./scripts/exec.sh${TEST_MODE:+ --test} --name ${INSTANCE_NAME}"
