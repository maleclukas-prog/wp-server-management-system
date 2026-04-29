#!/bin/bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-wsms-smoke-test}"

docker build -t "$IMAGE_NAME" -f tests/docker/Dockerfile .
docker run --rm "$IMAGE_NAME"