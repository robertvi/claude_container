#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

parse_common_args "$@"

# Validate profile exists
validate_profile "$PROFILE_NAME"

IMAGE_NAME=$(get_image_name "$PROFILE_NAME")
LOG_FILE="/tmp/claude-sandbox-${PROFILE_NAME}-build.log"

info "Building image for profile: ${PROFILE_NAME}"

# Prepare build context (merges default + profile files)
BUILD_DIR=$(prepare_build_context "$PROFILE_NAME")

# Ensure cleanup on exit
cleanup() {
    if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
    fi
}
trap cleanup EXIT

USER_UID=$(id -u)
USER_GID=$(id -g)

# Determine NOSUDO value for build arg
if [[ "$NO_SUDO_MODE" == "true" ]]; then
    NOSUDO_ARG="true"
    info "Building with sudo DISABLED for claude user"
else
    NOSUDO_ARG="false"
fi

# Determine cache flag
CACHE_FLAG=""
if [[ "$NO_CACHE_MODE" == "true" ]]; then
    CACHE_FLAG="--no-cache"
    info "Building with no cache (forcing full rebuild)"
fi

> "$LOG_FILE"

info "Building container image for UID:GID ${USER_UID}:${USER_GID}... (logging to ${LOG_FILE})"
podman build \
  $CACHE_FLAG \
  --build-arg USER_UID="${USER_UID}" \
  --build-arg USER_GID="${USER_GID}" \
  --build-arg NOSUDO="${NOSUDO_ARG}" \
  -t "$IMAGE_NAME" \
  -f "$BUILD_DIR/Containerfile" "$BUILD_DIR" 2>&1 | tee "$LOG_FILE"

info "Build complete. Image tagged as: ${IMAGE_NAME}"
