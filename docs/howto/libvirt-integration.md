# How-to: Use Per-Die L3 Cache with libvirt

Configure a libvirt-managed QEMU VM to use per-die asymmetric L3 cache
properties (`l3-cache-size-die<N>`, `l3-cache-assoc-die<N>`).

---

## Prerequisites

- DKVM QEMU installed (custom build with per-die L3 patches)
- libvirt ≥ 8.0 (tested with 10.x; earlier versions may work)
- A libvirt domain definition (XML) you can edit via `virsh edit` or
  `virsh define`

---

## 1. libvirt Domain XML with Custom CPU Properties

libvirt has no native schema for per-die cache properties.
Two approaches work:

### Approach A: `<qemu:commandline>` (works on all libvirt versions)

Use the `<qemu:commandline>` namespace to pass extra `-cpu` arguments.

**Step 1: Add the QEMU namespace** to the `<domain>` element:

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

**Step 2: Define the CPU model** inside `<cpu>`:

```xml
<cpu mode='custom' match='exact'>
  <model fallback='forbid'>EPYC-Turin</model>
  <topology sockets='1' dies='2' cores='8' threads='1'/>
</cpu>
```

**Step 3: Append per-die properties** via `<qemu:commandline>`:

```xml
<qemu:commandline>
  <qemu:arg value='-cpu'/>
  <qemu:arg value='EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296'/>
</qemu:commandline>
```

> **Note**: The full `-cpu` string goes in one `<qemu:arg value='...'/>`.
> libvirt's `-cpu` in `<cpu>` is <u>not</u> used when you override via
> `<qemu:commandline>` — so set everything (model + topology + per-die props)
> in the single `<qemu:arg>`.

#### Full example domain XML

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>perdie-l3-demo</name>
  <memory unit='GiB'>4</memory>
  <vcpu placement='static'>16</vcpu>

  <cpu>
    <topology sockets='1' dies='2' cores='8' threads='1'/>
  </cpu>

  <qemu:commandline>
    <qemu:arg value='-cpu'/>
    <qemu:arg value='EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296'/>
  </qemu:commandline>

  <!-- ... rest of domain config: devices, disks, etc. ... -->
</domain>
```

### Approach B: `<feature policy='require' name='...'>` (limited)

libvirt allows passing arbitrary CPU feature flags via `<feature>` elements.
Per-die properties are <u>not</u> boolean features — they take size/integer
values. This approach only works if you set a single boolean-like property:

```xml
<cpu mode='custom' match='exact'>
  <model fallback='forbid'>EPYC-Turin</model>
  <topology sockets='1' dies='2' cores='8' threads='1'/>
  <feature policy='require' name='x-force-cpuid-0x80000026'/>
</cpu>
```

Per-die size properties like `l3-cache-size-die0` **cannot** be passed this
way because libvirt expects boolean on/off features. Use Approach A for
per-die properties.

---

## 2. Host Passthrough Mode

For `-cpu host` (passthrough) with per-die overrides:

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>perdie-l3-passthrough</name>
  <vcpu placement='static'>16</vcpu>

  <cpu mode='host-passthrough'>
    <topology sockets='1' dies='2' cores='8' threads='1'/>
  </cpu>

  <qemu:commandline>
    <qemu:arg value='-cpu'/>
    <qemu:arg value='host,l3-cache-size-die1=100663296'/>
  </qemu:commandline>
</domain>
```

This passthroughs the host CPU but overrides die 1's L3 to 96 MB.

---

## 3. Verify the Configuration

After defining the domain, check the actual QEMU command line:

```bash
# Show the generated QEMU command (without starting the VM)
virsh dumpxml perdie-l3-demo --xpath //qemu:commandline 2>/dev/null || \
  virsh qemu-monitor-command perdie-l3-demo '{"execute":"query-cpu-model-expansion","arguments":{"type":"static","model":{"name":"EPYC-Turin","props":{"l3-cache-size-die0":33554432,"l3-cache-size-die1":100663296}}}}'
```

Or start the VM and inspect inside the guest:

```bash
virsh start perdie-l3-demo
virsh console perdie-l3-demo
```

Inside guest, check L3 visibility:

```bash
lscpu -C
cat /sys/devices/system/cpu/cpu*/cache/index3/size | sort -u
```

See [Debug Per-Die L3](debug-per-die-l3.md) for full verification steps.

---

## 4. Current Limitations

| Limitation | Detail |
|------------|--------|
| **No native libvirt schema** | libvirt has no `<cache>` or per-die property elements as of libvirt 10.x. Must use `<qemu:commandline>`. |
| **No domain capabilities detection** | `virsh capabilities` will not advertise per-die properties. libvirt cannot auto-detect them. |
| **`-cpu` fully overridden** | Using `<qemu:commandline>` for `-cpu` means libvirt's `<cpu>` block only provides topology info; the full `-cpu` string must be self-contained. |
| **libvirt may strip unknown `<feature>` names** | Older libvirt versions (pre-9.0) strip or reject unrecognized feature flags. Use `<qemu:commandline>` if you hit this. |
| **No hotplug support** | Per-die properties are set at domain creation; cannot be changed on a running VM. |

---

## 5. Troubleshooting

### libvirt rejects domain XML

```
error: unsupported configuration: CPU ... not supported by hypervisor
```

**Fix**: Move the full `-cpu` string into `<qemu:commandline>`.
Remove `<model>` from `<cpu>` or keep only `<topology>`.

### libvirt ignores per-die properties

Check the actual QEMU command libvirt generates:

```bash
ps aux | grep qemu | grep -o '\-cpu [^ ]*'
```

If per-die arguments are missing, libvirt may have stripped them from
`<qemu:commandline>` if the namespace is wrong. Verify:

```bash
virsh dumpxml <domain> | grep -i 'xmlns:qemu'
```

Must show `http://libvirt.org/schemas/domain/qemu/1.0`.

### Guest shows uniform L3 size

Same root causes as standalone QEMU — most commonly `dies=N` missing from
`<topology>` or `-smp`. Ensure `<topology dies='2'>` matches your per-die
property indices.

### libvirt 8.x / 9.x workaround

These versions may require the `-cpu` flag in a single arg without spaces:

```xml
<qemu:commandline>
  <qemu:arg value='-cpu'/>
  <qemu:arg value='EPYC-Turin,l3-cache-size-die0=33554432,l3-cache-size-die1=100663296'/>
</qemu:commandline>
```

Do **not** split per-die properties across multiple `<qemu:arg>` elements.

---

## Related

- [QEMU Flags](qemu-flags.md) — all CPU properties and flags
- [CPU Properties](../reference/cpu-properties.md) — custom CPU property reference
- [Simulate 9950X3D](simulate-9950x3d.md) — step-by-step 9950X3D VM configuration
- [Debug Per-Die L3](debug-per-die-l3.md) — troubleshooting guide
- [ADR-0001](../adr/0001-per-die-asymmetric-l3-cache.md) — design decision record
