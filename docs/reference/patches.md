# Reference: Patches Overview

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

## See Also

- [CPU Properties](cpu-properties.md) — detailed property reference
- [Patch Dependencies](patch-dependencies.md) — dependency graph between patches
- [How-to: QEMU Flags](../howto/qemu-flags.md) — usage examples
- [Architecture](../explanation/architecture.md) — design overview
