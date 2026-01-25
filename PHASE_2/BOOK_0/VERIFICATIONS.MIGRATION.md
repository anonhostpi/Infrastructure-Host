# Verifications Migration: Functions to SDK.Testing.Verifications Submodule

## Overview

Migrate `Verifications.ps1` (standalone functions) to `SDK.Testing.Verifications` submodule (methods on object).

**Source**: `book-0-builder/host-sdk/modules/Verifications.ps1` (~2000 lines, 18 test functions)
**Target**: `SDK.Testing.Verifications` submodule accessible at `$SDK.Testing.Verifications`

---

## Current Architecture (Old)

### File Structure
```
Verifications.ps1
├── Write-TestFork (helper)
├── Test-NetworkFragment
├── Test-KernelFragment
├── Test-UsersFragment
├── Test-SSHFragment
├── Test-UFWFragment
├── Test-SystemFragment
├── Test-MSMTPFragment
├── Test-PackageSecurityFragment
├── Test-SecurityMonitoringFragment
├── Test-VirtualizationFragment
├── Test-CockpitFragment
├── Test-OpenCodeFragment
├── Test-ClaudeCodeFragment
├── Test-CopilotCLIFragment
├── Test-UIFragment
├── Test-PackageManagerUpdates (agent-dependent, layer 16)
├── Test-UpdateSummary (agent-dependent, layer 17)
└── Test-NotificationFlush (agent-dependent, layer 18)
```

### Invocation Pattern (Old)
```powershell
# Load functions
. "$PSScriptRoot/Verifications.ps1"

# Call directly with VM name
Test-NetworkFragment -VMName "test-vm"
```

### Test Execution Pattern (Old)
```powershell
function Test-NetworkFragment {
    param([string]$VMName)

    # Direct multipass call
    $hostname = multipass exec $VMName -- hostname -s 2>&1

    # Implicit output (multiple returns via PowerShell output)
    <# (multi) return #> @{
        Test = "6.1.1"
        Name = "Short hostname set"
        Pass = ($hostname -and $hostname -ne "localhost" -and $LASTEXITCODE -eq 0)
        Output = $hostname
    }

    # More tests...
}
```

### Config Access (Old)
```powershell
$config = $SDK.Settings
$username = $config.identity.username  # Lowercase, nested
$smtp = $config.smtp
```

---

## Target Architecture (New)

### Module Structure
```
SDK.Testing.Verifications (submodule)
├── Network (method)
├── Kernel (method)
├── Users (method)
├── SSH (method)
├── UFW (method)
├── System (method)
├── MSMTP (method)
├── PackageSecurity (method)
├── SecurityMonitoring (method)
├── Virtualization (method)
├── Cockpit (method)
├── OpenCode (method)
├── ClaudeCode (method)
├── CopilotCLI (method)
├── UI (method)
├── PackageManagerUpdates (method, layer 16)
├── UpdateSummary (method, layer 17)
├── NotificationFlush (method, layer 18)
└── Fork (helper method, replaces Write-TestFork)
```

### Invocation Pattern (New)
```powershell
# Already loaded via SDK.ps1
$worker = $SDK.CloudInit.CreateWorker(3)
$SDK.Testing.Verifications.Network($worker)
```

### Test Execution Pattern (New)
```powershell
Network = {
    param($Worker)

    # Use worker.Exec instead of multipass exec
    $result = $Worker.Exec("hostname -s")
    $hostname = $result.Output

    # Explicit recording
    $mod.SDK.Testing.Record(@{
        Test = "6.1.1"
        Name = "Short hostname set"
        Pass = ($result.Success -and $hostname -ne "localhost")
        Output = $hostname
    })

    # More tests...
}
```

### Config Access (New)
```powershell
$identity = $mod.SDK.Settings.Identity  # PascalCase getter
$username = $identity.username
$smtp = $mod.SDK.Settings.Smtp
```

---

## Discrepancies & Required Changes

### 1. Execution Method

| Old | New |
|-----|-----|
| `multipass exec $VMName -- cmd` | `$Worker.Exec("cmd")` |
| Check `$LASTEXITCODE` | Check `$result.Success` |
| Output in `$variable` | Output in `$result.Output` |

**Migration Pattern**:
```powershell
# Old
$hostname = multipass exec $VMName -- hostname -s 2>&1
$pass = ($hostname -and $LASTEXITCODE -eq 0)

# New
$result = $Worker.Exec("hostname -s")
$pass = ($result.Success -and $result.Output)
```

### 2. Config Access

| Old | New |
|-----|-----|
| `$SDK.Settings` | `$mod.SDK.Settings` |
| `$config.identity.username` | `$mod.SDK.Settings.Identity.username` |
| `$config.smtp.host` | `$mod.SDK.Settings.Smtp.host` |

**Note**: Settings getters are PascalCase (`Identity`, `Smtp`, `Network`), but nested properties remain lowercase (`username`, `host`).

### 3. Result Recording

| Old | New |
|-----|-----|
| Implicit output via `@{...}` | `$mod.SDK.Testing.Record(@{...})` |
| Multiple returns collected by caller | Explicit recording to Testing.Results |

**Migration Pattern**:
```powershell
# Old
<# (multi) return #> @{
    Test = "6.1.1"
    Name = "Hostname set"
    Pass = $pass
    Output = $hostname
}

# New
$mod.SDK.Testing.Record(@{
    Test = "6.1.1"
    Name = "Hostname set"
    Pass = $pass
    Output = $hostname
})
```

