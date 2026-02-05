#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Default instance name
INSTANCE_NAME="${INSTANCE_NAME:-default}"

# Build container name
CONTAINER_NAME=$(build_container_name "$PROFILE_NAME" "$INSTANCE_NAME")

# Check if container exists
if ! container_exists "$CONTAINER_NAME"; then
    die "Container '${CONTAINER_NAME}' does not exist. Use ./scripts/run.sh to create it."
fi

# Check if container is already running
if container_running "$CONTAINER_NAME"; then
    info "Container '${CONTAINER_NAME}' is already running."
    exit 0
fi

info "Starting container: ${CONTAINER_NAME}"
podman start "$CONTAINER_NAME"
info "Container started. Access with: ./scripts/exec.sh --profile ${PROFILE_NAME} --name ${INSTANCE_NAME}"
