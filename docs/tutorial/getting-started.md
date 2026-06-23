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

- [QEMU Flags](../howto/qemu-flags.md) — all CPU properties and flags
- [Simulate 9950X3D](../howto/simulate-9950x3d.md) — step-by-step 9950X3D VM configuration
- [Domain Glossary](../reference/glossary.md) — domain terminology
- [Architecture Decision Record](../adr/0001-per-die-asymmetric-l3-cache.md) — why things are designed this way
- [Contributing](../CONTRIBUTING.md) — how to submit patches

## Troubleshooting

### `dev-build.sh` fails with Docker errors

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `docker: command not found` | Docker not installed | [Install Docker](https://docs.docker.com/engine/install/) |
| `Cannot connect to the Docker daemon` | Docker daemon not running | `sudo systemctl start docker` (Linux) or start Docker Desktop (macOS/Windows) |
| `permission denied while trying to connect` | User not in `docker` group | `sudo usermod -aG docker $USER && newgrp docker` |
| `no space left on device` | Docker cache filled up | `docker system prune -af` |

### Build fails with patch application errors

**Symptom:** `error: patch failed: ... Patch does not apply` or `hunk #1 FAILED`

**Cause:** Wrong QEMU version or stale patches directory.

**Fix:**

1. Verify the patches target QEMU 11.0.1:

   ```bash
   head -20 patches/series
   ```

2. Confirm your local clone matches the upstream tag:

   ```bash
   git describe --tags
   # Expected: something based on qemu-11.0.1
   ```

3. Regenerate the Docker build image so it fetches a fresh QEMU source:

   ```bash
   docker build --no-cache -t qemu-dev-builder .
   ```

4. Re-run `./dev-build.sh`.

### Test suite fails

#### Missing `bios-256k.bin`

**Symptom:** `Could not open 'bios-256k.bin': No such file or directory`

**Cause:** QEMU cannot find the BIOS file required for boot tests.

**Fix:**

*Option A — locate the BIOS shipped with your system QEMU:*

```bash
find /usr -name 'bios-256k.bin' 2>/dev/null
```

Then pass its directory via `-L` or copy it into `build/pc-bios/`.

*Option B — install SeaBIOS:*

```bash
# Debian/Ubuntu
sudo apt install seabios
# Fedora
sudo dnf install seabios
# Arch
sudo pacman -S seabios
```

After install, symlink or copy `/usr/share/seabios/bios-256k.bin` → `build/pc-bios/bios-256k.bin`.

#### KVM not available

**Symptom:** `failed to find KVM device: No such file or directory` or tests skip KVM-dependent tests.

**Cause:** `/dev/kvm` does not exist or is not accessible.

**Fix:**

- Check if hardware virtualization is enabled: `grep -E '(vmx|svm)' /proc/cpuinfo`
- Load the KVM module: `sudo modprobe kvm` (plus `kvm_amd` or `kvm_intel` matching your CPU)
- Verify `/dev/kvm` exists and is readable: `ls -l /dev/kvm`
- Tests run without KVM too; they just skip passthrough tests. Non-KVM QMP tests still pass.

#### Specific test failures — what they mean

| Test name | Failure meaning |
|-----------|----------------|
| `QMP — query-cpu-model-expansion with per-die properties` | QEMU binary missing per-die L3 cache support. Rebuild. |
| `l3-cache=off + per-die property → error` | Expected error missing — check CPU property registration. |
| `Multi-die SMP boot with per-die L3 (model)` | Guest boot failed in model expansion mode. Check CPU model name. |
| `Multi-die SMP boot with per-die L3 (passthrough)` | Passthrough boot failure — see KVM section above. |
| `Regression: no per-die properties → uniform L3` | Per-die props leaking when not requested — bug in property logic. |
| `KVM passthrough boot` | Test skipped (not a failure) when KVM unavailable. |

### VM boot fails

#### `Could not open disk image`

**Symptom:** `Could not open '...': No such file or directory` or `Invalid argument`

**Cause:** Wrong path or image format.

**Fix:**

- Verify the file exists: `ls -la /path/to/disk.qcow2`
- Ensure it is a qcow2 image: `qemu-img info /path/to/disk.qcow2` (install `qemu-img` if missing)
- Use an absolute or correct relative path
- If you need a test disk: `qemu-img create -f qcow2 test-disk.qcow2 4G`

#### Guest does not show asymmetric L3

**Symptom:** `lscpu -e` shows identical L3 cache sizes across all dies, or the expected per-die values are not visible.

**Cause:** `-smp dies=N` does not match per-die property indices.

**Fix:**

- Ensure `-smp` dies count matches the number of `l3-cache-size-die<N>` properties provided.
- Example for 2 dies:

  ```bash
  -cpu EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296 \
  -smp 16,dies=2,cores=8,threads=1
  ```

- Die indices are zero-based: `die0`, `die1`, …, `dieN-1`.

#### `l3-cache-size-die0: Property not found`

**Symptom:** `Property 'l3-cache-size-die0' not found`

**Cause:** Selected CPU model does not support per-die L3 properties.

**Fix:**

- Use one of the supported models: `EPYC-Turin` (recommended for testing) or a model with explicit patch-level L3 support.
- Check available CPU models: `./build/out/qemu-system-x86_64 -cpu help`

### How to get help

If none of the above solves your issue:

- **File an issue** at [github.com/glemsom/dkvm-qemu/issues](https://github.com/glemsom/dkvm-qemu/issues)
- **Include** the exact error output (paste the full terminal session)
- **Include** the output of:

  ```bash
  ls -la build/out/qemu-system-x86_64
  ./dev-test.sh build/out/qemu-system-x86_64 2>&1 | tail -50
  grep . /proc/cpuinfo 2>/dev/null | head -5
  ls -la /dev/kvm 2>/dev/null
  docker --version
  ```
