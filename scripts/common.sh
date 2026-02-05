#!/bin/bash
# Common functions for claude-sandbox scripts

# Base name prefix for all containers and images
BASE_NAME="claude-sandbox"

# Directory containing this script
COMMON_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$COMMON_SCRIPT_DIR/.." && pwd)"

# Output helpers
die() {
    echo "Error: $1" >&2
    exit 1
}

info() {
    echo "$1"
}

# Get profile directory path
# Usage: get_profile_dir <profile_name>
get_profile_dir() {
    local profile="$1"
    if [[ "$profile" == "default" ]]; then
        echo "$PROJECT_ROOT/default"
    else
        echo "$PROJECT_ROOT/profiles/$profile"
    fi
}

# Validate that a profile exists
# Usage: validate_profile <profile_name>
validate_profile() {
    local profile="$1"
    local profile_dir
    profile_dir=$(get_profile_dir "$profile")

    if [[ ! -d "$profile_dir" ]]; then
        die "Profile '$profile' does not exist. Expected directory: $profile_dir"
    fi
}

# Prepare build context by merging default + profile files
# Usage: prepare_build_context <profile_name>
# Returns: path to temporary build directory (caller must clean up)
prepare_build_context() {
    local profile="$1"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Start with default files
    cp -r "$PROJECT_ROOT/default/"* "$tmp_dir/"

    # Overlay profile-specific files (if not default profile)
    if [[ "$profile" != "default" ]]; then
        local profile_dir
        profile_dir=$(get_profile_dir "$profile")
        # Copy profile files, excluding .gitkeep
        find "$profile_dir" -maxdepth 1 -type f ! -name '.gitkeep' -exec cp {} "$tmp_dir/" \;
    fi

    echo "$tmp_dir"
}

# Get image name for a profile
# Usage: get_image_name <profile>
get_image_name() {
    local profile="${1:-default}"
    echo "${BASE_NAME}-${profile}"
}

# Build full container name
# Usage: build_container_name <profile> <instance>
build_container_name() {
    local profile="${1:-default}"
    local instance="${2:-default}"
    echo "${BASE_NAME}-${profile}-${instance}"
}

# Check if container exists (running or stopped)
# Usage: container_exists <name>
container_exists() {
    local name="$1"
    podman ps -a --format "{{.Names}}" | grep -q "^${name}$"
}

# Check if container is running
# Usage: container_running <name>
container_running() {
    local name="$1"
    podman ps --format "{{.Names}}" | grep -q "^${name}$"
}

# Check if image exists
# Usage: image_exists <name>
image_exists() {
    local name="$1"
    podman image exists "$name" 2>/dev/null
}

# Parse common arguments: --profile <name>, --name <value>, --force, --no-sudo, --no-cache
# Sets global variables: PROFILE_NAME, INSTANCE_NAME, FORCE_MODE, NO_SUDO_MODE, NO_CACHE_MODE, REMAINING_ARGS
# Usage: parse_common_args "$@"
parse_common_args() {
    PROFILE_NAME=""
    INSTANCE_NAME=""
    FORCE_MODE=false
    NO_SUDO_MODE=false
    NO_CACHE_MODE=false
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                if [[ -z "$2" || "$2" == --* ]]; then
                    die "--profile requires a value"
                fi
                PROFILE_NAME="$2"
                shift 2
                ;;
            --name)
                if [[ -z "$2" || "$2" == --* ]]; then
                    die "--name requires a value"
                fi
                INSTANCE_NAME="$2"
                shift 2
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --no-sudo)
                NO_SUDO_MODE=true
                shift
                ;;
            --no-cache)
                NO_CACHE_MODE=true
                shift
                ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done

    # Default profile to "default"
    PROFILE_NAME="${PROFILE_NAME:-default}"
}

# List all claude-sandbox containers (returns names)
# Usage: list_sandbox_containers [profile]
# If profile is specified, only list containers for that profile
# If profile is empty, list all claude-sandbox containers
list_sandbox_containers() {
    local profile="$1"
    if [[ -n "$profile" ]]; then
        podman ps -a --format "{{.Names}}" | grep "^${BASE_NAME}-${profile}-" || true
    else
        podman ps -a --format "{{.Names}}" | grep "^${BASE_NAME}-" || true
    fi
}

# List running claude-sandbox containers (returns names)
# Usage: list_running_containers [profile]
list_running_containers() {
    local profile="$1"
    if [[ -n "$profile" ]]; then
        podman ps --format "{{.Names}}" | grep "^${BASE_NAME}-${profile}-" || true
    else
        podman ps --format "{{.Names}}" | grep "^${BASE_NAME}-" || true
    fi
}

# Count running containers matching pattern
# Usage: count_running_containers [profile]
count_running_containers() {
    local profile="$1"
    list_running_containers "$profile" | wc -l
}

# List all available profiles
# Usage: list_profiles
list_profiles() {
    local profiles=("default")
    for dir in "$PROJECT_ROOT/profiles/"*/; do
        if [[ -d "$dir" ]]; then
            local name
            name=$(basename "$dir")
            # Skip if only contains .gitkeep
            if [[ -n "$(find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' | head -1)" ]]; then
                profiles+=("$name")
            fi
        fi
    done
    printf '%s\n' "${profiles[@]}"
}

# List all claude-sandbox images
# Usage: list_sandbox_images
list_sandbox_images() {
    podman images --format "{{.Repository}}" | grep "^${BASE_NAME}-" || true
}
