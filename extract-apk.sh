#!/bin/sh
# Copy built APK files from the Docker volume to the current directory

VOLUME="${1:-qemu-packages}"

echo "Copying APK from volume '$VOLUME' to $(pwd)..."
# Find all APK files in the volume
APK_LIST=$(docker run --rm -v "$VOLUME":/packages alpine:edge sh -c "
    find /packages -name '*.apk' -type f 2>/dev/null
" 2>/dev/null)

if [ -z "$APK_LIST" ]; then
    echo 'No APK files found'
    exit 1
fi

echo "Found $(echo "$APK_LIST" | wc -l | tr -d ' ') APK file(s):"
echo "$APK_LIST"

docker run --rm -v "$VOLUME":/packages -v "$(pwd):/out" alpine:edge sh -c '
    count=0
    for apk in $(find /packages -name "*.apk" -type f); do
        cp "$apk" /out/ && count=$((count + 1))
    done
    echo "Copied $count APK file(s)"
'