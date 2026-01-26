# Review: Invoke Script Cleanup

## Invoke-*.ps1 Scripts Use Old API

The Invoke scripts still reference the old `$SDK.AutoinstallTest` and `$SDK.CloudInitTest` paths instead of the new submodule paths.

---

### Invoke-AutoinstallTest.ps1

**Current (broken)**:
```powershell
$result = $SDK.AutoinstallTest.Run(@{
    Network = "Ethernet"
})

if (-not $SkipCleanup) {
    $SDK.AutoinstallTest.Cleanup()
}
```

**Should be**:
```powershell
$result = $SDK.Autoinstall.Test.Run(@{
    Network = "Ethernet"
})

if (-not $SkipCleanup) {
    $SDK.Autoinstall.Cleanup()
}
```

---

### Invoke-IncrementalTest.ps1

**Current (broken)**:
```powershell
$result = $SDK.CloudInitTest.Run($Layer)

if (-not $SkipCleanup) {
    $SDK.CloudInitTest.Cleanup()
    $SDK.Builder.Destroy()
}
```

**Should be**:
```powershell
$result = $SDK.CloudInit.Test.Run($Layer)

if (-not $SkipCleanup) {
    $SDK.CloudInit.Cleanup()
    $SDK.Builder.Destroy()
}
```
