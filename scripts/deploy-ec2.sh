#!/usr/bin/env bash

set -euo pipefail

DEPLOY_PATH="${DEPLOY_PATH:?DEPLOY_PATH must be set}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-develop}"

echo "Deploy path: ${DEPLOY_PATH}"
echo "Deploy branch: ${DEPLOY_BRANCH}"

if [ ! -d "${DEPLOY_PATH}" ]; then
  echo "Deployment directory does not exist: ${DEPLOY_PATH}" >&2
  exit 1
fi

cd "${DEPLOY_PATH}"

if [ ! -d .git ]; then
  echo "The deployment directory is not a git repository: ${DEPLOY_PATH}" >&2
  exit 1
fi

if [ ! -f .env ]; then
  echo "Missing .env file in ${DEPLOY_PATH}. Create it from .env.example before running CD." >&2
  exit 1
fi

echo "Pulling latest changes from ${DEPLOY_BRANCH}..."
git fetch origin --tags
git checkout "${DEPLOY_BRANCH}"

echo "Starting Docker build in background..."
nohup bash -c "
  cd ${DEPLOY_PATH}
  docker compose up -d --build --remove-orphans
  docker image prune -f
  echo '=== Deploy finished at '\$(date)' ==='
  docker compose ps
" > /tmp/deploy.log 2>&1 &

DEPLOY_PID=$!
echo "Deploy PID: ${DEPLOY_PID}"

TIMEOUT=600
ELAPSED=0
INTERVAL=10

echo "Suivi des logs (timeout ${TIMEOUT}s)..."
while kill -0 "${DEPLOY_PID}" 2>/dev/null; do
  if [ "${ELAPSED}" -ge "${TIMEOUT}" ]; then
    echo "Timeout atteint — build toujours en cours sur l'EC2."
    echo "Vérifiez avec : tail -f /tmp/deploy.log"
    exit 0
  fi
  tail -n 5 /tmp/deploy.log 2>/dev/null || true
  sleep "${INTERVAL}"
  ELAPSED=$((ELAPSED + INTERVAL))
done

wait "${DEPLOY_PID}"
EXIT_CODE=$?

if [ "${EXIT_CODE}" -ne 0 ]; then
  echo "Deploy échoué (exit code ${EXIT_CODE}) :" >&2
  cat /tmp/deploy.log >&2
  exit "${EXIT_CODE}"
fi

echo "Deploy terminé avec succès !"
docker compose ps
