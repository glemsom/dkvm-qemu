# DKVM QEMU Package

Custom QEMU build for [DKVM](https://github.com/dkvm) - an Alpine-based distribution optimized for virtualization.

## Features

- x86_64-optimized build
- Minimal subpackage set for DKVM use case
- Latest stable QEMU versions
- GitHub Actions CI/CD for reproducible builds

## Installation

1. Add the DKVM repository to your Alpine system:

   ```bash
   echo "https://github.com/dkvm/dkvm-qemu/releases/download/v11.0.0/" >> /etc/apk/repositories
   apk add --no-scripts qemu
   ```

2. Install QEMU:

   ```bash
   apk update
   apk add qemu
   ```

## Building Locally

```sh
# Install abuild tools
apk add alpine-sdk

# Build the package
abuild -r  # or -b -c -p separately
```

The built package will be in `~/packages/`.

## Versioning

Tags follow the pattern `v{VERSION}-dkvm{RELEASE}` (e.g., `v11.0.0-dkvm1`)

## Subpackages

| Package | Description |
|---------|-------------|
| `qemu` | Main QEMU virtualizer |
| `qemu-img` | Disk image utility |
| `qemu-dev` | Development files |
| `qemu-doc` | Documentation |
| `qemu-tools` | QEMU tools (qemu-ga, qemu-pr-helper, etc.) |
| `qemu-ui-*` | UI components (gtk, spice, curses, etc.) |
| `qemu-audio-*` | Audio drivers (alsa, oss, pa, sdl) |
| `qemu-block-*` | Block drivers (curl, dmg, nfs, ssh) |
| `qemu-hw-display-*` | Display devices (virtio-gpu variants) |

## License

GPL-2.0-only AND LGPL-2.1-only (same as upstream QEMU)

## Development

### Release Process

1. Update `pkgver` and `pkgrel` in APKBUILD
2. Commit and push
3. Create and push a tag: `git tag v11.0.0-dkvm1 && git push origin v11.0.0-dkvm1`
4. GitHub Actions builds and creates release
5. Release page contains `.apk` file

### Verification

After building, verify:
- [ ] APKBUILD builds locally with `abuild -r`
- [ ] `.apk` file is generated in `~/packages/`
- [ ] Package installs correctly (`apk add qemu`)
- [ ] `qemu-system-x86_64 --version` shows expected version