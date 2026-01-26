#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Determine what we're nuking
if [[ "$TEST_MODE" == "true" ]]; then
    TARGET_DESC="TEST resources only (claude-sandbox-test-* containers and claude-sandbox-test image)"
    CONTAINER_PATTERN="^${BASE_TEST_NAME}-"
    IMAGES_TO_REMOVE=("$BASE_TEST_NAME")
else
    TARGET_DESC="ALL claude-sandbox resources (all containers and both images)"
    CONTAINER_PATTERN="^${BASE_NAME}"
    IMAGES_TO_REMOVE=("$BASE_NAME" "$BASE_TEST_NAME")
fi

# Find containers to remove
CONTAINERS=$(podman ps -a --format "{{.Names}}" | grep "$CONTAINER_PATTERN" || true)

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
    for img in "${IMAGES_TO_REMOVE[@]}"; do
        if image_exists "$img"; then
            echo "  $img"
        fi
    done

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
    if image_exists "$img"; then
        info "Removing image: $img"
        podman rmi "$img" >/dev/null
    fi
done

info "Cleanup complete."