### 4. Logging

| Old | New |
|-----|-----|
| `Write-TestFork` | `$this.Fork()` or `$mod.SDK.Log.Debug()` |
| `Write-Host` | `$mod.SDK.Log.Write()` |

### 5. Function Signature

| Old | New |
|-----|-----|
| `param([string]$VMName)` | `param($Worker)` |
| Standalone function | Method on `$Verifications` object |

### 6. Early Return

| Old | New |
|-----|-----|
| `return` exits function | `return` exits method |

No change needed, but ensure logic handles method context.

---

## Module Implementation Shape

```powershell
param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    Add-ScriptMethods $Verifications @{
        Fork = {
            param([string]$Test, [string]$Decision, [string]$Reason = "")
            $msg = "[FORK] $Test : $Decision"
            if ($Reason) { $msg += " ($Reason)" }
            $mod.SDK.Log.Debug($msg)
        }
    }

    Add-ScriptMethods $Verifications @{
        Network = {
            param($Worker)
            # ... migrated tests
        }
        Kernel = {
            param($Worker)
            # ... migrated tests
        }
        # ... more methods
    }

    # Attach as submodule to Testing
    $SDK.Testing | Add-Member -MemberType NoteProperty -Name Verifications -Value $Verifications

    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
```

---

## Test Function Mapping

| Old Function | New Method | Fragment | Layer |
|--------------|------------|----------|-------|
| `Test-NetworkFragment` | `Network` | network | 1 |
| `Test-KernelFragment` | `Kernel` | kernel | 2 |
| `Test-UsersFragment` | `Users` | users | 3 |
| `Test-SSHFragment` | `SSH` | ssh | 4 |
| `Test-UFWFragment` | `UFW` | ufw | 5 |
| `Test-SystemFragment` | `System` | system | 6 |
| `Test-MSMTPFragment` | `MSMTP` | msmtp | 7 |
| `Test-PackageSecurityFragment` | `PackageSecurity` | packages,pkg-security,pkg-upgrade | 8 |
| `Test-SecurityMonitoringFragment` | `SecurityMonitoring` | security-mon | 9 |
| `Test-VirtualizationFragment` | `Virtualization` | virtualization | 10 |
| `Test-CockpitFragment` | `Cockpit` | cockpit | 11 |
| `Test-ClaudeCodeFragment` | `ClaudeCode` | claude-code | 12 |
| `Test-CopilotCLIFragment` | `CopilotCLI` | copilot-cli | 13 |
| `Test-OpenCodeFragment` | `OpenCode` | opencode | 14 |
| `Test-UIFragment` | `UI` | ui | 15 |
| `Test-PackageManagerUpdates` | `PackageManagerUpdates` | (agent-dependent) | 16 |
| `Test-UpdateSummary` | `UpdateSummary` | (agent-dependent) | 17 |
| `Test-NotificationFlush` | `NotificationFlush` | (agent-dependent) | 18 |

---

## Migration Considerations

### 1. File Loading Order

`Verifications.ps1` module must load **after** `Testing.ps1` so that `$SDK.Testing` exists for the submodule attachment.

In `SDK.ps1`:
```powershell
& "$PSScriptRoot/modules/Testing.ps1" -SDK $SDK
& "$PSScriptRoot/modules/Verifications.ps1" -SDK $SDK  # After Testing
```

### 2. Caller Changes

Current `SDK.Testing.Verifications` method returns function names:
```powershell
Verifications = {
    param([int]$Layer)
    return $mod.SDK.Fragments.At($Layer) | ForEach-Object { "Test-$($_.Name)Fragment" }
}
```

This will need to be renamed or removed since `Verifications` becomes a submodule. Options:
- Rename to `VerificationNames`
- Remove entirely (callers can use `$SDK.Testing.Verifications.<Method>` directly)
- Keep but return method names instead

### 3. Dynamic Invocation

Old pattern for running all verifications at a layer:
```powershell
$funcNames = $SDK.Testing.Verifications($Layer)
foreach ($fn in $funcNames) {
    & $fn -VMName $worker.Name
}
```

New pattern:
```powershell
# Option A: Direct method call
$SDK.Testing.Verifications.Network($worker)

# Option B: Dynamic via Get-Member
$methodName = "Network"  # from fragment name
$SDK.Testing.Verifications.$methodName($worker)
```

### 4. Line Count per Method

Many test functions are 50-150 lines. These will need to be split across multiple commits (5-20 lines each per Rule 3).

---

## Decisions

1. **Remove the old `Verifications` method** - Delete it from Testing.ps1 to make room for the Verifications submodule.

2. **Agent-dependent tests** - No special handling needed. `PackageManagerUpdates`, `UpdateSummary`, and `NotificationFlush` are just additional methods on the submodule alongside the fragment methods.

3. **Add a `Run` method** - Convenience method to run all verifications up to a layer:
   ```powershell
   $SDK.Testing.Verifications.Run($worker, $layer)
   ```

4. **Missing methods** - Silent skip is acceptable. Document which test is being migrated for each commit group.

---

## Estimated Commit Count

Assuming ~100 lines average per test function and 18 functions:
- Module shape: 1 commit
- Fork helper: 1 commit
- Each test method: 5-10 commits each (split by depth)
- Total: ~100-150 commits

This is a significant migration. Consider:
- Phased approach (migrate a few functions at a time)
- Single large commit with file replacement (if exempted from line limit)
