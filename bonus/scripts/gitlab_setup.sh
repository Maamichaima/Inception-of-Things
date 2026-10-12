#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Creates the K3d cluster and installs GitLab in the 'gitlab' namespace

CLUSTER_NAME="iot-bonus"
CHART_VERSION="9.11.8"   # GitLab CE v18.11
GITLAB_HOST="gitlab.local"
CONFS_DIR="$(cd "$(dirname "$0")/../confs" && pwd)"

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not usable by $USER. Run 'newgrp docker' (or log out/in) and retry."
  exit 1
fi

# wil42/playground is only built for amd64: on an arm64 machine, register
# QEMU emulation so the K3d nodes can still run it
if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
  echo "=== arm64 host detected: enabling amd64 emulation ==="
  docker run --privileged --rm tonistiigi/binfmt --install amd64
fi

echo "=== K3d cluster creation ==="
# Port 80 of this machine -> K3d load balancer -> Traefik -> GitLab ingress
if k3d cluster get "${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "Cluster already exists, skipping."
else
  k3d cluster create "${CLUSTER_NAME}" \
    --servers 1 \
    --port "80:80@loadbalancer" \
    --wait
fi
kubectl config use-context "k3d-${CLUSTER_NAME}"

echo "=== Namespace ==="
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

echo "=== Install GitLab (chart ${CHART_VERSION}) ==="
helm repo add gitlab https://charts.gitlab.io/ --force-update
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --version "${CHART_VERSION}" \
  --namespace gitlab \
  --timeout 900s \
  -f "${CONFS_DIR}/gitlab_values.yaml"

echo "=== Wait for GitLab to be ready (this can take 10-15 minutes) ==="
kubectl wait --for=condition=available deployment --all -n gitlab --timeout=1800s

# Make gitlab.local resolve to this machine
if ! grep -q " ${GITLAB_HOST}" /etc/hosts; then
  echo "127.0.0.1 ${GITLAB_HOST}" | sudo tee -a /etc/hosts > /dev/null
fi

until curl -sf "http://${GITLAB_HOST}/users/sign_in" > /dev/null; do
  echo "Waiting for http://${GITLAB_HOST} ..."
  sleep 10
done

echo "=== GitLab is up: http://${GITLAB_HOST} ==="
echo "user     : root"
echo "password : $(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)"
