#!/bin/bash
# Generate a test signing key for local builds
# For production, use a properly secured key

set -e

KEYS_DIR="keys"
PRIVATE_KEY="$KEYS_DIR/signkey.rsa"
PUBLIC_KEY="$KEYS_DIR/signkey.rsa.pub"

mkdir -p "$KEYS_DIR"

echo "Generating 4096-bit RSA key for APK signing..."
openssl genrsa -out "$PRIVATE_KEY" 4096
chmod 600 "$PRIVATE_KEY"

# Extract public key
ssh-keygen -y -f "$PRIVATE_KEY" > "$PUBLIC_KEY" 2>/dev/null || \
    openssl rsa -in "$PRIVATE_KEY" -pubout > "$PUBLIC_KEY"

chmod 644 "$PUBLIC_KEY"

echo "Generated:"
echo "  Private key: $PRIVATE_KEY"
echo "  Public key:  $PUBLIC_KEY"
echo ""
echo "WARNING: This is a TEST key for local development only!"
echo "For production releases, use a properly secured key."