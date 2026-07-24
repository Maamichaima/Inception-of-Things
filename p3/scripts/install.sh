#!/bin/bash

set -e

echo "Updating packages..."
sudo apt update

echo "Installing dependencies..."
sudo apt install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

####################################################
# Docker
####################################################

if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."

    curl -fsSL https://get.docker.com | sh

    sudo usermod -aG docker $USER
fi

####################################################
# kubectl
####################################################

if ! command -v kubectl &> /dev/null
then
    echo "Installing kubectl..."

    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    chmod +x kubectl

    sudo mv kubectl /usr/local/bin/
fi

####################################################
# k3d
####################################################

if ! command -v k3d &> /dev/null
then
    echo "Installing k3d..."

    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

####################################################
# Create Cluster
####################################################

if ! k3d cluster list | grep -q iot
then
    echo "Creating cluster..."

    k3d cluster create iot
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Installation finished."
echo ""
kubectl get nodes