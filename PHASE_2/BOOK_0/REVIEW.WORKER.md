# Review: Worker Module Consolidation

## General.ps1 + Worker.ps1 Merge

### Current State

**Worker.ps1** (48 lines):
```powershell
New-Module -Name SDK.Worker -ScriptBlock {
    param($SDK)
    $mod = @{ SDK = $SDK }

    function Add-CommonWorkerMethods {      # ← Exported function (anti-pattern)
        param($Worker)
        Add-ScriptMethods $Worker @{
            Ensure = { ... }
            Test = { ... }
        }
    }

    $Worker = New-Object PSObject
    $SDK.Extend("Worker", $Worker)          # ← Creates empty $SDK.Worker
    Export-ModuleMember -Function Add-CommonWorkerMethods
}
```

**General.ps1** (62 lines):
```powershell
New-Module -Name SDK.General -ScriptBlock {
    param($SDK)
    $mod = @{ SDK = $SDK }

    $General = New-Object PSObject
    Add-ScriptMethods $General @{
        UntilInstalled = {
            param($Username, $Address, $Port, $TimeoutSeconds)
            # BUG: Uses Network.SSH directly instead of $this.Exec
            return $mod.SDK.Network.SSH(
                $mod.SDK.Settings.KeyPath,
                $Username, $Address, $Port,
                "cloud-init status --wait",
                $TimeoutSeconds
            ).Success
        }
        Errored = {
            # BUG: $Username, $Address, $Port are undefined
            $status = $mod.SDK.Network.SSH(
                $mod.SDK.Settings.KeyPath,
                $Username, $Address, $Port,  # ← undefined variables
                "cloud-init status"
            ).Output
            # ...
        }
    }
    $SDK.Extend("General", $General)
}
```

**Usage** (Multipass.ps1:250, Vbox.ps1:112):
```powershell
Add-CommonWorkerMethods $worker
```

---

### Issues

1. **Worker.ps1 exports a function** - Should use module method pattern like other modules
2. **$SDK.Worker is empty** - Created but has no methods (Ensure/Test are added to workers, not $SDK.Worker)
3. **General.ps1 methods use Network.SSH directly** - Should use `$this.Exec()` for worker portability
4. **General.ps1 Errored() has undefined variables** - Bug: `$Username`, `$Address`, `$Port` not in scope
5. **General.ps1 is never called** - No references to `$SDK.General` in codebase

---

### $this.Exec Viability

Both worker types implement `Exec()` that abstracts SSH/exec:

| Worker | Exec Implementation |
|--------|---------------------|
| VboxWorker | `$mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)` |
| MultipassWorker | `multipass exec $VMName -- bash -c "$Command"` |

Both return: `@{ Output = string[]; ExitCode = int; Success = bool }`

**Conclusion**: General.ps1 methods would work on both worker types if converted to use `$this.Exec()`.

---

### Proposed Merged Worker.ps1

