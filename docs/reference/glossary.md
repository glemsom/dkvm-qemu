# DKVM QEMU — Domain Glossary

Domain terminology used throughout the DKVM QEMU project.

---

## 3D V-Cache

AMD technology stacking an additional 64 MB L3 SRAM die vertically on top of a standard CCD (32 MB L3), connected via hybrid bonding (TSVs). Total L3 for that die becomes 96 MB. Used in Ryzen X3D parts (e.g., 9950X3D).

*Contrast:* Standard CCD (32 MB L3 without stack).

---

## APIC ID

Advanced Programmable Interrupt Controller identifier. Each vCPU gets a unique APIC ID that encodes its position in the topology hierarchy (socket → die → module → core → thread). `x86_topo_ids_from_apicid()` decomposes the APIC ID to extract `die_id`, `core_id`, etc.

*See also:* die_id, x86_topo_ids_from_apicid

---

## Associativity (cache)

Number of ways in a set-associative cache. L3 on AMD Zen 5 is typically 16-way. 3D V-Cache may use different associativity (e.g., 12-way). Overridable via `l3-cache-assoc-die<N>`.

*Formula:* `size = line_size × associativity × partitions × sets`

*See also:* sets, line_size, partitions

---

## Cache Instance

A single cache unit with its own parameters (size, associativity, sets, line size). Each die has exactly one L3 cache instance. Different dies may have different L3 instances.

*See also:* Die, L3

---

## Cache Topology Level

Hierarchical level at which a cache is shared. Defined by `CpuTopologyLevel` enum in QEMU: thread, core, module, die, socket. L3 is shared at the die level.

---

## CCD (Core Complex Die)

AMD's term for a compute chiplet — a silicon die containing up to 8 CPU cores and a shared L3 cache. A single processor package may contain 1, 2, 4, 8, or more CCDs.

*See also:* CCX, Die, Chiplet

---

## CCX (Core Complex)

A cluster of CPU cores within a CCD. Zen 5 CCDs typically have one CCX of 8 cores.

---

## Chiplet

Small silicon die packaged together with other dies on a single substrate. AMD uses chiplets for CCDs (compute), I/O dies, and memory controllers.

---

## CPUCacheInfo

QEMU struct (`target/i386/cpu.h`) describing one cache level: size, line_size, associativity, partitions, sets, sharing topology. Per-die overrides are stored as `CPUCacheInfo*` pointers in `l3_cache_per_die[]`.

---

## CPUCaches

QEMU struct aggregating pointers to L1 (data + instruction), L2, and L3 `CPUCacheInfo` for a CPU model's uniform cache hierarchy.

---

## CPUID Leaf

A logical function number passed in EAX when executing the `CPUID` instruction. Each leaf returns cache, topology, and feature information in EAX/EBX/ECX/EDX. Per-die L3 patches modify leaves 4, 0x80000006, and 0x8000001D.

*See also:* CPUID Sub-leaf

---

## CPUID Sub-leaf

An index within a CPUID leaf, passed in ECX. Used for cache enumeration: sub-leaf 0 = L1 data, 1 = L1 instruction, 2 = L2, 3 = L3.

---

## Die

A topology container that groups cores sharing a unified L3 cache instance. Maps to AMD CCD in hardware. QEMU's SMP topology uses `-smp dies=N` to define the die count.

*Avoid:* CCD, tile, cluster (use Die for QEMU contexts)

---

## die_id

Zero-based index identifying which die a vCPU belongs to. Extracted from the vCPU's APIC ID at CPUID dispatch time. Used to index `l3_cache_per_die[]`.

*See also:* APIC ID, x86_topo_ids_from_apicid

---

## Die Topology Leaf (CPUID[0x80000026])

AMD extended topology leaf introduced in Zen 4. Reports die/module topology structure. Required for per-die L3 to function — without it, every vCPU's die_id is 0.

---

## encode_cache_cpuid*()

Family of three QEMU functions that populate CPUID output registers with cache geometry:
- `encode_cache_cpuid4()` — CPUID[4] (Intel-style)
- `encode_cache_cpuid80000006()` — CPUID[0x80000006].EDX (legacy AMD)
- `encode_cache_cpuid8000001d()` — CPUID[0x8000001D] (AMD extended)

All three are modified by patch 0007/0008 to select per-die L3.

---

## Extended Topology Leaf

See *Die Topology Leaf (CPUID[0x80000026])*.

---

## Family/Model

AMD CPU identification scheme. Family 0x19 (25) = Zen 4/5. Zen 4 models: 0x10-0x1f, 0x60-0x6f. Used by `x-force-cpuid-0x80000026` auto-detect to enable die topology on Zen4+.

---

## Finalizefn

QEMU device lifecycle function that frees per-die `CPUCacheInfo` structs from `l3_cache_per_die[]` when a CPU instance is destroyed. Added by patch 0006.

