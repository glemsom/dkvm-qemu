# How-to: Debug Per-Die L3 Cache Issues

Diagnose problems when per-die asymmetric L3 cache sizes don't show up in the guest, or QEMU rejects/reports unexpected behavior.

---

## Prerequisites

Tools inside the guest VM:

| Tool | Package | What for |
|------|---------|----------|
| `lscpu` | `util-linux` | Print cache topology per CPU, per cache index |
| `cpuid` | `cpuid` (x86) | Raw CPUID leaf dumps |
| `/sys/devices/system/cpu/` | kernel | Per-CPU cache size files |

Install inside the guest:

```bash
# Alpine
apk add util-linux cpuid

# Debian/Ubuntu
apt install util-linux cpuid

# Fedora/RHEL
dnf install util-linux cpuid
```

---

## 1. Verify Config Applied

### Via QMP (before boot)

Use `query-cpu-model-expansion` to confirm QEMU accepts your per-die properties:

```bash
echo "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': {
    'type': 'static',
    'model': { 'name': 'EPYC-Turin', 'props': {
        'l3-cache-size-die0': 33554432,
        'l3-cache-size-die1': 100663296
    } }
} }
{ 'execute': 'quit' }" | \
timeout 15 build/out/qemu-system-x86_64 \
  -machine none -S -display none -qmp stdio 2>/dev/null
```

