# Research: SDK.HyperV Module

## Context

The codebase has two VM management modules — `Vbox.ps1` (VBoxManage CLI) and `Multipass.ps1` (multipass CLI). Both follow the same architecture: `$mod.Configurator` + `$mod.Worker` + main object with methods. HyperV.ps1 should replicate Vbox.ps1's structure as closely as possible.

Key difference: Hyper-V has no single CLI to wrap. Instead of an `Invoke` method, each method uses PowerShell cmdlets from `Import-Module Hyper-V`.

---

## Architecture: Vbox.ps1 → HyperV.ps1 Mapping

### Module Setup

```
Vbox.ps1                          HyperV.ps1
─────────                         ──────────
. PowerShell.ps1                  . PowerShell.ps1
                                  Import-Module Hyper-V
$mod.Configurator.Defaults        $mod.Configurator.Defaults
$mod.Worker.Properties            $mod.Worker.Properties
$mod.Worker.Methods               $mod.Worker.Methods
$Vbox = New-Object PSObject       $HyperV = New-Object PSObject
Add-ScriptMethods ...             Add-ScriptMethods ...
$SDK.Extend("Vbox", $Vbox)       $SDK.Extend("HyperV", $HyperV)
```

### $mod.Configurator.Defaults

```powershell
# Vbox (memory in MB, disk in MB)
@{ CPUs = 2; Memory = 4096; Disk = 40960; SSHUser = $null; SSHHost = $null; SSHPort = 22 }

# HyperV (memory in bytes for Set-VMMemory, disk in bytes for New-VHD)
@{ CPUs = 2; MemoryMB = 4096; DiskGB = 40; SSHUser = $null; SSHHost = $null; SSHPort = 22; Generation = 2 }
```

### $mod.Worker.Properties

Same pattern as Vbox — `Rendered`, `Name`, `CPUs`, `Memory`, `Disk`, `SSHUser`, `SSHHost`, `SSHPort`. The `Rendered` property merges config with defaults and derives SSH settings from config files.

### $mod.Worker.Methods

Same delegation pattern — each method calls `$mod.SDK.HyperV.<Method>($this.Name, ...)`.

---

## Method Mapping: Vbox → HyperV

### Replaced: Invoke

Vbox wraps `VBoxManage.exe`. HyperV has no equivalent — each method calls cmdlets directly.

```powershell
# Vbox
$this.Invoke("list", "vms")

# HyperV — no Invoke, call cmdlets directly
Get-VM
```

### Worker Factory

Identical pattern to Vbox — takes a `$Base` object, adds properties/methods, calls `$mod.SDK.Worker.Methods()`.

### Network: GetGuestAdapter → GetSwitch

```powershell
# Vbox: maps host adapter to VBox bridge interface name
$this.Invoke("list", "bridgedifs")

# HyperV: finds a VMSwitch by name or type
Get-VMSwitch -Name $SwitchName
Get-VMSwitch -SwitchType External
```

### Medium Helpers: Drives

```powershell
# Vbox: parses machinereadable output for SATA/IDE entries
$this.Invoke("showvminfo", $VMName, "--machinereadable")

# HyperV: structured cmdlet output
$hdds = Get-VMHardDiskDrive -VMName $VMName
$dvds = Get-VMDvdDrive -VMName $VMName
```

Returns array of `@{ Controller; Port; Path; IsDVD }` for compatibility.

### Storage: Attach, Give, Delete

```powershell
# Vbox                                    # HyperV
$this.Invoke("storageattach", ...)        Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath
$this.Invoke("createmedium", ...)         New-VHD -Path $VHDPath -SizeBytes $Size -Dynamic
$this.Invoke("closemedium", ...)          Remove-VMHardDiskDrive ...; Remove-Item $VHDPath
```

### DVD: Eject, Insert

```powershell
# Vbox                                    # HyperV
# Eject: set medium to "emptydrive"       Set-VMDvdDrive -VMName $VMName -Path $null
# Insert: storageattach with dvddrive     Add-VMDvdDrive -VMName $VMName -Path $ISOPath
#   or                                    #   or if drive exists:
#                                         Set-VMDvdDrive -VMName $VMName -Path $ISOPath
```

### Lifecycle: Exists, Running, Pause, Resume, Bump, Start, Shutdown, UntilShutdown

```powershell
# Vbox                                    # HyperV
$this.Invoke("list", "vms")               $null -ne (Get-VM -Name $VMName -EA SilentlyContinue)
$this.Invoke("list", "runningvms")        (Get-VM -Name $VMName).State -eq 'Running'
$this.Invoke("controlvm", $n, "pause")    Suspend-VM -Name $VMName
$this.Invoke("controlvm", $n, "resume")   Resume-VM -Name $VMName
# Bump = Pause + sleep + Resume           # Same logic
$this.Invoke("startvm", $n, ...)          Start-VM -Name $VMName
$this.Invoke("controlvm", $n, "poweroff") Stop-VM -Name $VMName -Force
$this.Invoke("controlvm", ..., "acpi...")  Stop-VM -Name $VMName (graceful by default)
# UntilShutdown: $mod.SDK.Job({...})      # Same Job pattern
```

