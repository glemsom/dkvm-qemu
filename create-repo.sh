#!/bin/bash
# Create and sign Alpine repository
set -e

REPO_DIR="${1:-repo/x86_64}"

if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repository directory $REPO_DIR does not exist"
    exit 1
fi

# Find APK files
APKS=$(find "$REPO_DIR" -maxdepth 1 -name "*.apk" -type f 2>/dev/null)
if [ -z "$APKS" ]; then
    echo "Error: No APK files found in $REPO_DIR"
    exit 1
fi

echo "=== Found APK files ==="
echo "$APKS"
echo ""

# Find the private key
PRIVATE_KEY="keys/signkey.rsa"
PUBLIC_KEY="keys/signkey.rsa.pub"

if [ ! -f "$PRIVATE_KEY" ]; then
    echo "Error: No private key found at $PRIVATE_KEY"
    echo "Run ./generate-key.sh first"
    exit 1
fi

echo "=== Using key: $PRIVATE_KEY ==="
echo ""

# Create and sign index using Docker (apk index + abuild-sign)
# Note: These are APKv2 format packages, so we use legacy apk-index + abuild-sign
echo "=== Creating APKINDEX.tar.gz and signing ==="
REPO_ABS_PATH=$(readlink -f "$REPO_DIR")
KEYS_ABS_PATH=$(readlink -f keys)

docker run --rm \
    -v "$REPO_ABS_PATH":/repo \
    -v "$KEYS_ABS_PATH":/keys \
    -e PACKAGER_PRIVKEY="/keys/signkey.rsa" \
    -e SIGNPUBKEY="/keys/signkey.rsa.pub" \
    -w /repo \
    alpine:3.23 sh -c "
        apk add --no-cache alpine-sdk
        # Create index for v2 format packages (ignore untrusted signatures in packages)
        apk --allow-untrusted index *.apk -o APKINDEX.tar.gz
        # Sign the index with our private key
        abuild-sign APKINDEX.tar.gz
    "

echo ""
echo "=== Repository created ==="
ls -la "$REPO_DIR"

echo ""
echo "=== To use this repository, users should ==="
echo "1. Copy $PUBLIC_KEY to /etc/apk/keys/"
echo "2. Add the repository URL to /etc/apk/repositories"
echo "3. Run: apk update && apk add qemu"