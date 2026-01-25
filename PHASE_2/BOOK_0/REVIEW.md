# SDK Review Items

Issues identified for future cleanup/improvement.

---

## 1. WaitForSSH is Duplicative of UntilSSH

**Location**: `book-0-builder/host-sdk/modules/Network.ps1:73-101`

**Current State**:
```powershell
UntilSSH = {
    param([string]$Address, [int]$Port = 22, [int]$TimeoutSeconds)
    return $mod.SDK.Job({
        while(-not $SDK.Network.TestSSH($Address, $Port)) {
            Start-Sleep -Seconds 5
        }
    }, $TimeoutSeconds, @{ Address = $Address; Port = $Port })
}

WaitForSSH = {
    param([string]$Address, [int]$Port = 22, [int]$TimeoutSeconds = 300)
    $timedOut = $this.UntilSSH($Address, $Port, $TimeoutSeconds)
    if ($timedOut) {
        throw "Timed out waiting for SSH on ${Address}:${Port}"
    }
    return $true
}
```

**Issue**: `WaitForSSH` is just a thin wrapper that throws on timeout. The naming is confusing:
- `UntilSSH` - waits until SSH is available, returns bool (true = timed out)
- `WaitForSSH` - same thing but throws on timeout

**Options**:

1. **Keep both, clarify naming**:
   - `UntilSSH` -> `WaitForSSH` (returns bool)
   - `WaitForSSH` -> `WaitForSSHOrThrow` or `RequireSSH`

2. **Merge into one with throw parameter**:
   ```powershell
   WaitForSSH = {
       param([string]$Address, [int]$Port = 22, [int]$TimeoutSeconds = 300, [switch]$Throw)
       $timedOut = $mod.SDK.Job({ ... }, $TimeoutSeconds, ...)
       if ($timedOut -and $Throw) {
           throw "Timed out waiting for SSH on ${Address}:${Port}"
       }
       return -not $timedOut
   }
   ```

3. **Remove WaitForSSH entirely**: Callers can check `UntilSSH` return value and throw themselves.

**Recommendation**: Option 2 - single method with `-Throw` switch.

---

## 2. Default VBox SSH User Should Match identity.config.yaml

**Location**: `book-0-builder/host-sdk/modules/Vbox.ps1:21`

**Current State**:
```powershell
$mod.Configurator = @{
    Defaults = @{
        CPUs = 2
        Memory = 4096
        Disk = 40960
        SSHUser = "ubuntu"  # <-- HARDCODED
        SSHHost = "localhost"
        SSHPort = 2222
    }
}
```

**Issue**: The SSH user is hardcoded to `"ubuntu"`, but the actual user is defined in:
```yaml
# book-2-cloud/users/config/identity.config.yaml
identity:
  username: admin  # <-- This is the actual user
```

When the autoinstall ISO boots, it creates the user from `identity.config.yaml`. The VBox worker then fails to SSH because it's trying to connect as `ubuntu` instead of `admin`.

**Fix**:
```powershell
$mod.Configurator = @{
    Defaults = @{
        CPUs = 2
        Memory = 4096
        Disk = 40960
        SSHUser = $null  # Derive from config at runtime
        SSHHost = "localhost"
        SSHPort = 2222
    }
}
```

Then in the `Rendered` property getter, if `SSHUser` is null, load it from identity config:
```powershell
Rendered = {
    $config = ...
    if (-not $config.SSHUser) {
        # Load from identity.config.yaml
        $identityPath = "$($mod.SDK.Root())/book-2-cloud/users/config/identity.config.yaml"
        if (Test-Path $identityPath) {
            $identity = Get-Content $identityPath -Raw | ConvertFrom-Yaml
            $config.SSHUser = $identity.identity.username
        } else {
            $config.SSHUser = "ubuntu"  # Fallback
        }
    }
    return $config
}
```

**Alternative**: Add `SSHUser` to `vm.config.yaml` under `Virtualization.Vbox` section so it's explicit in the config.

---

## 3. Unit Testing Needed for SDK Modules

**Issue**: No unit tests exist for the SDK modules. Each module in `book-0-builder/host-sdk/modules/` should have corresponding tests.

**Modules Requiring Tests**:

| Module | Test Coverage Needed |
|--------|---------------------|
| `Logger.ps1` | Write, Info, Warning, Error methods |
| `Settings.ps1` | Config loading, path resolution |
| `Network.ps1` | TestSSH, UntilSSH/WaitForSSH, SSH execution |
| `General.ps1` | Cloud-init helper functions |
| `Vbox.ps1` | Worker creation, VM lifecycle |
| `Multipass.ps1` | Worker creation, VM lifecycle |
| `Builder.ps1` | Stage, Build, Clean |
| `Fragments.ps1` | Layer discovery, UpTo, At, IsoRequired |
| `Testing.ps1` | Reset, Record, Summary |
| `CloudInitBuild.ps1` | Build, CreateWorker, Cleanup |
| `CloudInitTest.ps1` | Run |
| `AutoinstallBuild.ps1` | GetArtifacts, CreateWorker, Cleanup |
| `AutoinstallTest.ps1` | Run |

**Test Framework**: Pester (standard PowerShell testing framework)

**Proposed Test Structure**:
```
book-0-builder/host-sdk/
├── tests/
│   ├── Logger.Tests.ps1
│   ├── Settings.Tests.ps1
│   ├── Network.Tests.ps1
│   ├── Fragments.Tests.ps1
│   ├── Testing.Tests.ps1
│   └── ...
└── modules/
    └── ...
```

**Example Test (Logger.Tests.ps1)**:
```powershell
BeforeAll {
    . $PSScriptRoot/../SDK.ps1
}

Describe "Logger Module" {
    It "Info outputs with correct color" {
        # Mock Write-Host and verify color parameter
    }

    It "Error outputs with Red color" {
        # ...
    }

    It "Write respects quiet mode" {
        # ...
    }
}
```

**Test Types**:
1. **Unit tests**: Mock external dependencies (SSH, VBoxManage, multipass)
2. **Integration tests**: Actually create/destroy VMs (slow, optional)

**Priority**:
1. `Fragments.ps1` - Core discovery logic
2. `Testing.ps1` - Test framework itself
3. `Network.ps1` - SSH utilities (mockable)
4. `Logger.ps1` - Output formatting
5. Build/Test modules - Higher level, depend on others

---

## Summary

| Item | Priority | Effort |
|------|----------|--------|
| WaitForSSH duplication | Low | Small |
| VBox SSHUser from identity.config | High | Medium |
| Unit testing | Medium | Large |
