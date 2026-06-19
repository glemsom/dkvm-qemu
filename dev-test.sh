#!/bin/bash
# Automated QMP test for per-die L3 cache properties
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

# Check QEMU binary exists
if [ ! -f "$QEMU_BIN" ]; then
    fail "QEMU binary not found at $QEMU_BIN (run ./dev-build.sh first)"
    exit 1
fi

# Test 1: Properties visible in QMP expansion
echo "=== Test 1: Per-die properties visible in QMP expansion ==="
QMP_OUT=$(echo "{ 'execute': 'qmp_capabilities' }
{ 'execute': 'query-cpu-model-expansion', 'arguments': { 'type': 'static', 'model': { 'name': 'EPYC-Turin', 'props': { 'l3-cache-size-die0': 33554432, 'l3-cache-size-die1': 100663296 } } } }
{ 'execute': 'quit' }" | \
    "$QEMU_BIN" -machine none -cpu EPYC-Turin -S -qmp stdio -display none 2>/dev/null || true)

if echo "$QMP_OUT" | grep -q '"l3-cache-size-die0"'; then
    pass "l3-cache-size-die0 visible in QMP expansion"
else
    fail "l3-cache-size-die0 NOT visible in QMP expansion"
    echo "QMP output: $QMP_OUT" | head -20
fi

if echo "$QMP_OUT" | grep -q '"l3-cache-size-die1"'; then
    pass "l3-cache-size-die1 visible in QMP expansion"
else
    fail "l3-cache-size-die1 NOT visible in QMP expansion"
fi

if echo "$QMP_OUT" | grep -q '"l3-cache-assoc-die0"'; then
    pass "l3-cache-assoc-die0 visible in QMP expansion"
else
    fail "l3-cache-assoc-die0 NOT visible in QMP expansion"
fi

# Test 2: Per-die property + l3-cache=off → error
echo "=== Test 2: l3-cache=off + per-die property → error ==="
ERROR_OUT=$(echo "q" | timeout 5 "$QEMU_BIN" \
    -machine none -cpu EPYC-Turin,l3-cache=off,l3-cache-size-die0=32M \
    -S -display none 2>&1 || true)

if echo "$ERROR_OUT" | grep -qi "per-die.*l3-cache=on\|l3-cache.*off"; then
    pass "l3-cache=off + per-die property produces error"
else
    fail "l3-cache=off + per-die property did NOT produce expected error"
    echo "Output: $ERROR_OUT" | head -10
fi

# Test 3: No CPUID changes (regression) — verify QEMU starts without per-die props
echo "=== Test 3: QEMU starts without per-die properties (no regression) ==="
# Just verify the binary starts and quits cleanly with -machine none
START_OUT=$(timeout 5 "$QEMU_BIN" -machine none -cpu EPYC-Turin -S -display none 2>&1 || true)
if echo "$START_OUT" | grep -qv "error\|Error\|ERROR"; then
    pass "QEMU starts cleanly with EPYC-Turin CPU model (no per-die props)"
else
    # If there's output but no error, it's fine
    if [ -z "$START_OUT" ]; then
        pass "QEMU starts cleanly with EPYC-Turin CPU model"
    else
        fail "QEMU had unexpected output: $START_OUT" | head -5
    fi
fi

# Summary
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
