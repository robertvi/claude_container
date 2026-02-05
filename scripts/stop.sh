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
    die "Container '${CONTAINER_NAME}' does not exist."
fi

# Check if container is running
if ! container_running "$CONTAINER_NAME"; then
    info "Container '${CONTAINER_NAME}' is already stopped."
    exit 0
fi

info "Stopping container: ${CONTAINER_NAME}"
podman stop "$CONTAINER_NAME"
info "Container stopped. Use ./scripts/start.sh to restart or ./scripts/rm.sh to remove."
