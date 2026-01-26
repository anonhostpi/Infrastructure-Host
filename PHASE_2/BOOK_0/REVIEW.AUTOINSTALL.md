# Review: Autoinstall Module Cleanup

## Merge GetArtifacts into Worker

**Current State**:

Autoinstall.ps1 has a separate `GetArtifacts` method:
```powershell
GetArtifacts = {
    $artifacts = $mod.SDK.Builder.Artifacts
    if (-not $artifacts -or -not $artifacts.iso) { throw "No ISO artifact found. Build the ISO first." }
    return $artifacts
}
CreateWorker = {
    param([hashtable]$Overrides = @{})
    $artifacts = $this.GetArtifacts()
    # ... rest of worker creation
}
```

---

### Proposed Change

Merge `GetArtifacts` logic directly into `Worker` (renamed from `CreateWorker`):

```powershell
Worker = {
    param([hashtable]$Overrides = @{})
    $artifacts = $mod.SDK.Builder.Artifacts
    if (-not $artifacts -or -not $artifacts.iso) { throw "No ISO artifact found. Build the ISO first." }

    $baseConfig = $mod.SDK.Settings.Virtualization.Vbox
    $config = @{}; foreach ($k in $baseConfig.Keys) { $config[$k] = $baseConfig[$k] }
    $config.IsoPath = $artifacts.iso
    foreach ($k in $Overrides.Keys) { $config[$k] = $Overrides[$k] }
    return $mod.SDK.Vbox.Worker(@{ Config = $config })
}
```

---

### Benefits

1. Removes unnecessary abstraction
2. `GetArtifacts` is only called from `CreateWorker` - no external callers
3. Simpler API surface