*See also:* Realizefn, l3_cache_per_die

---

## host-cache-info

CPU property (`host-cache-info=on`) that switches from model-defined cache to host hardware passthrough. Equivalent to `-cpu host`. Per-die L3 properties work in this mode by intercepting L3 leaves before the passthrough path.

*See also:* Passthrough Mode, Model Mode

---

## Hybrid Bonding

Connection technology (through-silicon vias, TSVs) used to stack 3D V-Cache die onto a standard CCD. Electrical connections pass vertically between stacked dies.

*See also:* 3D V-Cache, TSV

---

## Infinity Fabric

AMD's interconnect technology connecting CCDs, I/O die, and memory controllers within a processor package. Cross-die L3 cache misses must traverse Infinity Fabric, incurring higher latency than local die access.

---

## KVM (Kernel-based Virtual Machine)

Linux kernel module providing hardware-accelerated virtualization. QEMU uses KVM via `/dev/kvm` for near-native guest performance. The `-cpu host` passthrough mode reads real hardware CPUID via KVM.

---

## l3_cache_per_die[]

Array of 8 `CPUCacheInfo*` pointers on `CPUX86State`. Indexed by die_id. NULL means "use model default." Populated during realizefn by cloning the model L3 and applying property overrides.

*See also:* Realizefn, die_id, CPUCacheInfo

---

## L3 (Last-Level Cache)

Level 3 cache, shared by all cores within a die. On AMD Zen 5 CCDs: 32 MB standard, up to 96 MB with 3D V-Cache. Reported via CPUID leaves 4, 0x80000006, and 0x8000001D.

---

## Line Size

Number of bytes per cache line. AMD Zen 5 L3 line size is 64 bytes.

*See also:* Associativity, Sets, Partitions

---

## Model Mode

CPU configuration using a built-in QEMU model (e.g., `-cpu EPYC-Turin`) with optional property overrides. Cache information comes from the model definition, optionally overridden by per-die properties.

*Contrast:* Passthrough Mode

---

## NUMA (Non-Uniform Memory Access)

Memory architecture where access latency depends on which die/CPU the memory is attached to. Linux uses L3 cache topology to build NUMA maps. Correct per-die L3 reporting enables optimal NUMA-aware scheduling.

---

## Partitions (cache)

Number of physical partitions in a cache bank. AMD Zen 5 L3 typically has 1 partition.

*Formula:* `size = line_size × associativity × partitions × sets`

*See also:* Sets, Associativity, Line Size

---

## Passthrough Mode

CPU configuration using `-cpu host` (or `host-cache-info=on`) where cache information is read from real hardware via KVM instead of from a QEMU model. Per-die L3 properties intercept L3 CPUID leaves in passthrough mode using hardcoded Zen 5 geometry defaults for overridden dies.

*Contrast:* Model Mode

---

## QMP (QEMU Machine Protocol)

JSON-based protocol for controlling QEMU instances. Used by tests to verify CPU model expansion with per-die properties (`query-cpu-model-expansion`).

---

## Realizefn (x86_cpu_realizefn)

QEMU device lifecycle function called when a CPU device is realized (constructed). Per-die patches add initialization: iterate configured dies, clone model L3, apply property overrides, store in `l3_cache_per_die[]`.

*See also:* Finalizefn, l3_cache_per_die

---

## Sets (cache)

Number of cache sets (rows) in a set-associative cache. Recalculated when size or associativity is overridden: `sets = size / (line_size × associativity × partitions)`.

*Formula:* `size = line_size × associativity × partitions × sets`

*See also:* Associativity, Line Size, Partitions

---

## Topology Info (X86CPUTopoInfo)

QEMU struct holding bits-per-socket, bits-per-die, bits-per-core, etc., derived from the `-smp` topology. Used by `x86_topo_ids_from_apicid()` to extract topology fields from an APIC ID.

---

## TSV (Through-Silicon Via)

Vertical electrical connection passing through a silicon die. Used in 3D V-Cache hybrid bonding to connect the stacked cache die to the CCD below.

*See also:* Hybrid Bonding, 3D V-Cache

---

## x86_topo_ids_from_apicid()

QEMU function that decomposes a vCPU's APIC ID into topology components (pkg_id, die_id, module_id, core_id, smt_id). Called at each CPUID L3 encode site to select the per-die cache override.

*See also:* APIC ID, die_id

---

## x-force-cpuid-0x80000026

Boolean CPU property that forces CPUID[0x80000026] die topology leaf to be exposed. Auto-enables on Zen 4+ CPUs. Required for per-die L3 — without it, die_id is always 0.

*See also:* Die Topology Leaf

---

## Zen 4 / Zen 5

AMD CPU microarchitectures. Zen 4 introduced the die topology leaf (0x80000026). Zen 5 powers the Ryzen 9950X3D. The auto-detect in patch 0002 enables die topology for family 0x19, Zen 4+ models.
