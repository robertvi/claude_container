#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Check if --profile was explicitly passed
PROFILE_SPECIFIED=false
for arg in "$@"; do
    if [[ "$arg" == "--profile" ]]; then
        PROFILE_SPECIFIED=true
        break
    fi
done

# Determine what we're nuking
if [[ "$PROFILE_SPECIFIED" == "true" ]]; then
    TARGET_DESC="profile '${PROFILE_NAME}' resources (${BASE_NAME}-${PROFILE_NAME}-* containers and ${BASE_NAME}-${PROFILE_NAME} image)"
    CONTAINERS=$(list_sandbox_containers "$PROFILE_NAME")
    IMAGES_TO_REMOVE=("$(get_image_name "$PROFILE_NAME")")
else
    TARGET_DESC="ALL claude-sandbox resources (all containers and all images)"
    CONTAINERS=$(list_sandbox_containers "")
    # Get all claude-sandbox images
    mapfile -t IMAGES_TO_REMOVE < <(list_sandbox_images)
fi

# Confirmation prompt unless --force
if [[ "$FORCE_MODE" != "true" ]]; then
    echo "This will remove ${TARGET_DESC}:"
    echo ""

    if [[ -n "$CONTAINERS" ]]; then
        echo "Containers to remove:"
        echo "$CONTAINERS" | sed 's/^/  /'
    else
        echo "Containers to remove: (none)"
    fi

    echo ""
    echo "Images to remove:"
    if [[ ${#IMAGES_TO_REMOVE[@]} -gt 0 ]]; then
        for img in "${IMAGES_TO_REMOVE[@]}"; do
            if [[ -n "$img" ]] && image_exists "$img"; then
                echo "  $img"
            fi
        done
    else
        echo "  (none)"
    fi

    echo ""
    read -r -p "Are you sure? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        info "Aborted."
        exit 0
    fi
fi

# Stop and remove containers
if [[ -n "$CONTAINERS" ]]; then
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if container_running "$name"; then
            info "Stopping: $name"
            podman stop "$name" >/dev/null
        fi
        info "Removing: $name"
        podman rm "$name" >/dev/null
    done <<< "$CONTAINERS"
else
    info "No containers to remove."
fi

# Remove images
for img in "${IMAGES_TO_REMOVE[@]}"; do
    if [[ -n "$img" ]] && image_exists "$img"; then
        info "Removing image: $img"
        podman rmi "$img" >/dev/null
    fi
done

info "Cleanup complete."
