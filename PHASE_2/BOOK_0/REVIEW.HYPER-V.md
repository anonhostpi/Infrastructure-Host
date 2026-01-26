# Review: Hyper-V Module

## Nested Virtualization Support

**Context**: Multipass uses Hyper-V as its backend on Windows. Nested virtualization requires Hyper-V configuration that isn't exposed through Multipass CLI.

---

### Current State

- No `SDK.HyperV` module exists
- Multipass.ps1 has no nested virt support
- VMs created via Multipass cannot run nested VMs

---

### Hyper-V Commands for Nested Virt

```powershell
# Enable nested virt on a VM (must be stopped)
Set-VMProcessor -VMName "vm-name" -ExposeVirtualizationExtensions $true

# Disable dynamic memory (required for nested virt)
Set-VMMemory -VMName "vm-name" -DynamicMemoryEnabled $false

# Enable MAC address spoofing (required for nested networking)
Set-VMNetworkAdapter -VMName "vm-name" -MacAddressSpoofing On
```

---

### Potential SDK.HyperV Shape

```yaml
HyperV:
  Invoke: (...args) → ExecResult
  # VM Configuration
  SetProcessor: ($VMName, $Settings) → bool
  SetMemory: ($VMName, $Settings) → bool
  SetNetworkAdapter: ($VMName, $Settings) → bool
  # Nested Virt
  EnableNestedVirt: ($VMName) → bool
  DisableNestedVirt: ($VMName) → bool
```

---

### Integration with Multipass

Multipass VMs are managed by Hyper-V. The VM name in Hyper-V matches the Multipass instance name.

```powershell
# After multipass launch, enable nested virt
multipass stop my-vm
Set-VMProcessor -VMName "my-vm" -ExposeVirtualizationExtensions $true
multipass start my-vm
```

---

### Open Questions

1. Should HyperV module be standalone or integrated into Multipass?
2. How to handle the stop/configure/start dance cleanly?
3. Does Builder need nested virt for ISO building?
