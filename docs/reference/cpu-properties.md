# Custom CPU Properties

Reference quadrant — documents extra CPU properties added by DKVM QEMU patches, on top of standard QEMU CPU properties.

## Overview

Three custom CPU properties augment standard QEMU `-cpu` configuration:

| Property | Purpose | Patch |
|----------|---------|-------|
| `x-force-cpuid-0x80000026` | Enable AMD extended topology leaf (CPUID[0x80000026]) | 0002 |
| `l3-cache-size-die<N>` | Override L3 cache size for die N (bytes) | 0006 |
| `l3-cache-assoc-die<N>` | Override L3 cache associativity for die N | 0006 |

`x-force-cpuid-0x80000026` is foundational — without it, `die_id` extraction from APIC ID fails, making per-die L3 properties ineffective.

## Property Table

### `x-force-cpuid-0x80000026`

| Field | Value |
|-------|-------|
| **Type** | boolean (on/off) |
| **Default** | `off` (auto-enables for Zen4+ family 0x19, model 0x10-0x1f / 0x60-0xaf) |
| **Applies to** | All AMD CPU models |
| **Patch** | `0002-x-force-cpuid.patch` |
| **Description** | When `on`, injects CPUID[0x80000026] extended topology leaf exposing die/module topology to the guest OS. Required for per-die L3 cache properties to work. Auto-detects Zen4 and above CPUs and enables automatically. |

### `l3-cache-size-die<N>`

| Field | Value |
|-------|-------|
| **Type** | size (bytes; QEMU suffixes like M, MiB, G accepted) |
| **Default** | Model's uniform L3 size (no override) |
| **Applies to** | EPYC-Turin, `host`, all models with L3 cache |
| **Patch** | `0006-per-die-l3-cache.patch` |
| **Description** | Override L3 cache size for die N (N=0..7). Clone model's L3 `CPUCacheInfo`, replace size, recalculate sets: `sets = size / (line_size * associativity * partitions)`. Dies without override use model default. |

### `l3-cache-assoc-die<N>`

| Field | Value |
|-------|-------|
| **Type** | integer |
| **Default** | Model's associativity (no override; 16 for passthrough Zen5 template) |
| **Applies to** | EPYC-Turin, `host`, all models with L3 cache |
| **Patch** | `0006-per-die-l3-cache.patch` |
| **Description** | Override L3 cache associativity for die N (N=0..7). If set, overrides associativity before recalculating sets. Needed for 3D V-Cache (9950X3D) where extra cache uses higher associativity. |

## Validation Rules

| # | Rule | Condition | Effect |
|---|------|-----------|--------|
| 1 | Per-die + `l3-cache=off` | Any `l3-cache-size-die<N>` or `l3-cache-assoc-die<N>` set while `l3-cache=off` | **Error**: QEMU startup fails. Per-die properties require `l3-cache=on`. |
| 2 | Die index > topology die count | `l3-cache-size-die3` set but `-smp dies=2` | **Warning**: die index 3 exceeds 2-die topology; property ignored. Unspecified dies use model default. |
| 3 | Fewer per-die props than dies | Only `l3-cache-size-die0` set but `-smp dies=4` | **No warning**: dies 1-3 use model default. This is normal. |
| 4 | Passthrough + per-die allowed | `host-cache-info=on` (passthrough mode) with any `l3-cache-size-die<N>` | **Allowed**: per-die override uses hardcoded Zen5 L3 base template (see defaults below). Non-overridden dies use native host passthrough. |
| 5 | Passthrough + `l3-cache=off` + per-die | `host-cache-info=on`, `l3-cache=off`, and per-die property | **Error**: same as rule 1 — per-die properties need `l3-cache=on`. |

### Passthrough Mode Defaults (Zen5 template)

When `host-cache-info=on`, overridden dies use these hardcoded values as base geometry:

| Parameter | Value |
|-----------|-------|
| line_size | 64 |
| associativity | 16 (overrideable via `l3-cache-assoc-die<N>`) |
| partitions | 1 |
| lines_per_tag | 1 |
| self_init | true |
| no_invd_sharing | true |
| complex_indexing | false |
| inclusive | false |
| share_level | CPU_TOPOLOGY_LEVEL_DIE |

## Examples

### `x-force-cpuid-0x80000026`

```sh
# Explicit enable on EPYC-Turin
-cpu EPYC-Turin,x-force-cpuid-0x80000026=on

# Disable override (auto-detect already on for Zen4+)
-cpu EPYC-Turin,x-force-cpuid-0x80000026=off

# Force on non-Zen4 AMD model
-cpu EPYC-<model>,x-force-cpuid-0x80000026=on
```

### Per-die asymmetric L3 cache (model mode)

```sh
# EPYC-Turin, 2 dies, die0=32MB (33554432), die1=96MB (100663296)
-cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1

# With associativity override (3D V-Cache simulation)
-cpu EPYC-Turin,l3-cache-size-die1=100663296,l3-cache-assoc-die1=12 \
  -smp 16,dies=2,cores=8,threads=1

# Single die override, rest use model default
-cpu EPYC-Turin,l3-cache-size-die0=50331648 \
  -smp 8,dies=4,cores=2,threads=1
```

### Per-die asymmetric L3 cache (host passthrough mode)

```sh
# Host passthrough, override die1 L3 to 96MB (9950X3D simulation)
-cpu host,l3-cache-size-die1=100663296

# Passthrough without per-die props → pure host passthrough, no change
-cpu host
```

### Validation scenarios

```sh
# Error: per-die property requires l3-cache=on
-cpu EPYC-Turin,l3-cache=off,l3-cache-size-die0=33554432

# Warning: die index 3 exceeds 2-die topology (ignored)
-cpu EPYC-Turin,l3-cache-size-die3=100663296 -smp 8,dies=2,cores=4

# Error: passthrough + l3-cache=off + per-die property
-cpu EPYC-Turin,host-cache-info=on,l3-cache=off,l3-cache-size-die1=100663296
```

## QMP `query-cpu-model-expansion` Output

When using QMP to inspect CPU models, per-die properties appear in the `props` dictionary of the expansion response.

### Request

```json
{
  "execute": "query-cpu-model-expansion",
  "arguments": {
    "type": "static",
    "model": {
      "name": "EPYC-Turin",
      "props": {
        "l3-cache-size-die0": 33554432,
        "l3-cache-size-die1": 100663296,
        "x-force-cpuid-0x80000026": true
      }
    }
  }
}
```

### Response (abridged)

```json
{
  "return": {
    "model": {
      "name": "EPYC-Turin",
      "props": {
        "x-force-cpuid-0x80000026": true,
        "l3-cache-size-die0": 33554432,
        "l3-cache-size-die1": 100663296,
        "l3-cache-size-die2": 0,
        "l3-cache-size-die3": 0,
        "l3-cache-size-die4": 0,
        "l3-cache-size-die5": 0,
        "l3-cache-size-die6": 0,
        "l3-cache-size-die7": 0,
        "l3-cache-assoc-die0": 0,
        "l3-cache-assoc-die1": 0,
        ...
      }
    }
  }
}
```

Unset per-die properties serialize as `0` (internal default). The `l3-cache-assoc-die<N>` for unset dies appear as `0`, meaning "use model default".
