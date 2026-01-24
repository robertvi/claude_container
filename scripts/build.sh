#!/bin/bash
set -e

# Build the container image
podman build -t claude-sandbox -f Containerfile .

echo "Build complete. Image tagged as: claude-sandbox"
