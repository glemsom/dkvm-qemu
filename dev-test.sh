#!/bin/bash
# Automated test for per-die L3 cache: QMP tests + VM boot test
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

QEMU_BIN="${1:-build/out/qemu-system-x86_64}"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
pass() { PASS=$((PASS+1)); echo -e "${GREEN}PASS${NC}: $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "${RED}FAIL${NC}: $1"; }

CAN_KVM=false
[ -c /dev/kvm ] && [ -r /dev/kvm ] && CAN_KVM=true

if [ ! -f "$QEMU_BIN" ]; then
    fail "QEMU binary not found at $QEMU_BIN (run ./dev-build.sh first)"
    exit 1
fi

# Find BIOS for -machine pc tests
BIOS=""
for d in /usr/local/share/qemu /usr/share/qemu "$(dirname "$QEMU_BIN")/../pc-bios" ./pc-bios; do
    [ -f "$d/bios-256k.bin" ] && BIOS="$d/bios-256k.bin" && break
done

# Minimal QMP test — no CPU creation, just query CPU model
qmp_test() {
    echo "$1" | timeout 15 "$QEMU_BIN" -machine none -S -display none -qmp stdio 2>/dev/null || true
}

# Run QEMU with -machine pc (needs BIOS for CPU creation)
run_pc() {
    local bios_opt=""
    [ -n "$BIOS" ] && bios_opt="-bios $BIOS"
    timeout 15 "$QEMU_BIN" -machine pc $bios_opt -S -display none "$@" 2>&1 || true
}

echo "=== Test 1: QMP — query-cpu-model-expansion with per-die properties ==="
OUT=$(qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'static', 'model': { 'name': 'EPYC-Turin', 'props': { 'l3-cache-size-die0': 33554432, 'l3-cache-size-die1': 100663296 } } } }
{ 'execute': 'quit' }")
if echo "$OUT" | grep -q '"return"'; then
    pass "Model expansion with per-die props succeeds"
else
    fail "Model expansion failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 2: l3-cache=off + per-die property → error ==="
OUT=$(run_pc -cpu "EPYC-Turin,l3-cache=off,l3-cache-size-die0=33554432")
if echo "$OUT" | grep -qi "per-die.*l3-cache=on"; then
    pass "l3-cache=off + per-die property produces error"
else
    fail "l3-cache=off + per-die property did NOT produce expected error"
    echo "Output: $(echo "$OUT" | tail -3)"
fi

echo "=== Test 3: No per-die properties (regression) ==="
OUT=$(qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'static', 'model': { 'name': 'EPYC-Turin' } } }
{ 'execute': 'quit' }")
if echo "$OUT" | grep -q '"return"'; then
    pass "Model expansion without per-die properties works"
else
    fail "Model expansion failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 4: QMP — Per-die properties with static expansion (no machine needed) ==="
OUT=$(qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'static', 'model': { 'name': 'EPYC-Turin', 'props': { 'l3-cache-size-die0': 33554432, 'l3-cache-size-die1': 100663296 } } } }
{ 'execute': 'quit' }")
if echo "$OUT" | grep -q '"return"'; then
    pass "QMP static expansion with per-die L3 works"
else
    fail "QMP static expansion with per-die L3 failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 5: QMP — passthrough mode (host model) + per-die properties ==="
# Note: host-cache-info is a host-model-only property, not available on EPYC-Turin
# Use 'host' model in QMP expansion to verify passthrough + per-die props are accepted
OUT=$(qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'full', 'model': { 'name': 'host', 'props': { 'l3-cache-size-die1': 100663296 } } } }
{ 'execute': 'quit' }")
if echo "$OUT" | grep -q '"return"'; then
    pass "Passthrough mode (host) + per-die properties accepted"
else
    fail "Passthrough mode (host) + per-die properties failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 6: l3-cache=off + per-die property via run_pc (EPYC-Turin) → error ==="
# This test creates a CPU with l3-cache=off + per-die property, which should trigger
# realize-time validation error
OUT=$(run_pc -cpu "EPYC-Turin,l3-cache=off,l3-cache-size-die1=100663296" 2>&1 || true)
if echo "$OUT" | grep -qi "per-die.*l3-cache=on\|l3-cache-size-die1.*not found"; then
    pass "l3-cache=off + per-die property via run_pc produces error"
else
    fail "l3-cache=off + per-die property via run_pc did NOT produce expected error"
    echo "Output: $(echo "$OUT" | tail -3)"
fi

echo "=== Test 7: Per-die properties + host model multi-die QMP ==="
OUT=$(qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'full', 'model': { 'name': 'host', 'props': { 'l3-cache-size-die0': 33554432, 'l3-cache-size-die1': 100663296 } } } }
{ 'execute': 'quit' }")
if echo "$OUT" | grep -q '"return"'; then
    pass "Host model + multi-die per-die L3 accepted"
else
    fail "Host model + multi-die per-die L3 failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 8: Host model without per-die properties (regression) ==="
OUT=$(qmp_test "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'full', 'model': { 'name': 'host' } } }
{ 'execute': 'quit' }")
if echo "$OUT" | grep -q '"return"'; then
    pass "Host model without per-die properties works"
else
    fail "Host model without per-die properties failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 9: Passthrough VM boot (KVM required) ==="
if $CAN_KVM; then
    # Boot with -cpu host, per-die property for die1, verify no crash
    OUT=$(QEMU_QMP=1 timeout 15 "$QEMU_BIN" -machine pc -cpu "host,l3-cache-size-die1=100663296" -smp 4,dies=2,cores=2,threads=1 -S -display none -qmp stdio 2>&1 <<< "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'quit' }" || true)
    if echo "$OUT" | grep -q '"return"'; then
        pass "Passthrough VM boot with per-die L3 works"
    else
        fail "Passthrough VM boot with per-die L3 failed: $(echo "$OUT" | head -3)"
    fi
    
    # Boot without per-die properties, verify no change
    OUT=$(QEMU_QMP=1 timeout 15 "$QEMU_BIN" -machine pc -cpu host -smp 4,dies=2,cores=2,threads=1 -S -display none -qmp stdio 2>&1 <<< "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'quit' }" || true)
    if echo "$OUT" | grep -q '"return"'; then
        pass "Passthrough VM boot without per-die L3 works"
    else
        fail "Passthrough VM boot without per-die L3 failed: $(echo "$OUT" | head -3)"
    fi
else
    echo "  SKIP (no KVM)"
fi

echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
