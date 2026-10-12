#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Installs every tool the bonus needs: Docker, K3d, kubectl, Helm, git

echo "=========================================="
echo "🚀 Starting Bonus Installation Script..."
echo "=========================================="

echo "🔄 Updating system package indexes..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

# 1. Docker Engine (K3d runs K3s inside Docker containers)
if ! command -v docker >/dev/null 2>&1; then
  echo "🐋 Installing Docker Engine for Debian..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi
sudo usermod -aG docker "$USER"

# Binaries below are downloaded for this CPU architecture (amd64 or arm64)
ARCH=$(dpkg --print-architecture)

# 2. K3d
if ! command -v k3d >/dev/null 2>&1; then
  echo "📦 Installing K3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash
fi

# 3. kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  echo "🕹️ Installing kubectl CLI..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# 4. Helm (used to install GitLab)
if ! command -v helm >/dev/null 2>&1; then
  echo "⛵ Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "Installed versions:"
docker --version
kubectl version --client
k3d version
helm version --short
git --version

echo "=========================================="
echo "✅ Installation Complete!"
echo "⚠️  CRITICAL: Run 'newgrp docker' to apply group permissions!"
echo "👉 Then run: bash $(dirname "$0")/setup.sh"
echo "=========================================="