### Configuration: Configure, Optimize, Hypervisor

```powershell
# Vbox: single VBoxManage modifyvm with key-value pairs
# HyperV: separate cmdlets per subsystem

# Configure — dispatch to appropriate Set-VM* cmdlet per setting
# Optimize — Generation 2 settings, integration services
# Hypervisor (key use case from postponed doc):
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
Set-VMNetworkAdapter -VMName $VMName -MacAddressSpoofing On
```

### Creation/Destruction: Create, Destroy

```powershell
# HyperV Create:
New-VM -Name $VMName -MemoryStartupBytes $RAM -Generation $Gen -NewVHDPath $VHDPath -NewVHDSizeBytes $Disk
Set-VMProcessor -VMName $VMName -Count $CPUs
# Attach network switch
Connect-VMNetworkAdapter -VMName $VMName -SwitchName $Switch
# Optional: add DVD
Add-VMDvdDrive -VMName $VMName -Path $ISOPath

# HyperV Destroy:
Stop-VM -Name $VMName -Force -TurnOff  (if running)
$drives = Get-VMHardDiskDrive -VMName $VMName
Remove-VM -Name $VMName -Force
foreach ($d in $drives) { Remove-Item $d.Path -Force }
```

---

## Method Inventory

Methods HyperV.ps1 should have, mapped from Vbox.ps1:

### Shared API Surface

Both Vbox and HyperV expose these methods with the same names:

| # | Method | Vbox Implementation | HyperV Implementation |
|---|--------|--------------------|-----------------------|
| 1 | Worker | Same factory pattern | Same factory pattern |
| 2 | GetSwitch | GetGuestAdapter (existing, renamed) | Get-VMSwitch |
| 3 | Drives | Parse showvminfo | Get-VMHardDiskDrive + Get-VMDvdDrive |
| 4 | Attach | storageattach | Add-VMHardDiskDrive |
| 5 | Give | createmedium + Attach | New-VHD + Attach |
| 6 | Delete | closemedium + Remove-Item | Remove-VMHardDiskDrive + Remove-Item |
| 7 | Eject | Attach emptydrive | Set-VMDvdDrive -Path $null |
| 8 | Insert | Attach dvddrive | Add-VMDvdDrive / Set-VMDvdDrive |
| 9 | Exists | list vms | Get-VM check |
| 10 | Running | list runningvms | Get-VM .State check |
| 11 | Pause | controlvm pause | Suspend-VM |
| 12 | Resume | controlvm resume | Resume-VM |
| 13 | Bump | Pause + Sleep + Resume | Pause + Sleep + Resume |
| 14 | Start | startvm | Start-VM |
| 15 | Shutdown | controlvm poweroff/acpi | Stop-VM [-Force] |
| 16 | UntilShutdown | $mod.SDK.Job pattern | $mod.SDK.Job pattern |
| 17 | SetProcessor | Configure (flat flags) | Set-VMProcessor @Settings |
| 18 | SetMemory | Configure (flat flags) | Set-VMMemory @Settings |
| 19 | SetNetworkAdapter | Configure (flat flags) | Set-VMNetworkAdapter @Settings |
| 20 | SetFirmware | Configure (flat flags) | Set-VMFirmware @Settings |
| 21 | Optimize | Composes Set* methods | Composes Set* methods |
| 22 | Hypervisor | SetProcessor(nested-hw-virt) | SetProcessor + SetMemory + SetNetworkAdapter |
| 23 | Destroy | Shutdown + unregistervm + cleanup | Stop + Remove-VM + cleanup |
| 24 | Create | createvm + Configure + storage | New-VM + Set-VM* + storage |

### Platform-Specific Methods

| Module | Method | Notes |
|--------|--------|-------|
| Vbox | Path (property) | VBoxManage.exe path |
| Vbox | Invoke | VBoxManage CLI wrapper |
| Vbox | Configure | Generic `modifyvm` dispatcher (Set* methods delegate to this) |

---

## Integration Points

### SDK.ps1 Loading

Add between Vbox and Multipass (line 79):
```powershell
& "$PSScriptRoot/modules/HyperV.ps1" -SDK $SDK
```

### vm.config.yaml

Existing `vbox` section has `memory: 4096` (MB) and `disk_size: 40960` (MB). HyperV could potentially share the `vbox` config section or get its own `hyperv` section. The Autoinstall module references `$mod.SDK.Settings.Virtualization.Vbox` — a HyperV equivalent would reference `$mod.SDK.Settings.Virtualization.HyperV` or similar.

