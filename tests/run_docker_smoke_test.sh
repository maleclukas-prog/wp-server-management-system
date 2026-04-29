#!/bin/bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-wsms-smoke-test}"
KEEP_CONTAINER="${WSMS_DOCKER_KEEP_CONTAINER:-0}"

docker build -t "$IMAGE_NAME" -f tests/docker/Dockerfile .

if [ "$KEEP_CONTAINER" = "1" ]; then
  docker run "$IMAGE_NAME"
else
  docker run --rm "$IMAGE_NAME"
fi