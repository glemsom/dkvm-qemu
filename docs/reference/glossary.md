# DKVM QEMU — Domain Glossary

Domain terminology used throughout the DKVM QEMU project.

## Die

A topology container that groups cores sharing a unified L3 cache instance. Maps to AMD CCD (Core Complex Die) in hardware.

_Avoid_: CCD, tile, cluster, compute unit

## L3 Cache Instance

The L3 cache belonging to a single die. Each die has exactly one L3 cache instance with its own size, associativity, and sets. Different dies may have different L3 parameters.

_Avoid_: L3 slice, L3 partition

## Cache Topology Level

The hierarchical level at which a cache is shared (thread, core, module, die, socket). Defined by `CpuTopologyLevel` enum in QEMU.
