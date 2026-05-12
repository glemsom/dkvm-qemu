# QEMU Alpine Package Repository

This repository contains a custom Alpine Linux package build system for QEMU with additional patches and optimizations for x86_64 virtualization.

## Overview

- **QEMU Version**: 10.1.5
- **Target**: Alpine Linux (x86_64)
- **Purpose**: Custom QEMU builds with enhanced CPUID support, EPYC vCPU optimizations, and bus lock detection patches

## Repository Structure

```
.
├── APKBUILD                    # Alpine package build definition
├── patches/                    # Custom QEMU patches
│   ├── 0001-CPUID.patch        # Extended CPU Topology (Fn80000026)
│   ├── 0002-x-force-cpuid.patch
│   ├── 0003-epyc-vcpu.patch    # EPYC vCPU optimizations
│   ├── 0004-bus-lock-detect.patch
│   ├── 0005-bus-lock-detect-epyc.patch
│   └── ...                     # Additional patches
├── repo/                       # Built packages and signed repository
├── keys/                       # Signing keys for repository
├── build-in-docker.sh          # Build script (Docker-based)
├── create-repo.sh              # Repository index creation and signing
├── generate-key.sh             # Generate repository signing keys
├── Dockerfile                  # Build environment container
└── rebuild.sh                  # Full rebuild script
```

## Features

### Custom Patches

- **Extended CPU Topology (Fn80000026)**: CPUID support for extended CPU topology enumeration
- **EPYC vCPU Optimizations**: AMD EPYC-specific virtualization improvements
- **Bus Lock Detection**: Enhanced bus lock detection for virtualization security
- **Musl/liburing Compatibility**: Fixes for Alpine's musl libc and modern liburing

### Build Configuration

The package is built with:
- KVM acceleration enabled
- Seccomp sandboxing
- VirtFS/9p support
- Vhost-net, VDE networking
- TPM support
- Zstd, Snappy, LZO compression

## Contents

- `repo/x86_64/qemu-10.1.5-r0.apk` - Main QEMU package
- `repo/x86_64/qemu-system-x86_64-10.1.5-r0.apk` - QEMU system emulator for x86_64
- `repo/x86_64/APKINDEX.tar.gz` - Signed repository index

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

## Building

### Quick Build

```bash
./rebuild.sh
```

### Manual Build Steps

1. **Generate signing keys** (first time only):
   ```bash
   ./generate-key.sh
   ```

2. **Build packages** (requires Docker):
   ```bash
   ./build-in-docker.sh
   ```

3. **Copy APK files** to `repo/x86_64/`:
   ```bash
   cp *.apk repo/x86_64/
   ```

4. **Create signed repository**:
   ```bash
   ./create-repo.sh
   ```

## Publishing

To host this repository:

1. Upload the `repo/` directory to a web server
2. Ensure the URL path matches the repository structure
3. Users can then add the repository URL to their `/etc/apk/repositories`

## Files Reference

| File | Description |
|------|-------------|
| `APKBUILD` | Alpine package build recipe |
| `create-repo.sh` | Creates signed APKINDEX.tar.gz |
| `generate-key.sh` | Generates RSA signing keys |
| `build-in-docker.sh` | Builds packages in Docker container |
| `Dockerfile` | Alpine-based build environment |
| `rebuild.sh` | Complete rebuild workflow |
| `qemu-guest-agent.initd` | OpenRC init script (template) |
| `qemu-guest-agent.confd` | OpenRC configuration (template) |