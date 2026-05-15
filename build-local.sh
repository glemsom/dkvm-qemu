#!/bin/bash
# Local build script that replicates .github/workflows/build.yml
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
IMAGE_NAME="qemu-apk-builder"
REPO_DIR="repo/x86_64"
KEYS_DIR="keys"
PRIVATE_KEY="$KEYS_DIR/signkey.rsa"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for signing key
check_signing_key() {
    if [ ! -f "$PRIVATE_KEY" ]; then
        log_error "Signing private key not found at $PRIVATE_KEY"
        log_info "You can generate a test key with: openssl genrsa -out $PRIVATE_KEY 2048"
        exit 1
    fi
    log_info "Found signing key: $PRIVATE_KEY"
}

# Build Docker image
build_image() {
    log_info "Building Docker image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" .
    log_info "Docker image built successfully"
}

# Build APK packages
build_apk() {
    log_info "Building APK packages..."
    
    # Create output directory
    mkdir -p "$REPO_DIR"
    
    # Get absolute paths for volume mounts
    REPO_ABS=$(readlink -f "$REPO_DIR")
    KEYS_ABS=$(readlink -f "$KEYS_DIR")
    WORKSPACE_ABS=$(readlink -f ".")
    
    # Read the private key for passing to container
    SIGNING_PRIVATE_KEY=$(cat "$PRIVATE_KEY")
    
    docker run --rm \
        -v "$WORKSPACE_ABS":/home/builder/qemu \
        -v "$REPO_ABS":/out \
        -v "$KEYS_ABS/signkey.rsa.pub":/etc/apk/keys/signkey.rsa.pub:ro \
        -e SIGNING_PRIVATE_KEY="$SIGNING_PRIVATE_KEY" \
        --user root \
        "$IMAGE_NAME" sh -c "
            set -e
            mkdir -p /out /home/builder/.abuild && \
            echo \"\$SIGNING_PRIVATE_KEY\" > /home/builder/.abuild/signkey.rsa && \
            chmod 600 /home/builder/.abuild/signkey.rsa && \
            cp /home/builder/qemu/keys/signkey.rsa.pub /home/builder/.abuild/signkey.rsa.pub && \
            echo \"PACKAGER_PRIVKEY=/home/builder/.abuild/signkey.rsa\" > /home/builder/.abuild/abuild.conf && \
            chown -R builder:abuild /home/builder/qemu /home/builder/.abuild && \
            HOME=/home/builder sudo -u builder sh -c 'cd /home/builder/qemu && abuild -r' && \
            find /home/builder/packages -name '*.apk' -exec cp {} /out/ \;
        "
    
    log_info "APK packages built:"
    ls -la "$REPO_DIR"/*.apk 2>/dev/null || log_warn "No APK files found in $REPO_DIR"
}

# Create signed repository
create_repo() {
    log_info "Creating signed repository..."
    
    if [ -f "./create-repo.sh" ]; then
        ./create-repo.sh "$REPO_DIR"
    else
        log_error "create-repo.sh not found"
        exit 1
    fi
}

# Main build function
main() {
    log_info "Starting local build process..."
    log_info "Workspace: $SCRIPT_DIR"
    
    check_signing_key
    build_image
    build_apk
    create_repo
    
    log_info "Build complete! Repository available at: $REPO_DIR"
}

# Handle command line arguments
case "${1:-all}" in
    image)
        build_image
        ;;
    apk)
        check_signing_key
        build_image
        build_apk
        ;;
    repo)
        create_repo
        ;;
    all|*)
        main
        ;;
esac