#!/bin/bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-wsms-smoke-test}"
KEEP_CONTAINER="${WSMS_DOCKER_KEEP_CONTAINER:-0}"
DEBUG_CONTAINER_NAME="${WSMS_DOCKER_CONTAINER_NAME:-wsms-all-modules-smoke-debug}"

cd "$(dirname "$0")/.."

docker build -t "$IMAGE_NAME" -f tests/docker/Dockerfile .

if [ "$KEEP_CONTAINER" = "1" ]; then
  docker rm -f "$DEBUG_CONTAINER_NAME" > /dev/null 2>&1 || true
  docker run --name "$DEBUG_CONTAINER_NAME" "$IMAGE_NAME" bash /workspace/tests/docker/run-all-modules-smoke.sh
else
  docker run --rm "$IMAGE_NAME" bash /workspace/tests/docker/run-all-modules-smoke.sh
fi
