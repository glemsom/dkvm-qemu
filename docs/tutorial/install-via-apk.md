# Install DKVM QEMU via Alpine APK Repository

This tutorial walks through installing a pre-built DKVM QEMU package on Alpine Linux using the APK repository. By the end, you will have a working `qemu-system-x86_64` binary with per-die asymmetric L3 cache support and verify it boots a VM.

**Time required:** ~2 minutes  
**Prerequisites:** Alpine Linux (v3.23 or v3.24), internet connection, `root` or `sudo` access

---

## Step 1: Import the signing key

APK requires the repository's signing key to verify package integrity. Download and install it:

```bash
wget -O /etc/apk/keys/signkey.rsa.pub https://glemsom.github.io/dkvm-qemu/x86_64/signkey.rsa.pub
```

If `wget` is not installed, use `curl` instead:

```bash
curl -o /etc/apk/keys/signkey.rsa.pub https://glemsom.github.io/dkvm-qemu/x86_64/signkey.rsa.pub
```

**Verification:** Check the key was written correctly:

```bash
cat /etc/apk/keys/signkey.rsa.pub
```

Expected output: a PEM-formatted RSA public key (starts with `ssh-rsa AAAAB3...`).

### Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `wget: command not found` | `wget` not installed | Use `curl` instead, or `apk add wget` |
| `Permission denied` | Need root | Prepend `sudo` to the command |
| `No such file or directory` for `/etc/apk/keys/` | Directory missing (older Alpine) | `mkdir -p /etc/apk/keys` then retry |

## Step 2: Add the repository URL

Append the DKVM QEMU repository to Alpine's repository list:

```bash
echo "https://glemsom.github.io/dkvm-qemu/x86_64" >> /etc/apk/repositories
```

**Verification:** Confirm the line was added:

```bash
tail -1 /etc/apk/repositories
```

Expected output:
```
https://glemsom.github.io/dkvm-qemu/x86_64
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Permission denied` | Need root | Prepend `sudo` to the command |
| Duplicate lines in file | Ran the command multiple times | Edit `/etc/apk/repositories` and remove duplicates |

## Step 3: Install the packages

Update the APK index and install QEMU with x86_64 system emulation:

```bash
apk update
apk add qemu qemu-system-x86_64
```

`apk update` refreshes the package index from all configured repositories.  
`apk add qemu` installs the base QEMU package (common files, libraries).  
`apk add qemu-system-x86_64` installs the x86_64 system emulator binary (requires the packed-in per-die L3 patches).

For additional QEMU components, you can also install:
- `qemu-img` — disk image tools
- `qemu-modules` — all optional modules (GTK UI, SPICE, etc.)
- `qemu-hw-usb-host` — USB host passthrough module

But these are optional — the tutorial only needs `qemu` and `qemu-system-x86_64`.

**Verification:** Check the installed version:

```bash
qemu-system-x86_64 --version
```

Expected output (version may vary slightly):
```
QEMU emulator version 11.0.1
Copyright (c) 2003-2025 Fabrice Bellard and the QEMU Project developers
```

Now confirm per-die L3 properties are available:

```bash
qemu-system-x86_64 -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 -S -display none &
QEMU_PID=$!; sleep 1; kill $QEMU_PID 2>/dev/null
```

No error output means the properties are recognized. If you see `Property 'l3-cache-size-die0' not found`, the binary does not include the per-die patches.

### Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `ERROR: unable to select packages: ...` | Version conflict with other repos | Check Alpine version: `cat /etc/alpine-release`. DKVM repo requires v3.23+ |
| `WARNING: Integrity check: ...` | Wrong or missing signing key | Re-do Step 1 |
| `qemu-system-x86_64: command not found` | Package not installed | `apk list --installed | grep qemu` to verify |
| Property `l3-cache-size-die0` not found | Wrong CPU model or unpatched binary | `qemu-system-x86_64 -cpu help` — use `EPYC-Turin` or `EPYC-Genoa` |
| `Could not open 'bios-256k.bin'` | BIOS file missing | `apk add qemu-system-x86_64` already includes it; if persists, re-install |

## Step 4: Boot a test VM

Create a VM with asymmetric L3 cache — 2 dies, die0 with 32 MB L3 and die1 with 96 MB L3 (simulating a 9950X3D-like configuration):

```bash
# Create a minimal test disk if you don't have one
qemu-img create -f qcow2 test-disk.qcow2 4G

# Boot without a display (console-only)
qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 4,dies=2,cores=2,threads=1 \
  -m 2G \
  -drive file=test-disk.qcow2,format=qcow2 \
  -display none \
  -serial mon:stdio
```

This starts the VM in console mode. Press `Ctrl+A X` to exit QEMU.

If you have a bootable Alpine ISO, you can boot from it:

```bash
qemu-system-x86_64 \
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 4,dies=2,cores=2,threads=1 \
  -m 2G \
  -cdrom /path/to/alpine-virt-3.24-x86_64.iso \
  -drive file=test-disk.qcow2,format=qcow2 \
  -display none \
  -serial mon:stdio
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Could not open '...': No such file or directory` | Wrong path to disk/ISO | Use absolute path |
| `Could not open '...': Invalid argument` | Wrong image format | Use `qemu-img info` to check format |
| `KVM not available` | `/dev/kvm` missing | Run without KVM (it will be slower but works) |
| Guest shows uniform L3 on all dies | `-smp dies=N` mismatch | Ensure dies count matches number of `l3-cache-size-die<N>` properties |

## Step 5: Verify asymmetric L3 inside the guest

Once booted into a Linux guest, check the L3 cache topology:

```bash
# Show cache information per CPU
lscpu -C
```

Look for the L3 cache line — it should show different sizes per die. Example output for a 2-die, 2-core-per-die setup:

```
# NAME ONE-SIZE ALL-SIZE WAYS TYPE        LEVEL  SETS
# L1d       32K       64K    8 Data            1   64
# L1i       32K       64K    8 Instruction     1   64
# L2       512K        1M    8 Unified         2 1024
# L3       32M        64M   16 Unified         3 32768
```

Note: `lscpu -C` may show a single L3 size if the guest kernel does not expose per-die topology. For detailed CPUID inspection:

```bash
cpuid -1 | grep -A 10 "L3"
```

This shows the raw CPUID leaves — you will see different `l3-cache-size-die0` and `l3-cache-size-die1` values encoded in the topology leaves.

### Why this works

The per-die patches encode the L3 cache size into CPUID leaf 0x80000026 (extended topology enumeration) and override the cache topology so that each die reports its own L3 size. The host kernel and QEMU expose these values to the guest.

## What's next?

- [QEMU Flags](../howto/qemu-flags.md) — all CPU properties and flags
- [Simulate 9950X3D](../howto/simulate-9950x3d.md) — step-by-step 9950X3D VM configuration
- [Domain Glossary](../reference/glossary.md) — domain terminology
- [Architecture Decision Record](../adr/0001-per-die-asymmetric-l3-cache.md) — design rationale
- [README-repo.md](../../README-repo.md) — APK repo reference (CI/CD, structure)

## Comparison: APK install vs. build from source

| Aspect | APK install (this tutorial) | Build from source |
|--------|---------------------------|-------------------|
| Time | ~2 minutes | ~10-15 minutes |
| Prerequisites | Alpine Linux, internet | Docker, Git, 4 GB disk |
| Binary location | `/usr/bin/qemu-system-x86_64` | `build/out/qemu-system-x86_64` |
| Updates | `apk upgrade` | Re-run `./dev-build.sh` |
| Good for | Users who just want to run DKVM QEMU | Developers who want to modify patches |
