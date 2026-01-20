#!/bin/bash
##
## Build Script for Claude Code Container
## Builds the Podman container image
##

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

IMAGE_NAME="claude-sandbox"
IMAGE_TAG="latest"

echo "=== Building Claude Code Container ==="
echo ""
echo "Project root: $PROJECT_ROOT"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    echo "ERROR: podman is not installed"
    echo "Please install podman first:"
    echo "  Ubuntu/Debian: sudo apt-get install podman"
    echo "  Fedora: sudo dnf install podman"
    echo "  RHEL/CentOS: sudo yum install podman"
    exit 1
fi

# Determine which SSH key to use (prefer ed25519)
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    SSH_PUB_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
    SSH_KEY_TYPE="ed25519"
elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
    SSH_KEY_TYPE="rsa"
else
    echo "No SSH key found. Generating ed25519 key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "claude-sandbox-key"
    SSH_PUB_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
    SSH_KEY_TYPE="ed25519"
fi

echo "Using SSH public key: $SSH_PUB_KEY_PATH ($SSH_KEY_TYPE)"
echo ""

# Copy SSH public key to build context
cp "$SSH_PUB_KEY_PATH" "$PROJECT_ROOT/authorized_keys.tmp"

# Build the container
echo "[1/2] Building container image..."
cd "$PROJECT_ROOT"
podman build -t "$IMAGE_NAME:$IMAGE_TAG" -f Containerfile .

# Clean up temporary key file
rm -f "$PROJECT_ROOT/authorized_keys.tmp"

echo ""
echo "[2/2] Verifying image..."
if podman image exists "$IMAGE_NAME:$IMAGE_TAG"; then
    echo "✓ Image built successfully"
    echo ""
    podman images "$IMAGE_NAME:$IMAGE_TAG"
else
    echo "✗ ERROR: Image build failed"
    exit 1
fi

echo ""
echo "=== Build complete! ==="
echo ""
echo "Next steps:"
echo "  1. Run the container: ./scripts/run.sh /path/to/shared/folder"
echo "  2. Connect via SSH: ./scripts/connect.sh"
echo ""
