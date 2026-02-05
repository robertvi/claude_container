#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# If no --name provided, try to auto-detect
if [[ -z "$INSTANCE_NAME" ]]; then
    # Get running containers (filtered by profile)
    RUNNING=$(list_running_containers "$PROFILE_NAME")

    COUNT=$(echo "$RUNNING" | grep -c . || echo 0)

    if [[ "$COUNT" -eq 0 ]]; then
        if [[ "$PROFILE_NAME" == "default" ]]; then
            die "No running containers found. Start one with ./scripts/run.sh"
        else
            die "No running containers found for profile '${PROFILE_NAME}'. Start one with ./scripts/run.sh --profile ${PROFILE_NAME}"
        fi
    elif [[ "$COUNT" -eq 1 ]]; then
        CONTAINER_NAME="$RUNNING"
        info "Auto-detected container: ${CONTAINER_NAME}"
    else
        echo "Multiple running containers found:"
        echo "$RUNNING" | sed 's/^/  /'
        die "Use --name to specify which container to exec into."
    fi
else
    CONTAINER_NAME=$(build_container_name "$PROFILE_NAME" "$INSTANCE_NAME")
fi

# Check if container is running
if ! container_running "$CONTAINER_NAME"; then
    if container_exists "$CONTAINER_NAME"; then
        die "Container '${CONTAINER_NAME}' exists but is not running. Use ./scripts/start.sh to start it."
    else
        die "Container '${CONTAINER_NAME}' does not exist."
    fi
fi

LOG_FILE="/tmp/claude-sandbox-${PROFILE_NAME}-exec.log"

echo "[$(date)] Accessing container: ${CONTAINER_NAME}" >> "$LOG_FILE"

podman exec -it "$CONTAINER_NAME" /bin/bash
