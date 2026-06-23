# Getting Started with DKVM QEMU

This tutorial walks through your first build of DKVM QEMU from scratch. By the end, you will have a working `qemu-system-x86_64` binary and verify it boots with per-die asymmetric L3 cache support.

**Time required:** ~10–15 minutes  
**Prerequisites:** Docker, Git, ~4 GB free disk space

---

## Step 1: Clone the repository

```bash
git clone https://github.com/glemsom/dkvm-qemu.git
cd dkvm-qemu
```

## Step 2: Build QEMU

The dev build compiles QEMU inside a Docker container, applies all patches, and outputs the binary.

```bash
./dev-build.sh
```

This will:

1. Build the `qemu-dev-builder` Docker image (Alpine 3.24 + build deps + QEMU 11.0.1 source)
2. Apply all patches from `patches/`
3. Compile `x86_64-softmmu` target with KVM
4. Copy the binary to `build/out/qemu-system-x86_64`

When done, verify the binary exists:

```bash
ls -la build/out/qemu-system-x86_64
```

Expected output: a ~50 MB binary.

## Step 3: Run the test suite

```bash
./dev-test.sh build/out/qemu-system-x86_64
```

The test suite checks:

- QMP `query-cpu-model-expansion` with per-die properties
- Error handling (`l3-cache=off` + per-die property → error)
- Multi-die SMP boot with per-die L3 (model and passthrough modes)
- Regression: no per-die properties → uniform L3
- KVM passthrough boot (if `/dev/kvm` available)

All tests should pass. Example output:

```
=== Test 1: QMP — query-cpu-model-expansion with per-die properties ===
PASS: Model expansion with per-die props succeeds
...
=== Results: 10 passed, 0 failed ===
```

## Step 4: Boot a VM with asymmetric L3

Create a VM with 2 dies where die0 has 32 MB L3 and die1 has 96 MB L3 (simulating a 9950X3D-like configuration):

```bash
# Quick smoke test (no disk image needed)
./dev-test.sh build/out/qemu-system-x86_64
```

For a real VM boot, you need a disk image and appropriate flags:

```bash
/path/to/dkvm-qemu/build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1 \
  -m 4G \
  -drive file=/path/to/disk.qcow2,format=qcow2 \
  -display none
```

## Step 5: Verify inside the guest

Once the VM is booted, check the L3 cache topology:

```bash
# Linux guest
lscpu -e
lscpu -C
# Look for L3 cache line — should show asymmetric sizes per die
# Example:
#   L3d  L3  L3  33554432 (die0, 32 MB)
#   L3d  L3  L3  100663296 (die1, 96 MB)
```

You can also inspect CPUID directly:

```bash
cpuid -1 | grep -A 10 "L3"
```

## What's next?

- [Usage — QEMU Flags](../README.md#usage) — all CPU properties and flags
- [Domain Glossary](../CONTEXT.md) — terminology and design decisions
- [Architecture Decision Record](../docs/adr/0001-per-die-asymmetric-l3-cache.md) — why things are designed this way
- [Contributing](../CONTRIBUTING.md) — how to submit patches
