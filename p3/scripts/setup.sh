#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Run after install.sh (and 'newgrp docker'):
# creates the K3d cluster, the argocd/dev namespaces, installs Argo CD
# and lets it deploy the application from the GitHub repository.

CLUSTER_NAME="iot-p3"
CONFS_DIR="$(cd "$(dirname "$0")/../confs" && pwd)"
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "=========================================="
echo "🚀 Starting Part 3 Setup Script..."
echo "=========================================="

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not usable by $USER. Run 'newgrp docker' (or log out/in) and retry."
  exit 1
fi

# wil42/playground is only built for amd64: on an arm64 machine, register
# QEMU emulation so the K3d nodes can still run it
if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
  echo "🧩 arm64 host detected: enabling amd64 emulation..."
  docker run --privileged --rm tonistiigi/binfmt --install amd64
fi

# 1. Create the K3d cluster (K3s running inside Docker containers)
echo "📦 Creating K3d cluster '${CLUSTER_NAME}'..."
if k3d cluster get "${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "Cluster already exists, skipping."
else
  k3d cluster create "${CLUSTER_NAME}" --wait
fi
kubectl config use-context "k3d-${CLUSTER_NAME}"

# 2. Create the two namespaces
echo "🗂️  Creating namespaces argocd and dev..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

# 3. Install Argo CD (server-side apply: its CRDs are too big for a client-side apply)
echo "🤖 Installing Argo CD..."
kubectl apply -n argocd --server-side --force-conflicts -f "${ARGOCD_MANIFEST}"

echo "⏳ Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available deployment --all -n argocd --timeout=600s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

# 4. Tell Argo CD which GitHub repository to watch
echo "🔗 Creating the Argo CD application..."
kubectl apply -f "${CONFS_DIR}/application.yaml"

echo "⏳ Waiting for Argo CD to deploy the app in 'dev'..."
until kubectl get deployment playground -n dev >/dev/null 2>&1; do
  sleep 5
done
kubectl rollout status deployment/playground -n dev --timeout=600s

# 5. Expose Argo CD UI (8080) and the app (8888) on this machine.
# The loop restarts the port-forward when the pod is replaced (v1 -> v2 update).
echo "🔌 Starting port-forwards..."
pkill -f "kubectl port-forward" >/dev/null 2>&1 || true
nohup bash -c 'while true; do kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0; sleep 2; done' >/tmp/pf-argocd.log 2>&1 &
nohup bash -c 'while true; do kubectl port-forward svc/playground-service -n dev 8888:8888 --address 0.0.0.0; sleep 2; done' >/tmp/pf-app.log 2>&1 &
sleep 3

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

echo "=========================================="
echo "✅ Setup Complete!"
echo ""
echo "Argo CD UI : https://localhost:8080"
echo "  user     : admin"
echo "  password : ${ARGOCD_PASSWORD}"
echo ""
echo "App        : curl http://localhost:8888/"
echo ""
echo "Check      : kubectl get ns"
echo "             kubectl get pods -n dev"
echo "=========================================="
