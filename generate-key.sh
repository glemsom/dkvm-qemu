#!/bin/bash
# Setup script for creating signed Alpine repository
set -e

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required but not installed"
    exit 1
fi

# Create directories for keys and repository
mkdir -p keys repo/x86_64

# Run abuild-keygen in a container to generate the signing key
echo "=== Generating signing key ==="
docker run --rm -v "$(pwd)/keys:/home/builder/.abuild" alpine:3.23 sh -c "
    apk add --no-cache alpine-sdk
    cd /home/builder/.abuild
    abuild-keygen -n -i
" || docker run --rm -v "$(pwd)/keys:/root/.abuild" alpine:3.23 sh -c "
    apk add --no-cache alpine-sdk
    cd /root/.abuild
    abuild-keygen -n -i
"

echo ""
echo "=== Key files generated ==="
ls -la keys/

echo ""
echo "=== Next steps ==="
echo "1. Copy the public key (*.rsa.pub) to /etc/apk/keys/ on target systems"
echo "2. Place your .apk files in repo/x86_64/"
echo "3. Run: ./create-repo.sh"