# DKVM QEMU — Asymmetric Cache Topology

Custom QEMU builds for AMD EPYC/ Ryzen virtualization with asymmetric die topology and per-die L3 cache support.

## Language

**Die**:
A topology container that groups cores sharing a unified L3 cache instance. Maps to AMD CCD (Core Complex Die) in hardware.
_Avoid_: CCD, tile, cluster, compute unit

**L3 Cache Instance**:
The L3 cache belonging to a single die. Each die has exactly one L3 cache instance with its own size, associativity, and sets. Different dies may have different L3 parameters.
_Avoid_: L3 slice, L3 partition

**Cache Topology Level**:
The hierarchical level at which a cache is shared (thread, core, module, die, socket). Defined by `CpuTopologyLevel` enum in QEMU.

## Design Decisions

**User Interface**: Per-die L3 cache sizes configured via CPU properties (`l3-cache-size-die0`, `l3-cache-size-die1`, etc.), not machine-level or model-level.

**Configuration Property**: `l3-cache-size-die<N>` — integer property in bytes, accepting suffixes (M, MiB, etc.). Default: uses model's uniform L3 size if not specified. Optional: `l3-cache-assoc-die<N>` to override associativity per die (default: model's associativity). Max 8 dies supported (fixed array). Only L3 gets per-die treatment; L1/L2 are per-core and stay uniform.

**Cache Geometry Derivation**: Clone model's L3 `CPUCacheInfo`, override `size` from property, recalculate `sets = size / (line_size * associativity * partitions)`. If associativity property set, override that too before recalculating sets.

**Per-CPU Selection Mechanism**: At CPUID encode time, extract `die_id` from vCPU's APIC ID via `x86_topo_ids_from_apicid()`, select corresponding per-die L3 `CPUCacheInfo` from `CPUX86State.l3_cache_per_die[]`, fall back to model default if no per-die override exists for that die.

**Internal Storage**: New field `CPUCacheInfo *l3_cache_per_die[MAX_DIES]` on `CPUX86State`, separate from existing `cache_info` struct. Only CPUID encode sites (0x8000001D leaf 3, 0x80000006.EDX, CPUID 4) select from this array.

**Initialization Timing**: Per-die L3 structs constructed during `x86_cpu_realizefn()`, right after `env->cache_info = *cache_info`. For each die where a property is set: clone model's L3 `CPUCacheInfo` via g_malloc+memcpy, override size/associativity, recalculate sets. Dies without a property keep NULL pointer (falls back to model default at encode time).

**Fallback Rule**: Only the uniform `l3_cache` from the model definition is used for any die that lacks a per-die override.

**Validation Rules**:
1. Topology has more dies than per-die properties set → no warning, unspecified dies use model/default.
2. Per-die property for a die index exceeding topology's die count → warn, ignore excess property.
3. Per-die property set while `l3-cache=off` → error.
4. Per-die property set while `host-cache-info=on` → **allowed**. In passthrough mode, per-die properties use hardcoded defaults for Zen5 L3 geometry as base template (line_size=64, associativity=16, partitions=1, no_invd_sharing=true, share_level=CPU_TOPOLOGY_LEVEL_DIE).

**Memory Management**: Per-die `CPUCacheInfo` structs are heap-allocated (`g_malloc`) at realize time. Freed in CPU object destructor via `g_free()`.

**Passthrough Mode Defaults** (hardcoded for host passthrough, matching Zen5):
- line_size = 64
- associativity = 16 (overrideable via `l3-cache-assoc-die<N>`)
- partitions = 1
- lines_per_tag = 1
- self_init = true
- no_invd_sharing = true
- complex_indexing = false
- inclusive = false
- share_level = CPU_TOPOLOGY_LEVEL_DIE
