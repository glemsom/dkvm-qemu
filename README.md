# DKVM QEMU — Asymmetric Cache Topology & AMD EPYC Patches

> **Documentation:** See [docs/index.md](docs/index.md) for a full doc map.
> **Alpine repo:** See [README-repo.md](README-repo.md) for package installation.
> **Contributing:** See [CONTRIBUTING.md](CONTRIBUTING.md).
> **Tutorial:** [Getting Started](docs/tutorial/getting-started.md).

Custom QEMU (11.0.1) build with patches for AMD EPYC/Ryzen virtualization
— die-topology CPUID, bus-lock detection, and **per-die asymmetric L3 cache**
support (simulate Ryzen 9950X3D in VMs).

## Quick Start (build from source)

```bash
git clone https://github.com/glemsom/dkvm-qemu.git
cd dkvm-qemu
./dev-build.sh
./dev-test.sh build/out/qemu-system-x86_64
```

Or [install via APK](docs/tutorial/install-via-apk.md) (Alpine Linux).

## Quick Reference

- **[How-to: QEMU Flags](docs/howto/qemu-flags.md)** — Build, CPU properties, per-die L3, validation
- **[How-to: Testing](docs/howto/testing.md)** — Test suite and verification
- **[Reference: Patches](docs/reference/patches.md)** — Patch list, files, purpose
- **[Reference: CPU Properties](docs/reference/cpu-properties.md)** — All CPU property reference
- **[Explanation: Architecture](docs/explanation/architecture.md)** — Per-die L3 design and data flow
- **[Explanation: AMD Die Topology](docs/explanation/amd-die-topology.md)** — AMD die/CCD topology background
- **[Explanation: CPUID Cache Encoding](docs/explanation/cpuid-cache-encoding.md)** — CPUID leaf encoding details

## Context

See [docs/reference/glossary.md](docs/reference/glossary.md) for domain glossary.
See [docs/adr/0001-per-die-asymmetric-l3-cache.md](docs/adr/0001-per-die-asymmetric-l3-cache.md) for the architecture decision record.
