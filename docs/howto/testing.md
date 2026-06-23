# How-to: Building and Running Tests

This guide covers running the DKVM QEMU test suite, interpreting results, and adding new tests.

---

## Quick test

```bash
./dev-test.sh build/out/qemu-system-x86_64
```

Expected output:

```
=== Test 1: QMP — query-cpu-model-expansion with per-die properties ===
PASS: Model expansion with per-die props succeeds
=== Test 2: l3-cache=off + per-die property → error ===
PASS: l3-cache=off + per-die property produces error
...
=== Results: 10 passed, 0 failed ===
```

If the binary is at a different path, pass it as argument:

```bash
./dev-test.sh /path/to/qemu-system-x86_64
```

Default path is `build/out/qemu-system-x86_64` (output of `./dev-build.sh`).

---

## What tests cover

The suite has 10 numbered test cases across two modes (model and passthrough):

| # | Test | Mode | What it checks |
|---|------|------|----------------|
| 1 | QMP — `query-cpu-model-expansion` with per-die properties | model | EPYC-Turin with `l3-cache-size-die0` + `die1` succeeds via QMP |
| 2 | `l3-cache=off` + per-die property | model | Error expected: per-die requires `l3-cache=on` |
| 3 | No per-die properties (regression) | model | EPYC-Turin without per-die props still expands OK |
| 4 | Per-die properties + multi-die SMP | model | `-cpu` plus `-smp 2,dies=2` works at QMP level |
| 5 | VM boot (KVM required) | model | Placeholder for full VM boot test; passes if KVM available |
| 6 | Passthrough + per-die properties | passthrough | `host-cache-info=on` + per-die property via QMP |
| 7 | Passthrough + `l3-cache=off` + per-die property | passthrough | Error expected: same constraint as test 2 |
| 8 | Passthrough + multi-die SMP | passthrough | `host-cache-info=on` with `-smp 4,dies=2` |
| 9 | Passthrough without per-die properties (regression) | passthrough | Pure host passthrough still works |
| 10a | Passthrough VM boot with per-die L3 | passthrough | `-cpu host,l3-cache-size-die1=...` boots (QMP probe) |
| 10b | Passthrough VM boot without per-die L3 | passthrough | `-cpu host` boots clean (regression check) |

Tests 1–4, 6–9 use QMP (`-machine none`) and do not need BIOS or KVM.
Tests 4, 8 use `-machine pc` and need `bios-256k.bin`.
Tests 5, 10 use `-machine pc` and need both BIOS and KVM.

---

## Running individual test cases

The test script runs all tests sequentially. To run a single test:

### By test number

Extract the test body from `dev-test.sh` and run it directly. For example, test 1:

```bash
QEMU_BIN="build/out/qemu-system-x86_64"
echo "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'static', 'model': { 'name': 'EPYC-Turin', 'props': { 'l3-cache-size-die0': 33554432, 'l3-cache-size-die1': 100663296 } } } }
{ 'execute': 'quit' }" | timeout 15 "$QEMU_BIN" -machine none -S -display none -qmp stdio 2>/dev/null
```

### By grep pattern

Tests output a banner line (`=== Test N: ... ===`). Run the full suite and pipe to filter:

```bash
./dev-test.sh | grep -A 5 "Passthrough"
```

Or use `sed` to extract a numbered block:

```bash
./dev-test.sh | sed -n '/^=== Test 4/,/^=== Test /p' | head -n -1
```

### With modified flags

Set `QEMU_BIN` inline for a one-off run using the helper functions from `dev-test.sh`:

```bash
# Source helpers, then call qmp_test or run_pc directly
source dev-test.sh  # reuse helper functions
qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'quit' }"
```

---

## Test prerequisites

### `bios-256k.bin`

Tests using `-machine pc` (tests 4, 8, and 10) need a BIOS file. The script auto-detects it from:

- `/usr/local/share/qemu/bios-256k.bin`
- `/usr/share/qemu/bios-256k.bin`
- `$QEMU_BIN/../pc-bios/bios-256k.bin`
- `./pc-bios/bios-256k.bin`

If none found, those tests produce opaque failures ("Could not open 'bios-256k.bin'"). Fix:

```bash
# Find BIOS on your system
find /usr -name 'bios-256k.bin' 2>/dev/null

# Or install SeaBIOS
# Debian/Ubuntu: sudo apt install seabios
# Fedora:         sudo dnf install seabios

# Then copy or symlink to build/pc-bios/
cp /usr/share/seabios/bios-256k.bin build/pc-bios/
```

### `/dev/kvm` availability

Tests 5 and 10 need `/dev/kvm` (passthrough mode). The script checks:

```bash
[ -c /dev/kvm ] && [ -r /dev/kvm ] && CAN_KVM=true
```

Without KVM these tests print `SKIP (no KVM)` — not a failure. The QMP-only tests (1–4, 6–9) always run.

To enable KVM:

```bash
# Check virtualization support
grep -E '(vmx|svm)' /proc/cpuinfo

# Load module
sudo modprobe kvm        # plus kvm_amd or kvm_intel matching your CPU

# Verify device
ls -l /dev/kvm           # should show crw-rw----  root kvm
```

### QEMU binary

The binary must exist at the given path. If missing:

```
FAIL: QEMU binary not found at build/out/qemu-system-x86_64 (run ./dev-build.sh first)
```

Build it first:

```bash
./dev-build.sh
```

---

## Interpreting test output

### PASS/FAIL meaning

| Outcome | Meaning |
|---------|---------|
| `PASS: ...` | Test condition met — expected success or expected error occurred |
| `FAIL: ...` | Test condition not met — expected success failed, or expected error did not appear |
| `SKIP` | Test skipped due to missing prerequisite (KVM), not a failure |

