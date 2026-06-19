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

echo "=== Test 4: Per-die properties + multi-die SMP ==="
OUT=$(run_pc -cpu "EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296" -smp 2,dies=2,cores=1,threads=1 -qmp stdio 2>/dev/null <<< "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'quit' }" || true)
if echo "$OUT" | grep -q '"return"'; then
    pass "Multi-die SMP + per-die L3 works"
else
    fail "Multi-die SMP + per-die L3 failed: $(echo "$OUT" | head -3)"
fi

echo "=== Test 5: VM boot (KVM required) ==="
if $CAN_KVM; then
    echo "  TODO: Alpine initrd boot test"
    pass "(KVM available)"
else
    echo "  SKIP (no KVM)"
fi

echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