```powershell
param($SDK)

New-Module -Name SDK.Worker -ScriptBlock {
    param($SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Worker = New-Object PSObject

    Add-ScriptMethods $Worker @{
        Methods = {
            param($Target)
            Add-ScriptMethods $Target @{
                Ensure = {
                    if (-not $this.Exists()) { return $this.Create() }
                    return $true
                }
                Test = {
                    param($TestId, $Name, $Command, $ExpectedPattern)
                    $mod.SDK.Log.Debug("Running test: $Name")
                    try {
                        $result = $this.Exec($Command)
                        $pass = $result.Success -and ($result.Output -join "`n") -match $ExpectedPattern
                        $testResult = @{ Test = $TestId; Name = $Name; Pass = $pass; Output = $result.Output; Error = $result.Error }
                        $mod.SDK.Testing.Record($testResult)
                        if ($pass) { $mod.SDK.Log.Write("[PASS] $Name", "Green") }
                        else { $mod.SDK.Log.Write("[FAIL] $Name", "Red") }
                        return $testResult
                    }
                    catch {
                        $mod.SDK.Log.Write("[FAIL] $Name - Exception: $_", "Red")
                        $testResult = @{ Test = $TestId; Name = $Name; Pass = $false; Error = $_.ToString() }
                        $mod.SDK.Testing.Record($testResult)
                        return $testResult
                    }
                }
                UntilInstalled = {
                    param([int]$TimeoutSeconds = 900)
                    return $this.Exec("cloud-init status --wait").Success
                }
                Errored = {
                    $status = $this.Exec("cloud-init status").Output
                    $joined = $status -join " "
                    $errored = $joined -match "status: error" -or $joined -match "status: degraded"
                    if ($errored) {
                        $mod.SDK.Log.Warn("Cloud-init finished with errors")
                        return $true
                    }
                    return $false
                }
            }
        }
    }

    $SDK.Extend("Worker", $Worker)
    Export-ModuleMember -Function @()
}
```

---

### Changes Summary

| Change | Before | After |
|--------|--------|-------|
| Function export | `Export-ModuleMember -Function Add-CommonWorkerMethods` | `Export-ModuleMember -Function @()` |
| Method access | `Add-CommonWorkerMethods $worker` | `$SDK.Worker.Methods($worker)` |
| UntilInstalled | `Network.SSH($KeyPath, $User, $Addr, $Port, ...)` | `$this.Exec("cloud-init status --wait")` |
| Errored | Uses undefined `$Username`, `$Address`, `$Port` | Uses `$this.Exec("cloud-init status")` |
| General.ps1 | Exists as separate module | Deleted |

---

### Callers to Update

| File | Current | Proposed |
|------|---------|----------|
| Multipass.ps1:250 | `Add-CommonWorkerMethods $worker` | `$mod.SDK.Worker.Methods($worker)` |
| Vbox.ps1:112 | `Add-CommonWorkerMethods $worker` | `$mod.SDK.Worker.Methods($worker)` |
| SDK.ps1 | Loads General.ps1 | Remove General.ps1 loading |

---

## CreateWorker → Worker Rename

**Instances to rename** (where "Worker" is not reserved):

| File | Current | Proposed |
|------|---------|----------|
| CloudInit.ps1:28 | `CreateWorker = {` | `Worker = {` |
| CloudInitTest.ps1:13 | `$mod.SDK.CloudInit.CreateWorker(...)` | `$mod.SDK.CloudInit.Worker(...)` |
| Autoinstall.ps1:16 | `CreateWorker = {` | `Worker = {` |
| AutoinstallTest.ps1:13 | `$mod.SDK.Autoinstall.CreateWorker(...)` | `$mod.SDK.Autoinstall.Worker(...)` |

**Reserved** (do not rename):
- `$SDK.Multipass.Worker` - factory method
- `$SDK.Vbox.Worker` - factory method

---

## Worker.Status Method

**Proposal**: Add `Status` to SDK.Worker.Methods based on MultipassWorker.Status pattern.

### Current State

```powershell
# Multipass.ps1 - core module
Status = {
    param([string]$VMName)
    $result = $this.Exec($VMName, "cloud-init status")
    return $result.Output
}

# Multipass.ps1 - worker method
Status = {
    return $mod.SDK.Multipass.Status($this.Name)
}
```

### Proposed Worker.Methods Addition

```powershell
Status = {
    $result = $this.Exec("cloud-init status")
    return $result.Output
}
```

This generalizes to any worker type since it uses `$this.Exec()`.

---

## Remove UntilInstalled Duplication

**Issue**: UntilInstalled is defined in multiple places:

| Location | Implementation |
|----------|----------------|
| `$SDK.Multipass.UntilInstalled($VMName)` | `$this.Exec($VMName, "cloud-init status --wait")` |
| `MultipassWorker.UntilInstalled()` | Delegates to `$SDK.Multipass.UntilInstalled($this.Name)` |
| `SDK.Worker.Methods` (proposed) | `$this.Exec("cloud-init status --wait")` |

**Action**:
1. Remove `UntilInstalled` from `$SDK.Multipass` core module
2. Remove `UntilInstalled` from `$mod.Worker.Methods` in Multipass.ps1
3. Keep only in `SDK.Worker.Methods` (uses `$this.Exec()`)

---

## Move Setup to SDK.Worker.Methods

**Current**: Setup only exists in MultipassWorker.

```powershell
# Multipass.ps1 - worker method
Setup = {
    param([bool]$FailOnNotInitialized)
    $created = $this.Ensure()
    if (-not $created) {
        throw "Failed to create VM '$($this.Name)'"
    }
    $initialized = $this.UntilInstalled()
    if (-not $initialized -and $FailOnNotInitialized) {
        throw "Cloud-init failed for VM '$($this.Name)'"
    }
    return $initialized
}
```

**Proposal**: Move to SDK.Worker.Methods since it only uses worker methods (`Ensure`, `UntilInstalled`).

Works for both MultipassWorker and VboxWorker.

---

## Add SDK.Network.SCP for File Transfers

**Proposal**: Add SCP method to SDK.Network module.

```powershell
# SDK.Network
SCP = {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$KeyPath = $mod.SDK.Settings.KeyPath,
        [int]$Port = 22
    )
    # scp -i $KeyPath -P $Port $Source $Destination
    $args = @("-i", $KeyPath, "-P", $Port, "-o", "StrictHostKeyChecking=no", $Source, $Destination)
    $result = & scp @args 2>&1
    return @{
        Output = $result
        ExitCode = $LASTEXITCODE
        Success = $LASTEXITCODE -eq 0
    }
}
```

---

## Add Base Pull/Push to SDK.Worker.Methods

**Proposal**: Add Pull and Push methods that use SCP, overridable by Multipass.

### SDK.Worker.Methods (base implementation)

```powershell
Pull = {
    param([string]$Source, [string]$Destination)
    # Uses SSH-based SCP: user@host:source -> destination
    $remote = "$($this.SSHUser)@$($this.SSHHost):$Source"
    return $mod.SDK.Network.SCP($remote, $Destination, $mod.SDK.Settings.KeyPath, $this.SSHPort).Success
}
Push = {
    param([string]$Source, [string]$Destination)
    # Uses SSH-based SCP: source -> user@host:destination
    $remote = "$($this.SSHUser)@$($this.SSHHost):$Destination"
    return $mod.SDK.Network.SCP($Source, $remote, $mod.SDK.Settings.KeyPath, $this.SSHPort).Success
}
```

### Multipass.Worker Override

```powershell
# Multipass uses multipass transfer instead of SCP
Pull = {
    param([string]$Source, [string]$Destination)
    return $mod.SDK.Multipass.Transfer("$($this.Name):$Source", $Destination)
}
Push = {
    param([string]$Source, [string]$Destination)
    return $mod.SDK.Multipass.Transfer($Source, "$($this.Name):$Destination")
}
```

---

## Add Base Shell to SDK.Worker.Methods

**Proposal**: Add Shell method that spawns interactive SSH session, overridable by Multipass.

### SDK.Worker.Methods (base implementation)

```powershell
Shell = {
    # Spawn interactive SSH session
    $keyPath = $mod.SDK.Settings.KeyPath
    & ssh -i $keyPath -p $this.SSHPort -o StrictHostKeyChecking=no "$($this.SSHUser)@$($this.SSHHost)"
}
```

### Multipass.Worker Override

```powershell
# Multipass uses multipass shell instead of SSH
Shell = {
    $mod.SDK.Multipass.Shell($this.Name)
}
```
