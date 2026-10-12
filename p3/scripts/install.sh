#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================="
echo "🚀 Starting Part 3 Installation Script..."
echo "=========================================="

# 1. Update system packages
echo "🔄 Updating system package indexes..."
sudo apt-get update -y

# 2. Install Docker Engine dependencies
echo "🐋 Installing Docker Engine for Debian..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

# Configure Docker's official GPG keyring securely
sudo mkdir -p /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes

# Set up the stable Docker repository for this Debian release (bookworm, trixie, ...)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Allow your current user to run Docker commands without needing sudo prefix
sudo usermod -aG docker $USER

# Binaries below are downloaded for this CPU architecture (amd64 or arm64)
ARCH=$(dpkg --print-architecture)

# 3. Install K3d (K3s running inside Docker containers)
echo "📦 Installing K3d (Kubernetes inside Docker)..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash

# 4. Install kubectl CLI
echo "🕹️ Installing kubectl CLI..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# 5. Install Argo CD CLI
echo "🤖 Installing Argo CD CLI engine..."
curl -sSL -o argocd-linux-${ARCH} https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH}
sudo install -o root -g root -m 0755 argocd-linux-${ARCH} /usr/local/bin/argocd
rm argocd-linux-${ARCH}

echo "=========================================="
echo "✅ Installation Complete!"
echo "⚠️  CRITICAL: Run 'newgrp docker' to apply group permissions!"
echo "👉 Then run: bash $(dirname "$0")/setup.sh"
echo "=========================================="