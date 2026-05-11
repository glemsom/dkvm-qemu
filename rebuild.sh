#!/bin/bash
# Cleanup any old volume and build the Docker image, then run the build script inside the container

docker volume rm qemu-packages 2>/dev/null || true
docker build -t qemu-apk-builder . && docker run --rm -v $(pwd):/workspace:ro -v qemu-packages:/home/builder/packages     qemu-apk-builder bash -c "cd /workspace && ./build-in-docker.sh"