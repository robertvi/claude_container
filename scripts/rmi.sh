#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

IMAGE_NAME=$(get_image_name "$TEST_MODE")

# Check if image exists
if ! image_exists "$IMAGE_NAME"; then
    die "Image '${IMAGE_NAME}' does not exist."
fi

# Check for containers using this image
if [[ "$TEST_MODE" == "true" ]]; then
    CONTAINERS=$(list_sandbox_containers "true")
else
    # For prod image, check for non-test containers
    CONTAINERS=$(podman ps -a --format "{{.Names}}" | grep "^${BASE_NAME}-" | grep -v "^${BASE_TEST_NAME}-" || true)
fi

if [[ -n "$CONTAINERS" ]]; then
    echo "Warning: The following containers use this image:"
    echo "$CONTAINERS" | sed 's/^/  /'
    if [[ "$FORCE_MODE" != "true" ]]; then
        die "Remove containers first or use --force."
    fi
    info "Force removing image despite existing containers..."
fi

info "Removing image: ${IMAGE_NAME}"
podman rmi "$IMAGE_NAME"
info "Image removed."