### Where to look for errors

On failure, the test prints the first 3 lines of QEMU's output:

```bash
# In the test script:
fail "Model expansion failed: $(echo "$OUT" | head -3)"
```

Common failure modes:

| Symptom | Likely cause |
|---------|--------------|
| `Could not open 'bios-256k.bin'` | Missing BIOS file |
| `Property 'l3-cache-size-die0' not found` | CPU model doesn't support per-die L3 |
| `unable to open /dev/kvm` | KVM not accessible |
| `"return" not found in QMP output` | QEMU crash or protocol mismatch |
| `per-die.*l3-cache=on` not matched | Error message changed — check QEMU source |

For detailed debugging, capture full QEMU output by running the QEMU command manually (see [Debugging a failing test](#debugging-a-failing-test)).

---

## Adding new tests

### Test structure

Each test in `dev-test.sh` follows a pattern:

```bash
echo "=== Test N: Description ==="
OUT=$(some_qemu_invocation)
if echo "$OUT" | grep -q "expected_criteria"; then
    pass "Description passes"
else
    fail "Description failed: $(echo "$OUT" | head -3)"
fi
```

Two helper functions are provided:

| Helper | QEMU flags | When to use |
|--------|------------|-------------|
| `qmp_test()` | `-machine none -S -display none -qmp stdio` | QMP protocol tests, no BIOS needed |
| `run_pc()` | `-machine pc -bios ... -S -display none` | Boot or CPU-creation tests, needs BIOS |

Both capture stderr (`2>&1` or `/dev/null` depending on test) and apply a 15-second timeout.

### Conventions

- Increment the test number sequentially
- Print a banner: `echo "=== Test N: Description ==="`
- Use `PASS`/`FAIL` counters via the `pass()` and `fail()` functions
- Add to the results count at bottom: `$PASS passed, $FAIL failed`
- If a test depends on KVM, gate it with `if $CAN_KVM; then ... else echo "SKIP"; fi`

### What's worth testing

Good test candidates for the per-die L3 feature:

- **Each user-facing property** — `l3-cache-size-die<N>` (N=0..7), `l3-cache-assoc-die<N>`
- **Validation edges** — N < 0, N > 7, non-die indices, mixed size/assoc, negative/zero sizes
- **Topology combos** — 1 die, 2 dies, 8 dies; different core/thread counts per die
- **Passthrough intersections** — `host-cache-info=on` + `l3-cache-size-die` with various `-cpu host` combinations
- **CPUID enumeration** — verify that `CPUID[4]`, `0x80000006`, `0x8000001D` all report the overridden values
- **Guest-visible verification** — boot a tiny initrd and run `cpuid`/`lscpu` inside

See [prior art in the test script](../dev-test.sh) and refer to [ADR-0001](adr/0001-per-die-asymmetric-l3-cache.md) for design constraints.

---

## Testing passthrough vs model mode

The test suite covers both modes. The distinction:

| Mode | `-cpu` pattern | Property source | Tests |
|------|----------------|-----------------|-------|
| **Model** | `-cpu EPYC-Turin,...` | QEMU built-in model definition, overridden by per-die props | 1–5 |
| **Passthrough** | `-cpu host,...` or `-cpu EPYC-Turin,host-cache-info=on,...` | Host CPU data from KVM, overridden by per-die props | 6–10 |

To test only model mode:

```bash
# Run tests 1–5 by commenting out tests 6+ in dev-test.sh
# Or extract test 1–4 logic and run manually
```

To test only passthrough mode (requires KVM):

```bash
# Tests 6–10
```

When adding a new feature or property, always write **two tests** — one for model mode via QMP and one for passthrough mode — to ensure both paths through `encode_cache_cpuid()` work correctly.

---

## Debugging a failing test

### 1. Extract the QEMU command

Each test constructs a QEMU invocation. Find it in `dev-test.sh` and copy the exact command. For example, test 4:

```bash
# From dev-test.sh, test 4:
# run_pc -cpu "EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296" \
#   -smp 2,dies=2,cores=1,threads=1 -qmp stdio
```

The `run_pc` function resolves to:

```bash
timeout 15 build/out/qemu-system-x86_64 \
  -machine pc -bios /path/to/bios-256k.bin \
  -S -display none \
  -cpu "EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296" \
  -smp 2,dies=2,cores=1,threads=1 -qmp stdio 2>&1
```

### 2. Run the command manually

Drop the `timeout` and `2>&1` for full interactive output:

```bash
build/out/qemu-system-x86_64 \
  -machine pc -bios /path/to/bios-256k.bin \
  -S -display none \
  -cpu "EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296" \
  -smp 2,dies=2,cores=1,threads=1 \
  -qmp stdio
```

### 3. Add verbose flags

Append debugging flags to the manual run:

```bash
# Enable QEMU tracing for CPU properties
-d cpu_reset,guest_errors,int
```

### 4. Isolate the failure

| Test type | Debug technique |
|-----------|----------------|
| QMP protocol test | Remove `2>/dev/null` to see all QEMU stderr. Send QMP commands interactively. |
| Error-expect test | Run without the offending property to confirm baseline works, then add it back. |
| Passthrough test | Check `dmesg` for KVM errors. Try `-accel tcg` instead of KVM to isolate hardware issues. |
| Multi-die SMP test | Start with 1 die, then increase. Verify `-smp` syntax is correct. |

### 5. Verify the binary

Confirm the binary is the right build and has patches applied:

```bash
# Check binary exists and is executable
file build/out/qemu-system-x86_64

# Verify patch content is present by looking for per-die symbols
strings build/out/qemu-system-x86_64 | grep l3-cache-size-die

# Check version
build/out/qemu-system-x86_64 --version
```
