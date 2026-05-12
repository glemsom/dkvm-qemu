# QEMU Alpine Package Repository

This repository automatically builds custom Alpine Linux packages for QEMU with additional patches and optimizations for x86_64 virtualization.

## Overview

- **Purpose**: Custom QEMU builds with enhanced CPUID support, EPYC vCPU optimizations, and bus lock detection patches
- **Build System**: Automated via GitHub Actions
- **Signing**: Packages are signed with a private key stored in GitHub Secrets

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
├── keys/                       # Signing keys for repository
│   └── qemu-builder.rsa.pub    # Public key for package verification
├── Dockerfile                  # Build environment container
├── create-repo.sh              # Repository index creation and signing
├── qemu.post-install           # Post-install script
├── qemu.pre-install            # Pre-install script
├── qemu.pre-upgrade            # Pre-upgrade script
└── .github/workflows/          # GitHub Actions CI/CD
    └── build.yml               # Build and publish workflow
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

## Usage

### 1. Import the signing key

```bash
sudo cp keys/qemu-builder.rsa.pub /etc/apk/keys/
```

### 2. Add the repository

The repository is published via GitHub Pages at:
```
https://raw.githubusercontent.com/<owner>/<repo>/main/repo/x86_64
```

Or for local usage:
```bash
echo "file:///path/to/repo/x86_64" >> /etc/apk/repositories
```

### 3. Install QEMU

```bash
apk update
apk add qemu qemu-system-x86_64
```

## CI/CD

This repository uses GitHub Actions to automatically build and publish packages:

- **Triggers**: Push to main branch (when Dockerfile, APKBUILD, or patches change) or manual dispatch
- **Build**: Packages are built in a Docker container with Alpine 3.23
- **Sign**: Packages are signed using the private key stored in `SIGNING_PRIVATE_KEY` secret
- **Publish**: The signed repository is published to GitHub Pages

### Required Secrets

- `SIGNING_PRIVATE_KEY`: RSA private key matching `keys/qemu-builder.rsa.pub`

## Files Reference

| File | Description |
|------|-------------|
| `APKBUILD` | Alpine package build recipe |
| `create-repo.sh` | Creates signed APKINDEX.tar.gz |
| `Dockerfile` | Alpine-based build environment |
| `.github/workflows/build.yml` | GitHub Actions CI/CD pipeline |
| `patches/*.patch` | QEMU source patches |
| `keys/qemu-builder.rsa.pub` | Public key for package verification |