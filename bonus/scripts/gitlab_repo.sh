#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Creates the public project root/cmaami-iot in the local GitLab and pushes
# the application manifests (bonus/confs/app) into its 'manifests' folder

GITLAB_URL="http://gitlab.local"
PROJECT="cmaami-iot"
REPO_URL="${GITLAB_URL}/root/${PROJECT}.git"
APP_DIR="$(cd "$(dirname "$0")/../confs/app" && pwd)"

ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d)
AUTH_HEADER="Authorization: Basic $(printf 'root:%s' "${ROOT_PASSWORD}" | base64 | tr -d '\n')"

echo "=== GitLab project root/${PROJECT} ==="
if git -c http.extraHeader="${AUTH_HEADER}" ls-remote "${REPO_URL}" >/dev/null 2>&1; then
  echo "Repository already exists, skipping the initial push."
else
  WORK_DIR=$(mktemp -d)
  mkdir "${WORK_DIR}/manifests"
  cp "${APP_DIR}"/*.yaml "${WORK_DIR}/manifests/"

  git -C "${WORK_DIR}" init -q -b main
  git -C "${WORK_DIR}" add .
  git -C "${WORK_DIR}" -c user.name="root" -c user.email="root@gitlab.local" commit -q -m "v1"
  # GitLab creates the project on the first push ("push to create")
  git -C "${WORK_DIR}" -c http.extraHeader="${AUTH_HEADER}" push -q "${REPO_URL}" main
  rm -rf "${WORK_DIR}"
fi

echo "=== Make the project public (so Argo CD can read it without credentials) ==="
kubectl exec -n gitlab deploy/gitlab-toolbox -- gitlab-rails runner \
  "Project.find_by_full_path('root/${PROJECT}').update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)"

curl -sf "${GITLAB_URL}/api/v4/projects/root%2F${PROJECT}" > /dev/null
echo "Project is public: ${GITLAB_URL}/root/${PROJECT}"
