# Review: Verifications Module

## Missing Layer Implementations (4-18)

**Current State**: Only layers 1-3 are implemented in the refactored Verifications.ps1.

---

### Run Method References All 18 Layers

```powershell
Run = {
    param($Worker, [int]$Layer)
    $methods = @{
        1 = "Network"; 2 = "Kernel"; 3 = "Users"; 4 = "SSH"; 5 = "UFW"
        6 = "System"; 7 = "MSMTP"; 8 = "PackageSecurity"; 9 = "SecurityMonitoring"
        10 = "Virtualization"; 11 = "Cockpit"; 12 = "ClaudeCode"
        13 = "CopilotCLI"; 14 = "OpenCode"; 15 = "UI"
        16 = "PackageManagerUpdates"; 17 = "UpdateSummary"; 18 = "NotificationFlush"
    }
    foreach ($l in 1..$Layer) {
        if ($methods.ContainsKey($l)) {
            $methodName = $methods[$l]
            if ($this.PSObject.Methods[$methodName]) {
                $this.$methodName($Worker)
            }
        }
    }
}
```

---

### Implementation Status

| Layer | Method | Status | Old Function (master) |
|-------|--------|--------|----------------------|
| 1 | Network | Implemented | Test-NetworkFragment |
| 2 | Kernel | Implemented | Test-KernelFragment |
| 3 | Users | Implemented | Test-UsersFragment |
| 4 | SSH | **Missing** | Test-SSHFragment |
| 5 | UFW | **Missing** | Test-UFWFragment |
| 6 | System | **Missing** | Test-SystemFragment |
| 7 | MSMTP | **Missing** | Test-MSMTPFragment |
| 8 | PackageSecurity | **Missing** | Test-PackageSecurityFragment |
| 9 | SecurityMonitoring | **Missing** | Test-SecurityMonitoringFragment |
| 10 | Virtualization | **Missing** | Test-VirtualizationFragment |
| 11 | Cockpit | **Missing** | Test-CockpitFragment |
| 12 | ClaudeCode | **Missing** | Test-ClaudeCodeFragment |
| 13 | CopilotCLI | **Missing** | Test-CopilotCLIFragment |
| 14 | OpenCode | **Missing** | Test-OpenCodeFragment |
| 15 | UI | **Missing** | Test-UIFragment |
| 16 | PackageManagerUpdates | **Missing** | Test-PackageManagerUpdates |
| 17 | UpdateSummary | **Missing** | Test-UpdateSummary |
| 18 | NotificationFlush | **Missing** | Test-NotificationFlush |

---

### Old Implementation (master branch)

The master branch `Verifications.ps1` contains all 18 `Test-*Fragment` functions using the old pattern:

```powershell
function Test-SSHFragment {
    param([string]$VMName)

    # Direct multipass exec calls
    $result = multipass exec $VMName -- some-command 2>&1
    <# (multi) return #> @{
        Test = "6.4.1"
        Name = "Test name"
        Pass = ($result -match "expected")
        Output = $result
    }
}
```

---

### Migration Pattern

Convert each `Test-*Fragment` function to a method on `$Verifications`:

**Old (master)**:
```powershell
function Test-SSHFragment {
    param([string]$VMName)
    $result = multipass exec $VMName -- test -f /etc/ssh/sshd_config 2>&1
    <# (multi) return #> @{
        Test = "6.4.1"; Name = "SSHD config exists"
        Pass = ($LASTEXITCODE -eq 0); Output = $result
    }
}
```

**New (module method)**:
```powershell
SSH = {
    param($Worker)
    $result = $Worker.Exec("test -f /etc/ssh/sshd_config")
    $mod.SDK.Testing.Record(@{
        Test = "6.4.1"; Name = "SSHD config exists"
        Pass = $result.Success; Output = $result.Output
    })
}
```

---

### Key Differences

| Aspect | Old (master) | New (module) |
|--------|--------------|--------------|
| Parameter | `$VMName` string | `$Worker` object |
| Execution | `multipass exec $VMName --` | `$Worker.Exec()` |
| Return | Multiple `@{}` hashtables | `$mod.SDK.Testing.Record()` calls |
| Exit check | `$LASTEXITCODE -eq 0` | `$result.Success` |
| Scope | Multipass-only | Works with any worker type |

---

### Action Required

Port remaining 15 test functions from master `Verifications.ps1` to the new module pattern.

Reference: `git show master:book-0-builder/host-sdk/modules/Verifications.ps1`
