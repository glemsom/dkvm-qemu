# Architecture: Per-Die Asymmetric L3 Cache

This document explains the design and implementation of per-die asymmetric L3 cache reporting in DKVM QEMU — why it's designed this way, how data flows through the system, and what constraints the architecture imposes.

---

## Problem Statement

Standard QEMU CPU models carry a single uniform L3 cache description. Every vCPU reports the same L3 size, associativity, and geometry via CPUID, regardless of which die it belongs to. On AMD processors with heterogeneous dies (e.g., Ryzen 9 9950X3D with one 32 MB L3 die and one 96 MB L3 die), this uniform reporting is incorrect — half the vCPUs lie about their cache.

A uniform offset doesn't solve it: setting the model L3 to 32 MB under-reports the 96 MB die; setting it to 96 MB over-reports the 32 MB die.

---

## Design Overview

The solution adds CPU properties (`l3-cache-size-die<N>`, `l3-cache-assoc-die<N>`) that let users specify per-die L3 overrides. These are stored separately from the model's uniform cache and selected at CPUID encode time based on the vCPU's die ID.

```
CLI properties ──→ Realize: clone model L3, apply overrides ──→ l3_cache_per_die[]
                                                                       │
APIC ID ──→ x86_topo_ids_from_apicid() ──→ die_id ──→ l3_cache_per_die[die_id]
                                                                       │
                                                            ┌──────────┴──────────┐
                                                            ↓                     ↓
                                                     Non-NULL?               NULL?
                                                         ↓                     ↓
                                                  Per-die CPUCacheInfo   Model default
                                                         ↓                     ↓
                                                  CPUID encode sites     (unchanged)
```

---

## Key Design Decisions

### Separate Storage Array (l3_cache_per_die[])

Per-die overrides live in a dedicated array on `CPUX86State`, not in the model's `CPUCaches` struct. Rationale:

- **Minimal blast radius**: Only 3 CPUID encode sites need awareness of the per-die path. The model's uniform `caches->l3_cache` is untouched.
- **No struct bloat**: `CPUCaches` is a shared model definition. Adding die-level structure there would affect all CPU models and complicate model composition.
- **Clear NULL semantics**: A NULL entry = use model default. No ambiguity about whether a die was intentionally set to the model value or just forgotten.

### Clone + Override at Realize Time

Rather than requiring the user to specify full cache geometry for each die (line size, associativity, partitions, sets), the architecture clones the model's L3 `CPUCacheInfo` and overrides only the specified fields:

1. `g_malloc()` + `memcpy()` from model's `caches->l3_cache`
2. Override `size` from `l3-cache-size-die<N>` (if set)
3. Override `associativity` from `l3-cache-assoc-die<N>` (if set)
4. Recalculate `sets = size / (line_size * associativity * partitions)`

This keeps CLI commands concise: `l3-cache-size-die1=96M` instead of spelling out all geometry parameters.

### Passthrough Mode Uses Hardcoded Zen 5 Defaults

In passthrough mode (`-cpu host`), overridden dies cannot clone a model L3 (there is no model). Instead, the code constructs `CPUCacheInfo` from hardcoded Zen 5 cache geometry defaults:

| Parameter | Default value |
|-----------|---------------|
| line_size | 64 |
| associativity | 16 |
| partitions | 1 |
| lines_per_tag | 1 |
| self_init | true |
| no_invd_sharing | true |
| complex_indexing | false |
| inclusive | false |
| share_level | DIE |

This means overridden dies in passthrough mode report Zen 5 geometry — not the host CPU's actual geometry. Correct for 9950X3D simulation on a Zen 5 host; may need updating for future hardware.

Non-overridden dies in passthrough mode continue to report native host values unchanged.

---

## Data Flow: Realize Time

```
x86_cpu_realizefn() called
        │
        ├── Check: any per-die property set while l3-cache=off?
        │      YES → error ("per-die L3 requires l3-cache=on")
        │
        └── For each die N where N < MAX_DIES (8):
                │
                ├── Property set for die N?
                │      YES → continue
                │      NO  → l3_cache_per_die[N] = NULL (skip)
                │
                ├── Model mode or passthrough mode?
                │     Model:    g_malloc + memcpy(model->caches->l3_cache)
                │     Passthrough: g_malloc + fill from hardcoded Zen 5 defaults
                │
                ├── Override size from l3-cache-size-die<N> (if set)
                ├── Override associativity from l3-cache-assoc-die<N> (if set)
                ├── Recalculate sets = size / (line_size * associativity * partitions)
                ├── Warning: die N >= topology die count?
                │      YES → warn ("die index N exceeds topology die count M")
                │
                └── Store: env->l3_cache_per_die[N] = constructed CPUCacheInfo*
```

