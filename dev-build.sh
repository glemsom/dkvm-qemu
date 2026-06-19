#!/bin/bash
# Dev build script — builds QEMU with patches in Docker, outputs qemu-system-x86_64
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="qemu-dev-builder"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Build dev Docker image
log_info "Building dev Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" -f Dockerfile.dev .

# Create output directory
mkdir -p build/out

# Run build (no signing key needed)
log_info "Building QEMU (x86_64-softmmu)…"
docker run --rm \
    -v "$(readlink -f patches):/build/patches:ro" \
    -v "$(readlink -f build/out):/build/out" \
    "$IMAGE_NAME" \
    sh -c "
        set -e
        cd /build/qemu
        ./configure --target-list=x86_64-softmmu --enable-kvm --disable-werror \
            --disable-debug-info --disable-bsd-user --disable-linux-user \
            --python=/usr/bin/python3 --disable-docs --cc=gcc
        make -j\$(nproc)
        cp build/qemu-system-x86_64 /build/out/
    "

log_info "Build complete! Binary at: build/out/qemu-system-x86_64"
ls -la build/out/qemu-system-x86_64 2>/dev/null || log_error "Binary not found"