Expected output contains `"return": {}`. If you see `"error"`, QEMU rejected the config — see [Common Issues](#common-issues).

### Via QEMU log warnings at startup

Run QEMU with stderr visible and check for warnings:

```bash
build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die3=100663296 \
  -smp 4,dies=2,cores=2,threads=1 \
  -machine pc -m 1G \
  -display none \
  2>&1 | grep -i "l3-cache\|die"
```

If a die index exceeds the topology, you'll see something like:

```
l3-cache-size-die3: die index >= topology die count (2), ignoring
```

---

## 2. Inspect Guest-Visible CPUID

Inside the guest, after boot:

### CPUID[0x80000006] — L3 cache info (legacy leaf)

```bash
cpuid -1 | grep -A 10 "L3"
```

Sample output for a 2-die VM with die0=32MB, die1=96MB:

```
   L3 cache info (0x80000006):
      L3 cache         : 32MB (for die 0 vCPUs)
      L3 cache         : 96MB (for die 1 vCPUs)
```

If **all** vCPUs show the same value, the per-die override isn't being selected — see [common issue: -smp dies=](#all-cpus-show-32mb-even-though-i-set-l3-cache-size-die196m).

### lscpu — per-CPU topology and cache

```bash
# Per-CPU core/socket/die mapping + L1/L2/L3 cache
lscpu -e

# Per-cache-index details
lscpu -C
```

`lscpu -e` shows each CPU's die ID. `lscpu -C` lists all cache instances with their sizes. If `l3_cache_per_die[]` is working, you'll see different L3 sizes on different dies.

---

## 3. Check /sys/devices/system/cpu/

The kernel exposes per-CPU cache topology. Verify per-die L3 sizes:

```bash
# L3 size per CPU
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  cpu=$(basename "$cpu")
  size=$(cat /sys/devices/system/cpu/$cpu/cache/index3/size 2>/dev/null || echo "N/A")
  die=$(cat /sys/devices/system/cpu/$cpu/topology/die_id 2>/dev/null || echo "N/A")
  echo "$cpu die=$die L3=$size"
done
```

Expected: CPUs on same die show same L3 size; CPUs on different dies may differ.

```bash
# Check all cache levels per CPU
cat /sys/devices/system/cpu/cpu0/cache/index3/type
cat /sys/devices/system/cpu/cpu0/cache/index3/size
cat /sys/devices/system/cpu/cpu0/cache/index3/level
```

---

## 4. Common Issues

| Symptom | Root cause | Fix |
|---------|------------|-----|
| All CPUs show 32MB (or uniform size) despite setting `l3-cache-size-die1=96M` | `-smp dies=2` not set, so topology has only 1 die. Per-die overrides for die 1+ are ignored with a warning. | Add `dies=2` (or matching count) to `-smp`. Example: `-smp 8,dies=2,cores=4,threads=1` |
| QEMU error: `Property 'l3-cache-size-die0' not found` | CPU model doesn't have the per-die properties. Only patched QEMU supports them. | Use custom dkvm-qemu build. Verify with `strings qemu-system-x86_64 \| grep l3-cache-size-die`. |
| QEMU error: `per-die L3 cache properties require l3-cache=on` | Set `l3-cache-size-die<N>` while `l3-cache=off` on the CPU model. | Remove `l3-cache=off`, or set `l3-cache=on`. Only some models allow `l3-cache=off` (e.g., EPYC-Turin has it on by default). |
| Warning: `l3-cache-size-die3: die index >= topology die count (2), ignoring` | Die index (3) exceeds dies in topology (2). Property is silently ignored. | Reduce die index or increase `-smp dies=N`. |
| No change with `-cpu host` (passthrough) | `-cpu host` alone doesn't accept per-die properties unless explicitly listed. Or per-die property is misspelled. | Use `-cpu host,l3-cache-size-die1=100663296`. Verify QEMU version supports passthrough per-die (patch 0008). |
| VM won't boot / hangs with per-die properties | Validation error during realize causes `x86_cpu_realizefn()` to fail. | Check QEMU stderr. Common: `-smp` topology inconsistent with properties. Run with `-d cpu_reset,guest_errors` to see details. |
| Guest sees uniform L3 despite correct host config | QEMU's CPUID encode isn't selecting per-die cache. Either patch 0007 missing, or `die_id` extraction wrong for the guest's APIC layout. | Verify binary includes patch 0007. Test with QMP `query-cpu-model-expansion`. Check `-d in_asm,cpu` log. |

---

## 5. Enable Verbose QEMU Logging

For CPUID and cache debugging, append `-d` flags:

```bash
# CPU reset + guest errors + in/out
-d cpu_reset,guest_errors,int

# All CPUID leaves encoded (verbose)
-d cpu

# Full instruction trace (check which CPUID leaf is called)
-d in_asm,cpu
```

Example debug run:

```bash
build/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 2,dies=2,cores=1,threads=1 \
  -machine pc -m 1G \
  -display none \
  -d cpu_reset,guest_errors \
  -D /tmp/qemu-debug.log \
  2>&1 | tee /tmp/qemu-stderr.log
```

Then grep the log:

```bash
grep -i "l3\|cache\|cpuid\|die" /tmp/qemu-debug.log /tmp/qemu-stderr.log
```

### QEMU trace-events (if compiled with `--enable-trace-backends`)

```bash
# List available trace events
build/out/qemu-system-x86_64 -trace help | grep -i cpuid

# Enable CPUID tracing
-d trace:cpuid_*
```

Note: Upstream QEMU doesn't have trace events for the per-die cache encode calls. For deep debugging, add `fprintf(stderr, ...)` or `trace_*` calls inside `encode_cache_cpuid*()` in `target/i386/cpu.c`.

---

## 6. Quick Iteration with Minimal Guest

For fast "does the guest see my L3 config?" validation, use a microvm or tiny Alpine image.

### Option A: microvm + direct kernel boot (fastest)

```bash
# Build a minimal kernel or use your host's /boot/vmlinuz
# microvm boots in <1 second
build/out/qemu-system-x86_64 \
  -machine microvm,acpi=off,rtc=off \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 2,dies=2,cores=1,threads=1 \
  -kernel /boot/vmlinuz-lts \
  -append "console=ttyS0 quiet" \
  -display none \
  -serial stdio
```

### Option B: Alpine ISO (no install needed)

```bash
# Download Alpine ISO
wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/alpine-virt-*.iso

boot/out/qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 2,dies=2,cores=1,threads=1 \
  -machine pc -m 1G \
  -cdrom alpine-virt-*.iso \
  -display none \
  -serial stdio
```

At the Alpine login prompt (`root` with no password), run:

```bash
# Install tools (in tmpfs, ephemeral)
apk add util-linux cpuid

# Check L3
lscpu -C
cpuid -1 | grep -A 10 "L3"
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  cpu=$(basename "$cpu")
  echo "$cpu: die=$(cat $cpu/topology/die_id) L3=$(cat $cpu/cache/index3/size)"
done
```

### Option C: Existing QMP-based test (no boot)

Use the test harness to verify QEMU accepts properties without booting a guest:

```bash
# From the project root
./dev-test.sh build/out/qemu-system-x86_64
```

See [How-to: Testing](testing.md) for details.

---

## 7. Debug Workflow Summary

```
Problem: guest shows uniform L3
│
├─ Check QEMU stderr for warnings/errors
│  └─ grep -i "l3\|cache\|die" (stderr)
│
├─ Verify properties via QMP query-cpu-model-expansion
│  └─ qmp_test with your exact -cpu arguments
│
├─ Confirm topology has multiple dies
│  └─ -smp dies=2 (or more)
│
├─ Verify patches applied
│  └─ strings qemu-system-x86_64 | grep l3-cache-size-die
│
├─ Run minimal guest (microvm or Alpine)
│  └─ lscpu -C, /sys cache files, cpuid -1
│
└─ Enable verbose QEMU logging (-d cpu_reset,guest_errors)
   └─ Check -D log for CPUID leaf encodings
```
