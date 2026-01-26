#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

# Get all claude-sandbox containers
CONTAINERS=$(list_sandbox_containers "false")

if [[ -z "$CONTAINERS" ]]; then
    info "No claude-sandbox containers found."
    exit 0
fi

# Print header
printf "%-35s %-12s %s\n" "CONTAINER" "STATUS" "SHARED FOLDER"
printf "%-35s %-12s %s\n" "---------" "------" "-------------"

# Process each container
while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    # Get container status
    if container_running "$name"; then
        STATUS="running"
    else
        STATUS="stopped"
    fi

    # Get mount info (source path for /workspace)
    MOUNT_SOURCE=$(podman inspect "$name" --format '{{range .Mounts}}{{if eq .Destination "/workspace"}}{{.Source}}{{end}}{{end}}' 2>/dev/null || echo "N/A")

    printf "%-35s %-12s %s\n" "$name" "$STATUS" "$MOUNT_SOURCE"
done <<< "$CONTAINERS"