### Autoinstall.ps1 Relationship

Currently Autoinstall.Worker uses `$mod.SDK.Vbox.Worker()`. Eventually there may be a HyperV equivalent, but that's out of scope for the initial module — HyperV.ps1 stands alone as an SDK module like Vbox.ps1 does.

---

## Design Decisions

### 1. No Invoke Method

**Decision**: Confirmed. Each method calls Hyper-V cmdlets directly. This is the fundamental structural difference from Vbox.ps1 and Multipass.ps1.

### 2. Error Handling Pattern

Vbox.ps1 checks `$result.Success` from Invoke. HyperV cmdlets throw on failure by default.

**Options**:
A. Use `-ErrorAction Stop` + try/catch, return `$true/$false`
B. Use `-ErrorAction SilentlyContinue` + check `$?`
C. Let exceptions propagate

**Recommendation**: Option A — consistent with Vbox's `return $result.Success` pattern. Methods return `$true`/`$false` where Vbox does.

### 3. VM Generation

Hyper-V supports Generation 1 (BIOS) and Generation 2 (UEFI). Vbox uses `--firmware efi` parameter.

**Decision**: Default to Generation 2 (matches Vbox's EFI default). Expose as `$mod.Configurator.Defaults.Generation`.

### 4. VHD Path Convention

Vbox stores VDI at `$env:TEMP\$Name.vdi`. Hyper-V typically stores VHDs under `C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\` or a custom path.

**Decision**: Follow Vbox pattern — `$env:TEMP\$Name.vhdx`. Configurable via `MediumPath` in Worker Rendered properties.

### 5. Dynamic Memory

Must be disabled for nested virtualization. The `Hypervisor` method handles this alongside `ExposeVirtualizationExtensions`.

**Decision**: Hypervisor method disables dynamic memory, enables virt extensions, enables MAC spoofing — all three required for nested virt.

---

## Decisions (Resolved)

1. **Elevation**: Let errors propagate naturally. No special checks.

2. **No generic Configure**: Instead of a dispatcher, map necessary Hyper-V cmdlets as individual SDK module methods. Each is a thin wrapper that splats a hashtable to the underlying cmdlet:

```powershell
SetProcessor = {
    param([string]$VMName, [hashtable]$Settings)
    $Settings.VMName = $VMName
    Set-VMProcessor @Settings
    return $true
}
SetMemory = {
    param([string]$VMName, [hashtable]$Settings)
    $Settings.VMName = $VMName
    Set-VMMemory @Settings
    return $true
}
SetNetworkAdapter = {
    param([string]$VMName, [hashtable]$Settings)
    $Settings.VMName = $VMName
    Set-VMNetworkAdapter @Settings
    return $true
}
SetFirmware = {
    param([string]$VMName, [hashtable]$Settings)
    $Settings.VMName = $VMName
    Set-VMFirmware @Settings
    return $true
}
```

Higher-level methods compose these:
```powershell
Optimize = { calls SetProcessor, SetMemory with perf settings }
Hypervisor = { SetProcessor(ExposeVirtualizationExtensions) + SetMemory(DynamicMemoryEnabled=$false) + SetNetworkAdapter(MacAddressSpoofing=On) }
```

This mirrors how Vbox.Invoke wraps VBoxManage — each Set* method wraps its corresponding cmdlet.

**Vbox.ps1 parity**: Add the same Set* methods to Vbox.ps1 for a consistent API surface. On Vbox, all Set* methods delegate to `Configure` (since VBoxManage modifyvm has a flat flag namespace):

```powershell
# Vbox — semantic wrappers around Configure
SetProcessor      = { param($VMName, $Settings) return $this.Configure($VMName, $Settings) }
SetMemory         = { param($VMName, $Settings) return $this.Configure($VMName, $Settings) }
SetNetworkAdapter = { param($VMName, $Settings) return $this.Configure($VMName, $Settings) }
SetFirmware       = { param($VMName, $Settings) return $this.Configure($VMName, $Settings) }
```

Then `Optimize` and `Hypervisor` on both modules compose the same Set* methods with platform-specific parameters:
```powershell
# Vbox.Hypervisor
$this.SetProcessor($VMName, @{ "nested-hw-virt" = "on" })

# HyperV.Hypervisor
$this.SetProcessor($VMName, @{ ExposeVirtualizationExtensions = $true })
$this.SetMemory($VMName, @{ DynamicMemoryEnabled = $false })
$this.SetNetworkAdapter($VMName, @{ MacAddressSpoofing = "On" })
```

3. **VHD format**: Dynamic (matches Vbox and Multipass behavior — both use thin provisioning by default).
