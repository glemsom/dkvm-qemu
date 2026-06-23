# DKVM QEMU Documentation

Documentation organized by the [Diátaxis](https://diataxis.fr/) framework.

## Quadrant Map

| Quadrant | Document | Audience | Goal |
|----------|----------|----------|------|
| **Tutorial** | [Getting Started](tutorial/getting-started.md) | Developers | First successful build & VM boot |
| **Tutorial** | [Install via APK](tutorial/install-via-apk.md) | Alpine users | Install pre-built DKVM QEMU |
| **How-to** | [QEMU Flags](howto/qemu-flags.md) | QEMU users | Build, CPU properties, per-die L3, validation |
| **How-to** | [Simulate 9950X3D](howto/simulate-9950x3d.md) | QEMU users | Step-by-step 9950X3D VM configuration |
| **How-to** | [Debug Per-Die L3](howto/debug-per-die-l3.md) | QEMU users | Troubleshoot asymmetric L3 configuration |
| **How-to** | [libvirt Integration](howto/libvirt-integration.md) | QEMU users | Use per-die L3 cache with libvirt |
| **How-to** | [Testing](howto/testing.md) | Users & contributors | Run and write tests |
| **How-to** | [Adding the APK Repo](../README-repo.md#adding-the-repository) | Alpine sysadmins | Install custom QEMU packages |
| **How-to** | [Contributing](../CONTRIBUTING.md) | Developers | Submit patches, run tests |
| **How-to** | [Local APK Build](howto/build-apk-locally.md) | Packagers | Build signed APK packages locally |
| **Reference** | [CPU Properties](reference/cpu-properties.md) | QEMU users | Custom CPU property reference |
| **Reference** | [Patches Overview](reference/patches.md) | Developers | Patch list, files, purpose |
| **Reference** | [Patch Dependencies](reference/patch-dependencies.md) | Developers | Dependency chain & interactions |
| **Reference** | [Files Reference](../README-repo.md#files-reference) | Maintainers | Project file inventory |
| **Reference** | [Domain Glossary](reference/glossary.md) | All | Domain terminology |
| **Explanation** | [Architecture](explanation/architecture.md) | Developers | Per-die L3 design & data flow |
| **Explanation** | [AMD Die Topology](explanation/amd-die-topology.md) | All | AMD chiplet arch, 3D V-Cache background |
| **Explanation** | [CPUID Cache Encoding](explanation/cpuid-cache-encoding.md) | Developers | CPUID leaf encoding for cache topology |
| **Explanation** | [ADR-0001](adr/0001-per-die-asymmetric-l3-cache.md) | Architects | Decision record & trade-offs |

## Quick Links

- [README.md](../README.md) — Main project overview and quick reference
- [QEMU Flags](howto/qemu-flags.md) — Build and `-cpu` flags usage
- [Simulate 9950X3D](howto/simulate-9950x3d.md) — Step-by-step 9950X3D VM configuration
- [Testing](howto/testing.md) — Run and write tests
- [Debug Per-Die L3](howto/debug-per-die-l3.md) — Troubleshooting guide
- [libvirt Integration](howto/libvirt-integration.md) — Use per-die L3 with libvirt
- [CPU Properties](reference/cpu-properties.md) — Custom CPU property reference
- [Patches Overview](reference/patches.md) — Patch list, files, purpose
- [Patch Dependencies](reference/patch-dependencies.md) — Dependency chain & interactions
- [Architecture](explanation/architecture.md) — Per-die L3 design & data flow
- [AMD Die Topology](explanation/amd-die-topology.md) — AMD chiplet arch and 3D V-Cache
- [CPUID Cache Encoding](explanation/cpuid-cache-encoding.md) — CPUID leaf encoding details
- [Build APK Locally](howto/build-apk-locally.md) — Build signed APK packages locally
- [README-repo.md](../README-repo.md) — Alpine package repository docs
- [Glossary](reference/glossary.md) — Domain terminology
- [ADR-0001](adr/0001-per-die-asymmetric-l3-cache.md) — Design decisions and trade-offs

## Project Map

```
dkvm-qemu/
├── README.md              # Main project landing page
├── README-repo.md         # Alpine repo docs — install, CI/CD
├── CONTRIBUTING.md        # How to contribute
├── docs/
│   ├── index.md           # This page
│   ├── tutorial/
│   │   ├── getting-started.md
│   │   └── install-via-apk.md
│   ├── howto/
│   │   ├── qemu-flags.md           # Build & -cpu flags usage
│   │   ├── simulate-9950x3d.md     # 9950X3D VM configuration
│   │   ├── debug-per-die-l3.md     # Troubleshoot asymmetric L3
│   │   ├── libvirt-integration.md  # libvirt per-die L3 usage
│   │   ├── testing.md              # Run and write tests
│   │   └── build-apk-locally.md     # Build signed APK locally
│   ├── explanation/
│   │   ├── architecture.md         # Per-die L3 design & data flow
│   │   ├── amd-die-topology.md     # AMD chiplet arch, 3D V-Cache
│   │   └── cpuid-cache-encoding.md # CPUID leaf encoding details
│   ├── reference/
│   │   ├── cpu-properties.md       # Custom CPU property reference
│   │   ├── patches.md              # Patch list, files, purpose
│   │   ├── patch-dependencies.md   # Dependency chain & interactions
│   │   └── glossary.md             # Domain terminology
│   └── adr/
│       └── 0001-per-die-asymmetric-l3-cache.md
├── APKBUILD               # Alpine build recipe
├── Dockerfile              # Production build image
├── Dockerfile.dev          # Dev build image
├── build-local.sh          # Local APK build script
├── dev-build.sh            # Dev QEMU build script
├── dev-test.sh             # Test suite runner
├── create-repo.sh          # Sign & publish APK repo
├── generate-key.sh         # Generate test signing key
└── patches/                # QEMU source patches
```