Validation rules enforced at realize time:

| Rule | Condition | Effect |
|------|-----------|--------|
| Per-die + l3-cache=off | Any per-die property + `l3-cache=off` | Error (startup fails) |
| Die index > topology | `l3-cache-size-die3` with `-smp dies=2` | Warning (property ignored) |
| Fewer props than dies | Only die0 set, `-smp dies=4` | OK (die1-3 use model default) |

---

## Data Flow: CPUID Dispatch Time

At guest CPUID execution, each of three encode sites follows the same selection pattern:

```
1. Extract die_id:
   x86_topo_ids_from_apicid(cpu->apic_id, topo_info, &topo_ids)
   die_id = topo_ids.die_id

2. Select L3 CPUCacheInfo:
   l3 = env->l3_cache_per_die[die_id] ?: caches->l3_cache
                                                  │
                              (per-die override)   │   (model default)
                                             │    │
3. Call encode function with selected l3 ───┘    │
                                             ┌────┘
                                             ↓
                              encode_cache_cpuid4()
                              encode_cache_cpuid80000006()
                              encode_cache_cpuid8000001d()
```

The ternary `?:` operator means:
- If `l3_cache_per_die[die_id]` is non-NULL → use the override
- If NULL → fall back to the model's uniform L3 (original behaviour)

### Passthrough Pre-Check

In passthrough mode, the same three sites get a pre-check before the normal `x86_cpu_get_cache_cpuid()` passthrough path:

```
CPUID leaf L3 encode request (passthrough mode)
        │
        ├── Per-die override exists for this die_id?
        │      YES → call encode_cache_cpuid*() with override
        │             (skip host passthrough for this leaf)
        │
        └── NO → fall through to x86_cpu_get_cache_cpuid()
                  (read real hardware CPUID)
```

For the legacy leaf 0x80000006: the host's L2 TLB/L2 cache info is read first, then only the EDX register (L3 portion) is overridden with the per-die encoding. This preserves the host's L2 data.

---

## Memory Management

Per-die `CPUCacheInfo` structs are heap-allocated during realize and must be freed when the CPU instance is destroyed:

- **Allocation**: `g_malloc()` + `memcpy()`, done in `x86_cpu_realizefn()` (patch 0006)
- **Deallocation**: `g_free()` in `x86_cpu_finalizefn()` (patch 0006), wired into QEMU's `instance_finalize` callback
- **Leak risk**: If realizefn fails mid-initialization after some allocations succeed, already-allocated structs must be freed. The current implementation frees on the error path by jumping to a cleanup label.

---

## Constraints and Limits

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Max dies | 8 (`MAX_DIES`) | Covers today's AMD EPYC (up to 8 CCDs). Extensible if needed. |
| Die index | 0-based, N=0..7 | Must match `-smp dies=N` topology. Indexing is user responsibility. |
| Cache override scope | L3 only | L1/L2 are per-core and not die-level. Per-die L1/L2 has no hardware analogue. |
| Passthrough geometry | Zen 5 hardcoded | Future µarchs may need new defaults. Patch 0008 maintains the template. |
| Migration/savevm | Unchanged | Properties preserved through QEMU's standard property mechanism. No custom state to migrate. |

---

## Why Not Alternatives?

| Approach | Rejected because |
|----------|-----------------|
| Machine-level `-smp-cache` option | Feature is CPU-model-specific, not machine-level. CPU properties are the natural QEMU mechanism for per-CPU configuration. |
| Extend `CPUCaches` with per-die fields | Would bloat the shared model struct. Separate array limits awareness to the 3 encode sites. |
| Full geometry specification per die | Verbose CLI. Clone+override covers 95% of use cases (same µarch, different capacity). |
| Single monolithic patch | Less reviewable. Split into 0006 (foundation) / 0007 (model encode) / 0008 (passthrough) for clarity. |

---

## See Also

- [ADR-0001](../adr/0001-per-die-asymmetric-l3-cache.md) — architecture decision record with trade-offs
- [AMD Die Topology](amd-die-topology.md) — background on AMD die/CCD topology
- [CPUID Cache Encoding](cpuid-cache-encoding.md) — CPUID leaf encoding details
- [Glossary](../reference/glossary.md) — domain terminology
- [CPU Properties](../reference/cpu-properties.md) — property reference with validation rules
