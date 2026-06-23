# Per-Die Asymmetric L3 Cache via CPU Properties

We implement per-die L3 cache size asymmetry for AMD 9950X3D simulation by adding `l3-cache-size-die<N>` CPU properties. The per-die L3 `CPUCacheInfo` structs are stored in a separate array on `CPUX86State` (`l3_cache_per_die[8]`), populated at realize time by cloning the model's L3 and overriding size/associativity. At CPUID encode time, the vCPU's `die_id` is extracted from its APIC ID to select the correct L3 cache info. Host passthrough mode is supported with hardcoded Zen5 L3 geometry defaults.

## Status

Accepted

## Considered Options

- **CPU properties** (`l3-cache-size-die<N>`) vs machine-level config (`-smp-cache` extension): CPU properties win for simplicity and because the feature is CPU-model-specific, not machine-level.

- **Separate array on CPUX86State** vs extending `CPUCaches` struct: Separate array minimizes blast radius — only the CPUID encode call sites (4 locations) need awareness, and existing cache paths are untouched.

- **Clone model L3 + override** vs full geometry specification: Clone+override avoids CLI verbosity for the common case (same µarch, different capacity). Optional `l3-cache-assoc-die<N>` covers the 3D V-Cache associativity case.

- **Split into multiple patches** vs single patch: **Split chosen** — three patches for reviewability and independent understanding:
  - `0006-per-die-l3-cache.patch`: Foundation — properties, storage, realize init/finalize.
  - `0007-per-die-l3-cpuid-encode.patch`: Model-mode CPUID encode at all 3 L3 encode sites.
  - `0008-per-die-l3-passthrough.patch`: Host passthrough-mode CPUID encode at same sites.
  
  Split improves reviewability and lets each patch be understood independently. Reverting one aspect does not require reverting all. (See [patch-dependencies.md](../reference/patch-dependencies.md) for dependency details.)

## Consequences

- CLI must match `-smp dies=N` to have meaningful effect (no topology validation though).
- Host passthrough mode (`-cpu host`) works but uses hardcoded Zen5 defaults instead of host CPUID for overridden dies — correct for 9950X3D, may need updating for future hardware.
- libvirt integration will require schema extension for per-die cache properties.
- Migration not affected — properties are preserved through QEMU's standard property mechanism.
