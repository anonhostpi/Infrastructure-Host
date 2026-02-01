# Feedback #6: Unified Set* Keys & Firmware String

## Baseline

`f34ae9e`

## Issues

### 1. Firmware Should Be String

HyperV Create takes `[hashtable]$Firmware = @{}`. Should be `[string]$Firmware = "efi"` to match Vbox API shape. Each module translates internally.

### 2. ForEach Pipeline Unnecessary

`($Settings.Keys | ForEach-Object { $_ })` in Set* methods — no concurrent modification happening. Plain `$Settings.Keys` suffices.

### 3. Set* Methods Need Unified Key Maps

Both modules should accept the same keys. When a key from one module is used on the other, transform it. For unit differences (GB vs MB), accept both variants.

---

## Unified Key Maps

### SetProcessor

| Unified Key | VBox (→ Configure flag) | HyperV (→ Set-VMProcessor) |
|-------------|------------------------|---------------------------|
| Count | → `cpus` | native |
| cpus | native | → `Count` |
| ExposeVirtualizationExtensions | → `nested-hw-virt` (bool→on/off) | native |
| nested-hw-virt | native | → `ExposeVirtualizationExtensions` (on/off→bool) |
| pae | native | skip |
| nestedpaging | native | skip |
| hwvirtex | native | skip |
| largepages | native | skip |
| graphicscontroller | native | skip |
| vram | native | skip |

### SetMemory

| Unified Key | VBox (→ Configure flag) | HyperV (→ Set-VMMemory) |
|-------------|------------------------|------------------------|
| MemoryMB | → `memory` (as-is) | → `StartupBytes` (* 1MB) |
| MemoryGB | → `memory` (* 1024) | → `StartupBytes` (* 1GB) |
| memory | native | → `StartupBytes` (* 1MB, assume MB) |
| DynamicMemoryEnabled | skip | native |
| StartupBytes | → `memory` (/ 1MB) | native |

### SetNetworkAdapter

| Unified Key | VBox (→ Configure flag) | HyperV (→ Set-VMNetworkAdapter) |
|-------------|------------------------|-------------------------------|
| MacAddressSpoofing | skip | native |
| nic1 | native | skip |
| bridgeadapter1 | native | skip |

### SetFirmware

| Unified Key | VBox (→ Configure flag) | HyperV (→ Set-VMFirmware) |
|-------------|------------------------|--------------------------|
| Firmware | → `firmware` | skip (Gen 2 = UEFI already) |
| firmware | native | skip |
| EnableSecureBoot | skip | native |
| SecureBootTemplate | skip | native |

---

## Commits Needed

1. HyperV Create: `[hashtable]$Firmware` → `[string]$Firmware = "efi"`, fix body
2. HyperV Worker Create delegation: `@{}` → `"efi"`
3. VBox SetProcessor: unified key map with translation
4. HyperV SetProcessor: unified key map with translation
5. VBox SetMemory: unified key map with translation
6. HyperV SetMemory: unified key map with translation
7. VBox SetNetworkAdapter + SetFirmware: key filtering
8. HyperV SetNetworkAdapter + SetFirmware: key filtering
