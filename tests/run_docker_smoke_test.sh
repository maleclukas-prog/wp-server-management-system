#!/bin/bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-wsms-smoke-test}"
KEEP_CONTAINER="${WSMS_DOCKER_KEEP_CONTAINER:-0}"
DEBUG_CONTAINER_NAME="${WSMS_DOCKER_CONTAINER_NAME:-wsms-smoke-debug}"

docker build -t "$IMAGE_NAME" -f tests/docker/Dockerfile .

if [ "$KEEP_CONTAINER" = "1" ]; then
  docker rm -f "$DEBUG_CONTAINER_NAME" > /dev/null 2>&1 || true
  docker run --name "$DEBUG_CONTAINER_NAME" "$IMAGE_NAME"
else
  docker run --rm "$IMAGE_NAME"
fi