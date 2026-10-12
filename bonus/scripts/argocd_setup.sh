#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Installs Argo CD and makes it deploy the app in 'dev' from the local GitLab

CONFS_DIR="$(cd "$(dirname "$0")/../confs" && pwd)"
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "=== Namespaces argocd and dev ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "=== Install Argo CD ==="
# Server-side apply: Argo CD CRDs are too big for a client-side apply
kubectl apply -n argocd --server-side --force-conflicts -f "${ARGOCD_MANIFEST}"
kubectl wait --for=condition=available deployment --all -n argocd --timeout=600s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

echo "=== Argo CD application (source: local GitLab) ==="
kubectl apply -f "${CONFS_DIR}/application.yaml"

echo "=== Waiting for Argo CD to deploy the app in 'dev' ==="
until kubectl get deployment playground -n dev >/dev/null 2>&1; do
  sleep 5
done
kubectl rollout status deployment/playground -n dev --timeout=600s

# Expose Argo CD UI (8080) and the app (8888) on this machine.
# The loop restarts the port-forward when the pod is replaced (v1 -> v2 update).
echo "=== Port-forwards ==="
pkill -f "kubectl port-forward" >/dev/null 2>&1 || true
nohup bash -c 'while true; do kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0; sleep 2; done' >/tmp/pf-argocd.log 2>&1 &
nohup bash -c 'while true; do kubectl port-forward svc/playground-service -n dev 8888:8888 --address 0.0.0.0; sleep 2; done' >/tmp/pf-app.log 2>&1 &
sleep 3
