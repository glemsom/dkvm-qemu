# How-to: Simulate AMD Ryzen 9 9950X3D

Configure a QEMU VM that matches the AMD Ryzen 9 9950X3D's die topology: 2 dies, 8 cores each, with per-die asymmetric L3 cache (32 MB on die 0, 96 MB on die 1).

---

## Prerequisites

- DKVM QEMU built from this repository (`./dev-build.sh`)
- A guest OS that supports AMD die topology (Linux kernel ≥5.x with `CONFIG_NUMA`)
- Optional: a disk image for a persistent guest

---

## Step 1: Build QEMU

```bash
./dev-build.sh
```

Verify the binary has per-die L3 support:

```bash
strings build/out/qemu-system-x86_64 | grep l3-cache-size-die
```

Expected: `l3-cache-size-die0`, `l3-cache-size-die1`, … (N=0..7).

---

## Step 2: Basic 9950X3D Configuration

The 9950X3D has 16 cores total across 2 dies, with asymmetric L3:

| Component | Die 0 | Die 1 |
|-----------|-------|-------|
| Cores | 8 | 8 |
| L3 cache | 32 MB | 96 MB |
| L3 associativity | 16 | 12 (3D V-Cache) |

### Minimal QEMU command

```bash
build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1 \
  -m 4G \
  -display none
```

This boots a VM where:
- vCPUs 0–7 (die 0) see 32 MB L3
- vCPUs 8–15 (die 1) see 96 MB L3

### With associativity override

The 3D V-Cache die may use different associativity. To match the 9950X3D:

```bash
build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296,l3-cache-assoc-die1=12 \
  -smp 16,dies=2,cores=8,threads=1 \
  -m 4G \
  -display none
```

---

## Step 3: Boot with a Disk Image

```bash
build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1 \
  -m 4G \
  -drive file=/path/to/disk.qcow2,format=qcow2 \
  -display none
```

Create a test disk if needed:

```bash
qemu-img create -f qcow2 test-disk.qcow2 8G
```

---

## Step 4: Verify Inside the Guest

Boot the VM and run these checks:

### lscpu — per-CPU topology

```bash
lscpu -e
```

Look for the `DIE` column — vCPUs 0–7 should show die 0, vCPUs 8–15 die 1.

```bash
lscpu -C
```

Look for the L3 cache line. You should see:
- One L3 instance per die
- Different sizes for different dies

### sysfs — per-CPU cache size

```bash
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  cpu=$(basename "$cpu")
  die=$(cat "$cpu/topology/die_id" 2>/dev/null || echo "N/A")
  l3=$(cat "$cpu/cache/index3/size" 2>/dev/null || echo "N/A")
  echo "$cpu die=$die L3=$l3"
done
```

Expected output showing two groups:

```
cpu0 die=0 L3=32768K
cpu1 die=0 L3=32768K
...
cpu8 die=1 L3=98304K
cpu9 die=1 L3=98304K
...
```

### cpuid — raw CPUID leaf

```bash
cpuid -1 | grep -A 10 "L3 cache"
```

---

## Step 5: NUMA Configuration (Optional)

For better topology emulation, add NUMA nodes matching the dies:

```bash
build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1 \
  -m 32G \
  -numa node,nodeid=0,cpus=0-7,memdev=mem0 \
  -numa node,nodeid=1,cpus=8-15,memdev=mem1 \
  -object memory-backend-ram,id=mem0,size=16G \
  -object memory-backend-ram,id=mem1,size=16G \
  -drive file=/path/to/disk.qcow2,format=qcow2
```

This creates two NUMA nodes — one per die — matching the 9950X3D's memory architecture.

---

## Step 6: Host Passthrough Mode

If you want to passthrough the host CPU's features but override L3 for one die:

```bash
build/out/qemu-system-x86_64 \
  -cpu host,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1 \
  -m 4G \
  -display none
```

In this mode:
- Die 0 reads L3 info from real hardware (passthrough)
- Die 1 reports 96 MB L3 with hardcoded Zen 5 defaults

Use this on a real 9950X3D host to make the VM match the host's topology exactly.

---

## Step 7: Common Validation Errors

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| All vCPUs show 32 MB L3 | `-smp` missing `dies=2` | Add `dies=2` to `-smp` |
| `Property 'l3-cache-size-die0' not found` | Wrong QEMU build | Use DKVM QEMU binary |
| vCPUs 8-15 show wrong die | APIC ID mapping off | Check `-smp` core/thread count matches expected die layout |
| Guest reports uniform L3 in `cpuid` but correct in `lscpu -C` | Old kernel uses legacy leaf | Update guest kernel or check `cpuid` leaf 0x8000001D specifically |

---

## Reference: 9950X3D Parameters

| Parameter | Die 0 | Die 1 |
|-----------|-------|-------|
| CCD count | 1 | 1 |
| Cores per CCD | 8 | 8 |
| L3 cache (standard) | 32 MB | 32 MB |
| 3D V-Cache | none | 64 MB stacked |
| L3 total | 32 MB | 96 MB |
| L3 associativity | 16-way | 12-way |
| L3 line size | 64 B | 64 B |
| CPUID family/model | 0x19 (Zen 5) | 0x19 (Zen 5) |

---

## Related

- [QEMU Flags](qemu-flags.md) — all CPU properties and flags
- [Debug Per-Die L3](debug-per-die-l3.md) — troubleshooting guide
- [AMD Die Topology](../explanation/amd-die-topology.md) — background on chiplet architecture
- [Getting Started](../tutorial/getting-started.md) — first build tutorial
