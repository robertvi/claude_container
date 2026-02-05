#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Get containers (filtered by profile if specified via --profile)
# Note: PROFILE_NAME defaults to "default", but for list we want to show all unless explicitly filtered
# Check if --profile was explicitly passed by looking at original args
PROFILE_FILTER=""
for arg in "$@"; do
    if [[ "$arg" == "--profile" ]]; then
        PROFILE_FILTER="$PROFILE_NAME"
        break
    fi
done

CONTAINERS=$(list_sandbox_containers "$PROFILE_FILTER")

if [[ -z "$CONTAINERS" ]]; then
    if [[ -n "$PROFILE_FILTER" ]]; then
        info "No claude-sandbox containers found for profile '${PROFILE_FILTER}'."
    else
        info "No claude-sandbox containers found."
    fi
    exit 0
fi

# Print header
printf "%-40s %-12s %-12s %s\n" "CONTAINER" "PROFILE" "STATUS" "SHARED FOLDER"
printf "%-40s %-12s %-12s %s\n" "---------" "-------" "------" "-------------"

# Process each container
while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    # Extract profile from container name (claude-sandbox-<profile>-<instance>)
    # Remove "claude-sandbox-" prefix, then get first part before remaining "-"
    PROFILE=$(echo "$name" | sed "s/^${BASE_NAME}-//" | cut -d'-' -f1)

    # Get container status
    if container_running "$name"; then
        STATUS="running"
    else
        STATUS="stopped"
    fi

    # Get mount info (source path for /workspace)
    MOUNT_SOURCE=$(podman inspect "$name" --format '{{range .Mounts}}{{if eq .Destination "/workspace"}}{{.Source}}{{end}}{{end}}' 2>/dev/null || echo "N/A")

    printf "%-40s %-12s %-12s %s\n" "$name" "$PROFILE" "$STATUS" "$MOUNT_SOURCE"
done <<< "$CONTAINERS"
