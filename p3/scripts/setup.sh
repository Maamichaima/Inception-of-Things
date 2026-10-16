#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P3_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_CONF="${P3_DIR}/confs/application.yaml"

CLUSTER_NAME="iot-cluster"

echo "=========================================="
echo "1. Cleaning up existing cluster resources..."
echo "=========================================="
if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Deleting existing cluster: ${CLUSTER_NAME}..."
  k3d cluster delete "${CLUSTER_NAME}"
fi

echo "=========================================="
echo "2. Creating K3d Cluster: ${CLUSTER_NAME}..."
echo "=========================================="
k3d cluster create "${CLUSTER_NAME}" \
  --api-port 6443 \
  -p "8888:80@loadbalancer" \
  --wait

echo "=========================================="
echo "3. Creating Namespaces ('argocd' & 'dev')..."
echo "=========================================="
kubectl create namespace argocd
kubectl create namespace dev

echo "=========================================="
echo " 4. Deploying Argo CD Engine..."
echo "=========================================="
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=========================================="
echo "5. Waiting for Argo CD components to be ready..."
echo "=========================================="
sleep 5
kubectl wait --for=condition=available deployment \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s

kubectl wait --for=condition=available deployment \
  -l app.kubernetes.io/name=argocd-repo-server \
  -n argocd \
  --timeout=300s

echo "=========================================="
echo "6. Applying Argo CD Application manifest..."
echo "=========================================="
if [ ! -f "${APP_CONF}" ]; then
  echo "Error: Manifest not found at ${APP_CONF}"
  exit 1
fi
kubectl apply -f "${APP_CONF}"

echo "=========================================="
echo "7. Waiting for app deployment in 'dev'..."
echo "=========================================="
echo "Giving Argo CD up to 60s to pull from GitHub and spin up the pod..."
for i in {1..30}; do
  if kubectl get pods -n dev 2>/dev/null | grep -q "Running"; then
    echo "Dev pod is up and running!"
    break
  fi
  sleep 2
done

echo "=========================================="
echo "Argo CD Initial Admin Password:"
echo "=========================================="
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Password: ${ARGOCD_PASS}"

echo "=========================================="
echo "Setup Complete & Ready for Defense!"
echo "=========================================="
echo ""
echo "Verification Commands for Evaluation:"
echo "1. Namespaces:     kubectl get ns"
echo "2. Dev Pods:       kubectl get pods -n dev"
echo "3. App Curl Test:  curl http://localhost:8888/ (or tunnel: kubectl port-forward svc/wil-playground-service 9999:80 -n dev)"
echo "4. Argo CD UI:     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "                   URL: https://localhost:8080 | User: admin | Pass: ${ARGOCD_PASS}"
echo "=========================================="