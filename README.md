# DKVM QEMU — Asymmetric Cache Topology & AMD EPYC Patches

Custom QEMU (11.0.1) build with patches for AMD EPYC/Ryzen virtualization — die-topology CPUID, bus-lock detect, and per-die asymmetric L3 cache support (9950X3D simulation).

## Patches Overview

All patches are in `patches/`. Applied in sorted order during build.

| Patch | File | Purpose |
|-------|------|---------|
| `0001-CPUID.patch` | `target/i386/cpu.c`, `kvm/kvm.c` | **CPUID[0x80000026] — Extended CPU Topology leaf**. Encodes die/module topology for AMD CPUs so that the guest OS can discover die boundaries and properly interpret per-die cache information. |
| `0002-x-force-cpuid.patch` | `target/i386/cpu.c`, `cpu.h` | **`x-force-cpuid-0x80000026` property** + Zen4+ auto-detect. Allows forcing CPUID[0x80000026] on any AMD model via CPU property. Automatically enables for Zen4 and above (family 0x19, model 0x10-0x1f / 0x60-0xaf). |
| `0003-epyc-vcpu.patch` | `target/i386/cpu.c` | **EPYC-Turin v3** — adds version 3 of EPYC-Turin model that defaults `x-force-cpuid-0x80000026=on`. |
| `0004-bus-lock-detect.patch` | `target/i386/cpu.h`, `kvm/kvm.c` | **Bus Lock Debug exception** — adds `DR6_BLD` flag and KVM handling for bus-lock detection (required for newer KVM features). |
| `0005-bus-lock-detect-epyc.patch` | `target/i386/cpu.c` | **EPYC-Turin v2 bus-lock-detect** — enables `bus-lock-detect` on EPYC-Turin version 2. |
| `0006-per-die-l3-cache.patch` | `target/i386/cpu.h`, `cpu.c` | **Per-die L3 cache foundation**. Adds CPU properties `l3-cache-size-die<N>` and `l3-cache-assoc-die<N>` (N=0..7). Stores overrides in `CPUX86State.l3_cache_per_die[]`. Initializes at realize by cloning model's L3 `CPUCacheInfo`, overriding size/associativity, recalculating sets. Validation: per-die + `l3-cache=off` → error; die index ≥ topology die count → warn. Frees in finalize. |
| `0007-per-die-l3-cpuid-encode.patch` | `target/i386/cpu.c` | **Per-die L3 CPUID encode**. Modifies all 3 L3 CPUID encode sites (CPUID[4] leaf 3, 0x80000006.EDX, 0x8000001D leaf 3) to extract `die_id` from vCPU's APIC ID and select the per-die `CPUCacheInfo` from `l3_cache_per_die[die_id]`, falling back to model default if NULL. |
| `0008-per-die-l3-passthrough.patch` | `target/i386/cpu.c` | **Per-die L3 passthrough mode support**. When `host-cache-info=on` (`-cpu host`), checks for per-die L3 overrides before falling back to `x86_cpu_get_cache_cpuid()`. Dies with an override use `encode_cache_cpuid*()`; dies without use native host passthrough. |

## Usage

### Build

```sh
# Docker dev build (applies all patches, outputs qemu-system-x86_64)
./dev-build.sh

# Or use the Alpine APKBUILD directly:
abuild checksum   # update checksums
abuild -r         # build
```

### QEMU Flags

All features are configured via CPU properties on the `-cpu` flag.

#### Enable die topology (required for per-die L3)

```sh
# Auto-detect for Zen4+ models; or force with:
-cpu EPYC-Turin,x-force-cpuid-0x80000026=on
```

#### Per-die asymmetric L3 cache (model mode)

```sh
# EPYC-Turin, 2 dies, die0=32MB (33554432), die1=96MB (100663296)
-cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1

# With associativity override for 3D V-Cache
-cpu EPYC-Turin,l3-cache-size-die1=100663296,l3-cache-assoc-die1=12 \
  -smp 16,dies=2,cores=8,threads=1
```

#### Per-die asymmetric L3 cache (host passthrough mode)

```sh
# Host passthrough, override die1 L3 to 96MB (100663296) (9950X3D simulation)
-cpu host,l3-cache-size-die1=100663296 \

# Passthrough without per-die props → pure host passthrough, no change
-cpu host
```

#### Validation examples

```sh
# Error: per-die property requires l3-cache=on
-cpu EPYC-Turin,l3-cache=off,l3-cache-size-die0=33554432
# Warning: die index 3 exceeds 2-die topology (ignored)
-cpu EPYC-Turin,l3-cache-size-die3=100663296 -smp 8,dies=2,cores=4
```

### Test

```sh
# Run automated test suite (QMP + KVM tests)
./dev-test.sh [path/to/qemu-system-x86_64]

# Or specify the dev build output
./dev-test.sh build/out/qemu-system-x86_64
```

The test suite verifies:
- QMP `query-cpu-model-expansion` with per-die properties
- Error handling (l3-cache=off + per-die prop)
- Multi-die SMP boot with per-die L3 (model and passthrough mode)
- Regression: no per-die properties → uniform L3
- KVM passthrough boot (if /dev/kvm available)

## Architecture

```
                    ┌───────────────────────┐
                    │   CPU Properties      │
                    │ l3-cache-size-die<N>  │
                    │ l3-cache-assoc-die<N> │
                    └──────────┬───────────┘
                               │ realize-time
                               ▼
                    ┌───────────────────────┐
                    │  CPUX86State          │
                    │  l3_cache_per_die[8]  │
                    │  [0] → CPUCacheInfo*  │
                    │  [1] → CPUCacheInfo*  │
                    │  ...                  │
                    │  NULL = model default │
                    └──────────┬────────────┘
                               │ CPUID encode time
                               ▼
                    ┌──────────────────────┐
                    │  CPUID Encode Sites  │
                    │  ├─ CPUID[4] leaf 3  │
                    │  ├─ 0x80000006.EDX   │
                    │  └─ 0x8000001D leaf 3│
                    └──────────────────────┘
```

Per-die L3 overrides are stored separately from the model's uniform `cache_info`. At CPUID encode, the vCPU's die ID is extracted from its APIC ID (`x86_topo_ids_from_apicid`) to select the correct L3 info. This design minimizes blast radius — only 3 CPUID encode sites need modification.

## Context

See [CONTEXT.md](CONTEXT.md) for domain glossary and design decisions.
See [docs/adr/0001-per-die-asymmetric-l3-cache.md](docs/adr/0001-per-die-asymmetric-l3-cache.md) for the architecture decision record.
