#!/bin/bash
set -e

echo "Installing NVIDIA Container Toolkit..."

# Add NVIDIA's package repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

echo ""
echo "Generating CDI spec..."
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

echo ""
echo "Done. Verifying..."
nvidia-ctk --version
echo "CDI spec: $(ls -la /etc/cdi/nvidia.yaml)"

echo ""
echo "You can now retry:"
echo "  ./scripts/rm.sh --test --name gpu-test"
echo "  ./scripts/run.sh --test --gpu --name gpu-test /tmp/test_folder"
