# Code Review #3: Commits 93-152

## Critical Issues

### 1. Incorrect Helper Paths in Module Files

Six modules have incorrect paths to `PowerShell.ps1`:

| File | Line | Current Path | Should Be |
|------|------|--------------|-----------|
| Builder.ps1 | 12 | `$PSScriptRoot\helpers\PowerShell.ps1` | `$PSScriptRoot\..\helpers\PowerShell.ps1` |
| General.ps1 | 14 | `$PSScriptRoot\helpers\PowerShell.ps1` | `$PSScriptRoot\..\helpers\PowerShell.ps1` |
| Settings.ps1 | 12 | `$PSScriptRoot\helpers\PowerShell.ps1` | `$PSScriptRoot\..\helpers\PowerShell.ps1` |
| Multipass.ps1 | 14 | `$PSScriptRoot\helpers\PowerShell.ps1` | `$PSScriptRoot\..\helpers\PowerShell.ps1` |
| Network.ps1 | 14 | `$PSScriptRoot\helpers\PowerShell.ps1` | `$PSScriptRoot\..\helpers\PowerShell.ps1` |
| Vbox.ps1 | 14 | `$PSScriptRoot\helpers\PowerShell.ps1` | `$PSScriptRoot\..\helpers\PowerShell.ps1` |

**Root cause**: Modules are in `host-sdk/modules/` but helpers are in `host-sdk/helpers/`. The path needs `..` to go up from `modules/` to `host-sdk/`.

**Impact**: These modules would fail to load `Add-ScriptMethods` function, causing SDK initialization to fail.

**Evidence**: The recently modified/created modules all use the correct path:
- Logger.ps1:5 - `..\helpers\PowerShell.ps1`
- Testing.ps1:6 - `..\helpers\PowerShell.ps1`
- Fragments.ps1:6 - `..\helpers\PowerShell.ps1`
- CloudInit.ps1:10 - `..\helpers\PowerShell.ps1`
- Autoinstall.ps1:6 - `..\helpers\PowerShell.ps1`
- CloudInitTest.ps1:6 - `..\helpers\PowerShell.ps1`
- AutoinstallTest.ps1:6 - `..\helpers\PowerShell.ps1`
- Verifications.ps1:6 - `..\helpers\PowerShell.ps1`

## Minor Observations

### 2. Verifications Layer Mapping is Hardcoded

In `Verifications.ps1`, the `Run()` method has a hardcoded mapping:

```powershell
$methods = @{
    1 = "Network"; 2 = "Kernel"; 3 = "Users"; 4 = "SSH"; ...
}
```

If layer numbers in `build_layers.yaml` change, this mapping would need manual updates. Consider deriving from config in a future refactor.

## Summary

- **Fix Required**: 6 modules need helper path corrections
- **New Code Quality**: The commits 93-152 follow correct patterns
- **Pre-existing Issue**: The incorrect paths exist in older modules not modified in this batch

## Recommended Fixes

Commits 153-158:
- 153: Builder.ps1 - Fix helper path
- 154: General.ps1 - Fix helper path
- 155: Settings.ps1 - Fix helper path
- 156: Multipass.ps1 - Fix helper path
- 157: Network.ps1 - Fix helper path
- 158: Vbox.ps1 - Fix helper path
