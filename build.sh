#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="my-app-server"
IMAGE_TAG="${1:-dev}"

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
echo "Build completed successfully: ${IMAGE_NAME}:${IMAGE_TAG}"