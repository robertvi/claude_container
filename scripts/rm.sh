#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Default instance name
INSTANCE_NAME="${INSTANCE_NAME:-default}"

# Build container name
CONTAINER_NAME=$(build_container_name "$TEST_MODE" "$INSTANCE_NAME")

# Check if container exists
if ! container_exists "$CONTAINER_NAME"; then
    die "Container '${CONTAINER_NAME}' does not exist."
fi

# Check if container is running (unless --force)
if container_running "$CONTAINER_NAME"; then
    if [[ "$FORCE_MODE" == "true" ]]; then
        info "Force stopping container: ${CONTAINER_NAME}"
        podman stop "$CONTAINER_NAME"
    else
        die "Container '${CONTAINER_NAME}' is running. Stop it first or use --force."
    fi
fi

info "Removing container: ${CONTAINER_NAME}"
podman rm "$CONTAINER_NAME"
info "Container removed."
