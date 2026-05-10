#!/bin/bash
# Initialize abuild environment and build QEMU package

set -x

# Update repositoruies and install build dependencies
sudo apk update || true

# Ensure packages directory is writable
sudo mkdir -p /home/builder/packages/x86_64
sudo chown -R $(whoami):abuild /home/builder/packages

# Generate signing keys and install the public key
cd /home/builder
abuild-keygen -a -n 2>/dev/null || true

# Install public key so the repo index is trusted
PUB_KEY=$(ls /home/builder/.abuild/*.pub 2>/dev/null | head -1)
if [ -n "$PUB_KEY" ]; then
    sudo cp "$PUB_KEY" /etc/apk/keys/
fi

# Copy workspace contents (APKBUILD, patches, etc.) to writable builder home
mkdir -p /home/builder/qemu
cp -r /workspace/APKBUILD /workspace/qemu.* /home/builder/qemu/
cp -r /workspace/patches /home/builder/qemu/
chown -R builder:abuild /home/builder/qemu
cd /home/builder/qemu

# Build the package
abuild -r 2>&1

echo ""
echo "=== Build complete ==="
APK_FILE=$(find /home/builder/packages -name "*.apk" -type f 2>/dev/null | head -1)
if [ -n "$APK_FILE" ]; then
    echo "APK: $APK_FILE ($(du -h "$APK_FILE" | cut -f1))"
    echo ""
    echo "To copy to workspace: cp $APK_FILE /workspace/"
else
    echo "No APK found. Check ~/packages/"
fi