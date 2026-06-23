# DKVM QEMU Documentation

Documentation organized by the [Diátaxis](https://diataxis.fr/) framework.

## Quadrant Map

| Quadrant | Document | Audience | Goal |
|----------|----------|----------|------|
| **Tutorial** | [Getting Started](tutorial/getting-started.md) | New users | First successful build & VM boot |
| **How-to** | [QEMU Flags](howto/qemu-flags.md) | QEMU users | Build, CPU properties, per-die L3, validation |
| **How-to** | [Debug Per-Die L3](howto/debug-per-die-l3.md) | QEMU users | Troubleshoot asymmetric L3 configuration |
| **How-to** | [Testing](howto/testing.md) | Users & contributors | Run and write tests |
| **How-to** | [Adding the APK Repo](../README-repo.md#adding-the-repository) | Alpine sysadmins | Install custom QEMU packages |
| **How-to** | [Contributing](../CONTRIBUTING.md) | Developers | Submit patches, run tests |
| **How-to** | [Local APK Build](../build-local.sh) | Packagers | Build signed APK packages locally |
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
- [Testing](howto/testing.md) — Run and write tests
- [Debug Per-Die L3](howto/debug-per-die-l3.md) — Troubleshooting guide
- [CPU Properties](reference/cpu-properties.md) — Custom CPU property reference
- [Patches Overview](reference/patches.md) — Patch list, files, purpose
- [Patch Dependencies](reference/patch-dependencies.md) — Dependency chain & interactions
- [Architecture](explanation/architecture.md) — Per-die L3 design & data flow
- [AMD Die Topology](explanation/amd-die-topology.md) — AMD chiplet arch and 3D V-Cache
- [CPUID Cache Encoding](explanation/cpuid-cache-encoding.md) — CPUID leaf encoding details
- [README-repo.md](../README-repo.md) — Alpine package repository docs
- [Glossary](reference/glossary.md) — Domain terminology
- [ADR-0001](adr/0001-per-die-asymmetric-l3-cache.md) — Design decisions and trade-offs

## Project Map

```
dkvm-qemu/
├── README.md              # Main project landing page
├── README-repo.md         # Alpine repo docs — install, CI/CD
├── CONTEXT.md             # Redirect → glossary.md and ADR-0001
├── CONTRIBUTING.md        # How to contribute
├── docs/
│   ├── index.md           # This page
│   ├── tutorial/
│   │   └── getting-started.md
│   ├── howto/
│   │   ├── qemu-flags.md           # Build & -cpu flags usage
│   │   ├── debug-per-die-l3.md     # Troubleshoot asymmetric L3
│   │   └── testing.md              # Run and write tests
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
