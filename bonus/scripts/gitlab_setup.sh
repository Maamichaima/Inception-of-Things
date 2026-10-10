set -e

CLUSTER_NAME="iot-cluster"
DOMAIN="local.gitlab"
PORT="8888"

echo "=== Stage 0: Install environment requirements (Docker, kubectl, k3d, Helm) ==="
command -v docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER" || true

command -v kubectl >/dev/null 2>&1 || {
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
}

command -v k3d >/dev/null 2>&1 || curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

command -v helm >/dev/null 2>&1 || curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

command -v git >/dev/null 2>&1 || sudo apt-get update && sudo apt-get install -y git

echo "Installed versions:"
docker --version
kubectl version --client
k3d version
helm version
git --version


# ================================================= installation ====================================================

echo "===  K3d cluster creation ==="
k3d cluster create ${CLUSTER_NAME} \
  --agents 1 \
  --servers 1 \
  --port "${PORT}:80@loadbalancer" \

echo "=== Namespace ==="
kubectl create namespace gitlab

helm repo add gitlab https://charts.gitlab.io/
helm repo update

echo "=== install GitLab ==="
helm install gitlab gitlab/gitlab \
--version 9.11.8 \
--namespace gitlab --create-namespace \
--timeout 600s \
-f "$(dirname "$0")/../confs/gitlab_values.yaml"

# echo "=== install GitLab ingress ==="
# kubectl apply -f "$(dirname "$0")/../confs/gitlab_ingress.yaml"

echo "=== Wait for GitLab pods to be ready ==="
kubectl wait --for=condition=Ready pods --all -n gitlab --timeout=600s

echo "=====GitLab root password:====="
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d
echo