#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Run after install.sh (and 'newgrp docker'): builds the whole bonus lab
#   1. K3d cluster + GitLab in namespace 'gitlab'
#   2. Project root/cmaami-iot in GitLab with the app manifests
#   3. Argo CD in namespace 'argocd', deploying the app in 'dev' from GitLab

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "${SCRIPTS_DIR}/gitlab_setup.sh"
bash "${SCRIPTS_DIR}/gitlab_repo.sh"
bash "${SCRIPTS_DIR}/argocd_setup.sh"

GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

echo "=========================================="
echo "✅ Bonus Setup Complete!"
echo ""
echo "GitLab     : http://gitlab.local"
echo "  user     : root"
echo "  password : ${GITLAB_PASSWORD}"
echo ""
echo "Argo CD UI : https://localhost:8080"
echo "  user     : admin"
echo "  password : ${ARGOCD_PASSWORD}"
echo ""
echo "App        : curl http://localhost:8888/"
echo ""
echo "Update v1 -> v2 through GitLab:"
echo "  git clone http://gitlab.local/root/cmaami-iot.git && cd cmaami-iot"
echo "  sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' manifests/deployment.yaml"
echo "  git commit -am v2 && git push      # user: root, password above"
echo "  curl http://localhost:8888/        # after Argo CD sync"
echo "=========================================="
