# Feedback #5: HyperV API Alignment & Corrections

## Baseline

`a5c20e7`

## Issues

### 1. HyperV Naming Misalignment

HyperV uses `MemoryMB` and `DiskGB` where Vbox uses `Memory` and `Disk` (both in MB). `Give` uses `$SizeGB` where Vbox uses `$Size` (MB).

**Fix**: Rename to match Vbox — `Memory = 4096`, `Disk = 40960`, `$Size`. Convert internally: `$Memory * 1MB` for bytes, `$Disk * 1MB` for bytes.

**Affected**: Configurator.Defaults, Worker Properties (Rendered + accessors), Worker Methods Create, main Create params, Give params.

### 2. Missing IsoPath

Vbox Worker has `IsoPath` property (line 56) and passes `$this.IsoPath` in Create delegation (line 82). HyperV has no IsoPath — Worker Create hardcodes `$null` for DVDPath.

**Fix**: Add `IsoPath = $null` to Defaults, add Worker Property accessor, pass `$this.IsoPath` in Worker Create delegation.

### 3. Create Missing Firmware

Vbox Create accepts `$Firmware` param (`"efi"`/`"bios"`) and configures via `Configure(@{ firmware = $Firmware })`. HyperV Create has no firmware handling.

For Hyper-V Gen 2 VMs, firmware is always UEFI (set by Generation). The equivalent configuration is `Set-VMFirmware` for settings like SecureBoot. Create should call `$this.SetFirmware()` after VM creation.

**Fix**: Add `$this.SetFirmware($VMName, ...)` call in Create. Worker Create delegation should pass relevant firmware settings.

### 4. GetSwitch → GetGuestAdapter

Current GetSwitch does `Get-VMSwitch -Name $SwitchName` — doesn't follow the Vbox.GetGuestAdapter pattern. The same network interface name from config (e.g., "Ethernet 3") is used for both VBox and Hyper-V.

**Vbox pattern**:
1. Takes adapter name from config ("Ethernet 3")
2. Calls `$mod.SDK.Network.GetGuestAdapter($AdapterName)` → gets adapter object
3. Matches `adapter.InterfaceDescription` against VBox bridged interface list
4. Returns VBox-specific adapter name

**HyperV equivalent**:
1. Takes adapter name from config ("Ethernet 3")
2. Calls `$mod.SDK.Network.GetGuestAdapter($AdapterName)` → validates adapter exists
3. Gets physical adapter directly (Network.GetGuestAdapter may return vSwitch adapter whose InterfaceDescription won't match VMSwitch)
4. Finds External VMSwitch whose `NetAdapterInterfaceDescription` matches physical adapter
5. Returns VMSwitch name

**Fix**: Rename to `GetGuestAdapter`, follow Vbox pattern with VMSwitch lookup.

**Note**: When Hyper-V has an External switch on "Ethernet 3", `Network.GetGuestAdapter` returns the vSwitch adapter "vEthernet (Ethernet 3)" (InterfaceDescription = "Hyper-V Virtual Ethernet Adapter"). For VMSwitch matching we need the physical adapter's InterfaceDescription, so we must get the physical adapter directly via `Get-NetAdapter -Name $AdapterName`.

### 5. Set\* Methods Need Proper Params

**Current VBox** — pointless wrappers, all identical:
```powershell
SetProcessor = { param($VMName, $Settings) return $this.Configure($VMName, $Settings) }
```

**Current HyperV** — raw pass-through, mutates input hashtable:
```powershell
SetProcessor = { param($VMName, $Settings) $Settings.VMName = $VMName; Set-VMProcessor @Settings }
```

Neither validates input or documents acceptable keys.

**Fix**: Keep hashtable pattern (PowerShell ScriptBlock methods only support positional args, making named params awkward). Each method translates common keys and passes through platform-specific keys. Don't mutate input — copy to new hashtable.

**Common key**: `Count` for SetProcessor (VBox translates to `cpus`, HyperV passes directly to `-Count`).

**PowerShell gotcha**: `$hashtable.Count` returns number of entries, not a key named "Count". Must use `$hashtable["Count"]` or `$hashtable.ContainsKey("Count")`.

**Per-method accepted keys**:

| Method | VBox keys (→ VBoxManage flag) | HyperV keys (→ cmdlet param) |
|--------|-------------------------------|------------------------------|
| SetProcessor | Count → cpus, pae, nestedpaging, hwvirtex, largepages, nested-hw-virt, graphicscontroller, vram | Count, ExposeVirtualizationExtensions |
| SetMemory | memory | DynamicMemoryEnabled, StartupBytes |
| SetNetworkAdapter | nic1, bridgeadapter1 | MacAddressSpoofing |
| SetFirmware | firmware | EnableSecureBoot, SecureBootTemplate |

VBox translates `Count` → `cpus`, passes other keys as `--$key $value` to VBoxManage. HyperV copies keys to a new hashtable, adds VMName, splats to cmdlet.

### 6. HyperV Create Missing Throws

HyperV Create doesn't check return values from SetProcessor, Optimize, or Hypervisor. If any fail (return `$false`), Create silently continues.

**Fix**: Check return values and throw on failure, matching Vbox Create's pattern:
```powershell
$configured = $this.SetProcessor($VMName, @{ Count = $CPUs })
if (-not $configured) { throw "Failed to configure processor for VM '$VMName'." }
```

### 7. `| Out-Null` Blocking Throws in Vbox.ps1

In Vbox Create (lines 654, 660):
```powershell
$configured = $this.Optimize($VMName) | Out-Null
if (-not $configured) { throw "Failed to optimize..." }
```

`| Out-Null` consumes pipeline output, making `$configured` always `$null`. Since `-not $null` is `$true`, the throw **always fires**. This is a confirmed bug — every Create call with `$Optimize = $true` (the default) hits this throw, falls into the outer catch, and returns `$false`.

**Other `| Out-Null` in Vbox.ps1**:
- Line 313 (Delete → Invoke): return value discarded, not checked — functionally OK but sloppy
- Lines 553-554 (Destroy → Shutdown/UntilShutdown): return values discarded, not checked — OK
- Line 558 (Destroy → Invoke unregistervm): same
- Line 560 (Destroy → Delete): Delete returns void, Out-Null is unnecessary

**`| Out-Null` in HyperV.ps1**:
- Line 140 (Give → New-VHD): `-ErrorAction Stop` handles errors; Out-Null only suppresses VHD object output. Fine but could use `$null = ...` instead.
- Lines 253-254 (Destroy → Shutdown/UntilShutdown): same as Vbox, functionally OK
- Line 274 (Create → New-VM): same as Give

**Fix**: Remove `| Out-Null` from assignment lines in Vbox Create. Clean up unnecessary usages in both files.

### 8. HyperV Create Param Alignment

Create params should match Vbox naming: `$Size` (not `$DiskGB`), `$RAM` (not `$MemoryMB`), `$CPU` (not `$CPUs`), plus missing `$Firmware` and `$DVDPath` should map to `$IsoPath` in Worker.

**Vbox Create params**: `$VMName, $MediumPath, $DVDPath, $AdapterName, $OSType, $Firmware, $ControllerName, $Size, $RAM, $CPU, $Optimize, $Hypervisor`

**HyperV Create should have**: `$VMName, $MediumPath, $DVDPath, $AdapterName, $Generation, $Firmware, $Size, $RAM, $CPU, $Optimize, $Hypervisor`

---

## Files Affected

| File | Items |
|------|-------|
| HyperV.ps1 | 1, 2, 3, 4, 5, 6, 7 (Out-Null cleanup), 8 |
| Vbox.ps1 | 5, 7 |
