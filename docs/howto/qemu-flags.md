# How-to: Build and QEMU Flags

This guide covers building DKVM QEMU and configuring per-die asymmetric L3 cache via `-cpu` flags.

---

## Build

```sh
# Docker dev build (applies all patches, outputs qemu-system-x86_64)
./dev-build.sh

# Or use the Alpine APKBUILD directly:
abuild checksum   # update checksums
abuild -r         # build
```

## QEMU Flags

All features are configured via CPU properties on the `-cpu` flag.

### Enable die topology (required for per-die L3)

```sh
# Auto-detect for Zen4+ models; or force with:
-cpu EPYC-Turin,x-force-cpuid-0x80000026=on
```

### Per-die asymmetric L3 cache (model mode)

```sh
# EPYC-Turin, 2 dies, die0=32MB (33554432), die1=96MB (100663296)
-cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1

# With associativity override for 3D V-Cache
-cpu EPYC-Turin,l3-cache-size-die1=100663296,l3-cache-assoc-die1=12 \
  -smp 16,dies=2,cores=8,threads=1
```

### Per-die asymmetric L3 cache (host passthrough mode)

```sh
# Host passthrough, override die1 L3 to 96MB (100663296) (9950X3D simulation)
-cpu host,l3-cache-size-die1=100663296

# Passthrough without per-die props → pure host passthrough, no change
-cpu host
```

### Validation examples

```sh
# Error: per-die property requires l3-cache=on
-cpu EPYC-Turin,l3-cache=off,l3-cache-size-die0=33554432
# Warning: die index 3 exceeds 2-die topology (ignored)
-cpu EPYC-Turin,l3-cache-size-die3=100663296 -smp 8,dies=2,cores=4
```

## Test

See [Testing](testing.md) for the test suite guide.

The test suite verifies:
- QMP `query-cpu-model-expansion` with per-die properties
- Error handling (`l3-cache=off` + per-die prop)
- Multi-die SMP boot with per-die L3 (model and passthrough mode)
- Regression: no per-die properties → uniform L3
- KVM passthrough boot (if `/dev/kvm` available)
