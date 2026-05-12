#!/bin/bash

set -euo pipefail

KEEP_CONTAINER="${WSMS_DOCKER_KEEP_CONTAINER:-0}"
DEBUG_CONTAINER_NAME="${WSMS_DOCKER_CONTAINER_NAME:-wsms-notify-smoke-debug}"

cd "$(dirname "$0")/.."

if [ "$KEEP_CONTAINER" = "1" ]; then
  docker rm -f "$DEBUG_CONTAINER_NAME" > /dev/null 2>&1 || true
  docker run --name "$DEBUG_CONTAINER_NAME" \
    -v "$(pwd):/workspace" \
    -e WORKSPACE_DIR=/workspace \
    ubuntu:22.04 bash /workspace/tests/docker/run-notify-smoke.sh
else
  docker run --rm \
    -v "$(pwd):/workspace" \
    -e WORKSPACE_DIR=/workspace \
    ubuntu:22.04 bash /workspace/tests/docker/run-notify-smoke.sh
fi
