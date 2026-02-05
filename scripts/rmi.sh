#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

IMAGE_NAME=$(get_image_name "$PROFILE_NAME")

# Check if image exists
if ! image_exists "$IMAGE_NAME"; then
    die "Image '${IMAGE_NAME}' does not exist."
fi

# Check for containers using this image (containers for this profile)
CONTAINERS=$(list_sandbox_containers "$PROFILE_NAME")

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
