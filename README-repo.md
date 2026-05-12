# QEMU Alpine Package Repository

This directory contains a signed Alpine Linux repository for QEMU packages.

## Contents

- `x86_64/qemu-10.1.5-r0.apk` - Main QEMU package
- `x86_64/qemu-system-x86_64-10.1.5-r0.apk` - QEMU system emulator for x86_64
- `x86_64/APKINDEX.tar.gz` - Signed repository index

## Signing Key

The public key for verifying packages is at:
```
keys/qemu-builder.rsa.pub
```

## Usage

### 1. Import the signing key

```bash
sudo cp keys/qemu-builder.rsa.pub /etc/apk/keys/
```

### 2. Add the repository

```bash
# For local/testing usage:
echo "file:///path/to/repo/x86_64" >> /etc/apk/repositories

# Or for web hosting:
echo "https://your-domain.com/repo/x86_64" >> /etc/apk/repositories
```

### 3. Install QEMU

```bash
apk update
apk add qemu qemu-system-x86_64
```

## Publishing

To host this repository:

1. Upload the `repo/` directory to a web server
2. Ensure the URL path matches the repository structure
3. Users can then add the repository URL to their `/etc/apk/repositories`

## Regenerating the Repository

```bash
# After adding/updating APK files
./create-repo.sh
```

## Notes

- The packages were built with Alpine's standard build system
- The repository index is signed with our custom key
- Dependencies are resolved against Alpine's main repositories