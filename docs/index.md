# DKVM QEMU Documentation

Documentation organized by the [Diátaxis](https://diataxis.fr/) framework.

## Quadrant Map

| Quadrant | Document | Audience | Goal |
|----------|----------|----------|------|
| **Tutorial** | [Getting Started](tutorial/getting-started.md) | New users | First successful build & VM boot |
| **How-to** | [Usage — QEMU Flags](../README.md#usage) | QEMU users | Configure per-die L3, die topology |
| **How-to** | [Adding the APK Repo](../README-repo.md#adding-the-repository) | Alpine sysadmins | Install custom QEMU packages |
| **How-to** | [Contributing](../CONTRIBUTING.md) | Developers | Submit patches, run tests |
| **How-to** | [Local APK Build](../build-local.sh) | Packagers | Build signed APK packages locally |
| **Reference** | [Patches Overview](../README.md#patches-overview) | Developers | Patch list, files, purpose |
| **Reference** | [Files Reference](../README-repo.md#files-reference) | Maintainers | Project file inventory |
| **Reference** | [Domain Glossary](../CONTEXT.md) | All | Terminology & design decisions |
| **Explanation** | [Architecture](../README.md#architecture) | Developers | Per-die L3 design & data flow |
| **Explanation** | [ADR-0001](adr/0001-per-die-asymmetric-l3-cache.md) | Architects | Decision record & trade-offs |

## Quick Links

- [README.md](../README.md) — Main project overview, patches, QEMU usage
- [README-repo.md](../README-repo.md) — Alpine package repository docs
- [CONTEXT.md](../CONTEXT.md) — Domain terms and design decisions
- [ADR-0001](adr/0001-per-die-asymmetric-l3-cache.md) — Architecture Decision Record

## Project Map

```
dkvm-qemu/
├── README.md              # Main docs — patches, usage, architecture
├── README-repo.md         # Alpine repo docs — install, CI/CD
├── CONTEXT.md             # Domain glossary & design decisions
├── CONTRIBUTING.md        # How to contribute
├── docs/
│   ├── index.md           # This page
│   ├── tutorial/
│   │   └── getting-started.md
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
