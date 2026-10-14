#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="my-app-server"
IMAGE_TAG="${1:-dev}"
CONTAINER_NAME="my-app-server-deploy"
HOST_PORT="${2:-80}"

echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} on port ${HOST_PORT}..."

if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    echo "Error: image ${IMAGE_NAME}:${IMAGE_TAG} was not found locally."
    exit 1
fi

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${HOST_PORT}:80" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

echo "Deployment completed: http://localhost:${HOST_PORT}"