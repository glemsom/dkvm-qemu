#!/bin/sh
# Copy built APK files from the Docker volume to the current directory

VOLUME="${1:-qemu-packages}"

echo "Copying APK from volume '$VOLUME' to $(pwd)..."
docker run --rm -v "$VOLUME":/packages alpine:edge sh -c "
    find /packages -name '*.apk' -type f 2>/dev/null | head -20
" 2>/dev/null

docker run --rm -v "$VOLUME":/packages -v "$(pwd):/out" alpine:edge sh -c "
    cp /packages/x86_64/*.apk /out/ 2>/dev/null && echo 'Done!' || echo 'No APK found'
"