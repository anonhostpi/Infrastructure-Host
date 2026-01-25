# Host SDK Restructure Discussion

This document discusses how the Host SDK (PowerShell) should be reshaped to work with the new fragment-based architecture.

---

## Current State

### Directory Structure

```
book-0-builder/host-sdk/
├── SDK.ps1                      # Entry point
├── Invoke-AutoinstallTest.ps1   # Autoinstall test runner (BLOATED)
├── Invoke-IncrementalTest.ps1   # Incremental test runner (BLOATED)
│
├── helpers/
│   ├── Config.ps1               # Config merging utilities
│   └── PowerShell.ps1           # PSObject utilities (Add-ScriptMethods, etc.)
│
└── modules/
    ├── Builder.ps1              # Builder VM management (GOOD EXAMPLE)
    ├── Config.ps1               # Fragment/test level mappings (HARDCODED)
    ├── General.ps1              # Cloud-init helpers
    ├── Multipass.ps1            # Multipass VM management
    ├── Network.ps1              # Network utilities
    ├── Settings.ps1             # Config loading
    ├── Vbox.ps1                 # VirtualBox automation
    └── Verifications.ps1        # Test verification functions
```

### SDK Pattern

The SDK uses an extension pattern where modules receive the SDK object and extend it:

```powershell
# SDK.ps1 - creates base object
$SDK = New-Object PSObject -Property @{ Path = "$PSScriptRoot\SDK.ps1" }
Add-ScriptMethods $SDK @{
    Root = { git rev-parse --show-toplevel }
    Extend = { param($ModuleName, $ModuleObject) ... }
    Job = { param($ScriptBlock, $Timeout, $Env) ... }
}

# Module loading
& "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
& "$PSScriptRoot/modules/Builder.ps1" -SDK $SDK
...
```

```powershell
# Modules extend the SDK
$Settings = New-Object PSObject -Property @{ ... }
Add-ScriptMethods $Settings @{ Load = { ... } }
$SDK.Extend("Settings", $Settings)
```

### Current Test Script State

The test scripts are **mid-refactor**:
- Half manual calls (direct multipass/VBoxManage commands)
- Half SDK calls (`$SDK.Builder.*`, `$SDK.Vbox.*`)

Goal: Test scripts should be **minimal and tiny** - just parameter handling and orchestration. All logic should live in modules.

---

## Decisions Made

| Question | Answer |
|----------|--------|
| Test levels hardcoded or derived from `build_layer`? | **Derived from `build_layer`** |
| Split Config.ps1? | **Yes** - fragment mappings vs test functions |
| How should test scripts load the SDK? | **Modules should contain all logic** - test scripts should be minimal |
| vm.config.ps1 vs vm.config.yaml? | **vm.config.yaml is canonical** - no more .ps1-based configs |

---

## Current Issues

### Issue 1: Path References in SDK.ps1

SDK.ps1 currently references modules at root level:
```powershell
& "$PSScriptRoot/Settings.ps1" -SDK $SDK
& "$PSScriptRoot/Network.ps1" -SDK $SDK
```

But modules are in `modules/` subdirectory. This needs to be:
```powershell
& "$PSScriptRoot/modules/Settings.ps1" -SDK $SDK
& "$PSScriptRoot/modules/Network.ps1" -SDK $SDK
```

### Issue 2: Test Scripts Dot-Source External Files

`Invoke-IncrementalTest.ps1` dot-sources files that should be refactored INTO the SDK:
```powershell
. "$ScriptDir\lib\Config.ps1"        # Should be ABSORBED into SDK (see Fragments.ps1, TestLevels.ps1)
. "$ScriptDir\lib\Verifications.ps1" # Should be ABSORBED into SDK (see Verifications migration below)
. "$RepoRoot\vm.config.ps1"          # Should use SDK.Settings.Load() instead
```

These files should NOT just have paths fixed - they should be eliminated entirely by refactoring their logic into SDK modules. See "Test Script Migration Analysis" and "Proposed New Module Structure" sections.

### Issue 3: Hardcoded Fragment Mappings

`modules/Config.ps1` contains hardcoded fragment names with old naming:
```powershell
"6.1"  = @{ Fragments = @("10-network"); Name = "Network" }
```

Should be derived from `build.yaml` discovery using `build_layer`.

### Issue 4: Verifications Use Direct Multipass Calls

`modules/Verifications.ps1` calls multipass directly instead of using SDK:
```powershell
$hostname = multipass exec $VMName -- hostname -s 2>&1
```

Should use SDK methods for consistency.

---

## Test Script Migration Analysis

The test scripts (`Invoke-AutoinstallTest.ps1`, `Invoke-IncrementalTest.ps1`) contain significant logic that should be moved to modules.

### Items to Extract from Invoke-AutoinstallTest.ps1

| Current Location | Description | Target Module |
|------------------|-------------|---------------|
| Lines 106-110 | `Write-Step` progress tracking function | **Logger.ps1** - `$SDK.Log.Step()` |
| Lines 194-248 | `Test-ViaSSH` helper function | **Network.ps1** - already absorbing this |
| Lines 130-153 | ISO validation logic (xorriso checks) | **Builder.ps1** - `$SDK.Builder.ValidateISO()` |
| Lines 254-269 | Result tracking (`$allResults`, `$passCount`) | **Testing.ps1** (new) |
| Lines 275-312 | VirtualBox VM creation/config | Already in Vbox.ps1 ✓ |
| Lines 314-368 | VM startup and wait logic | Mostly using SDK ✓ |
| Lines 370-400 | SSH wait and cloud-init wait | Already in SDK ✓ |
| Lines 414-488 | All `Test-ViaSSH` calls (test definitions) | **Verifications.ps1** |
| Lines 515-542 | Summary/results printing | **Testing.ps1** (new) |

### Items to Extract from Invoke-IncrementalTest.ps1

| Current Location | Description | Target Module |
|------------------|-------------|---------------|
| Lines 79-94 | VM cleanup (multipass delete/purge) | **Multipass.ps1** - already has some |
| Lines 96-121 | Builder VM setup flow | Already in Builder.ps1 ✓ (`$SDK.Builder.Stage()`) |
| Lines 123-165 | AI CLI credentials copying | **Builder.ps1** - `$SDK.Builder.CopyAICredentials()` |
| Lines 167-187 | Cloud-init build with fragments | **Builder.ps1** - `$SDK.Builder.BuildCloudInit($fragments)` |
| Lines 189-230 | Runner VM launch with cloud-init | **Multipass.ps1** or **Runner.ps1** |
| Lines 232-271 | Nested virtualization setup | **Multipass.ps1** - `$SDK.Multipass.EnableNestedVirt()` |
| Lines 273-317 | Test execution loop | **Testing.ps1** (new) |
| Lines 319-356 | Cleanup and summary | **Testing.ps1** (new) |

### Items to Migrate in Verifications.ps1

The verification functions use direct `multipass exec` calls:
```powershell
$hostname = multipass exec $VMName -- hostname -s 2>&1
```

Should migrate to use the Worker base class `Test()` method:
```powershell
# Worker.Test() handles error handling, logging, and result recording
$Worker.Test("network-hostname", "Verify hostname", "hostname -s", "^runner$")
```

This provides:
- Unified interface for both Multipass and Vbox workers
- Centralized error handling with try/catch
- Automatic logging via `$SDK.Log`
- Automatic result recording via `$SDK.Testing.Record()`

---

## Proposed New Module Structure

### modules/Logger.ps1 (NEW - LOAD FIRST)

Unified logging for all SDK modules. Must be loaded before other modules so they can use it:

```powershell
$Logger = New-Object PSObject -Property @{
    Level = "Info"  # Debug, Info, Warn, Error
    Path = $null
}

Add-ScriptMethods $Logger @{
    # Core write method - all other methods call this
    Write = {
        param([string]$Message, [string]$ForegroundColor = "White", [string]$BackgroundColor = $null)
        $params = @{ Object = $Message; ForegroundColor = $ForegroundColor }
        if ($BackgroundColor) { $params.BackgroundColor = $BackgroundColor }
        Write-Host @params
    }

    # Log level methods
    Debug = { param([string]$Message) if ($this.Level -eq "Debug") { $this.Write("[DEBUG] $Message", "Gray") } }
    Info  = { param([string]$Message) $this.Write("[INFO] $Message", "Cyan") }
    Warn  = { param([string]$Message) $this.Write("[WARN] $Message", "Yellow") }
    Error = { param([string]$Message) $this.Write("[ERROR] $Message", "Red") }
    Step  = { param([string]$Message, [int]$Current, [int]$Total) $this.Write("[$Current/$Total] $Message", "Cyan") }

    # Transcript control
    Start = {
        param([string]$Path)
        $this.Path = $Path
        Start-Transcript -Path $Path -Append
        $this.Info("Transcript started: $Path")
    }
    Stop = {
        if ($this.Path) {
            Stop-Transcript
            $this.Info("Transcript stopped: $($this.Path)")
            $this.Path = $null
        }
    }
}
$SDK.Extend("Log", $Logger)
```

### modules/Fragments.ps1 (NEW)

Discovers fragments from `build.yaml` files. `Layers` is a live getter (no caching):

```powershell
$Fragments = New-Object PSObject

# Layers is a ScriptProperty - live getter, discovers on each access
$Fragments | Add-Member -MemberType ScriptProperty -Name Layers -Value {
    $results = @()
    Get-ChildItem -Path @("book-1-foundation", "book-2-cloud") -Recurse -Filter "build.yaml" |
    ForEach-Object {
        $meta = Get-Content $_.FullName -Raw | ConvertFrom-Yaml
        $results += [PSCustomObject]@{
            Name = $meta.name
            Path = $_.DirectoryName
            Order = $meta.build_order
            Layer = $meta.build_layer
            IsoRequired = $meta.iso_required
        }
    }
    return $results | Sort-Object Order
}

Add-ScriptMethods $Fragments @{
    UpTo = {
        # All fragments up to and including this layer
        param([int]$Layer)
        return $this.Layers | Where-Object { $_.Layer -le $Layer }
    }
    At = {
        # Fragments at exactly this layer
        param([int]$Layer)
        return $this.Layers | Where-Object { $_.Layer -eq $Layer }
    }
    IsoRequired = {
        return $this.Layers | Where-Object { $_.IsoRequired }
    }
}
$SDK.Extend("Fragments", $Fragments)
```

### Worker Pattern (COMMON METHODS)

Multipass.ps1 already uses a worker pattern with `$mod.Worker.Properties` and `$mod.Worker.Methods`. The pattern is:

```powershell
# Current pattern in Multipass.ps1
$mod.Worker = @{
    Properties = @{ ... }  # ScriptProperties like Name, CPUs, etc.
    Methods = @{ ... }     # ScriptMethods like Start, Exec, etc.
}

# Worker creator applies these to a base object
$SDK.Multipass.Worker = {
    param($Base)
    Add-ScriptProperties $Base $mod.Worker.Properties
    Add-ScriptMethods $Base $mod.Worker.Methods
    return $Base
}

# Usage in Builder.ps1:
$Runner = New-Object PSObject -Property @{}
Add-ScriptProperties $Runner @{
    Config = { return $mod.SDK.Settings.Virtualization.Runner }
    Defaults = { return @{ CPUs = 2; Memory = "4G"; Disk = "15G" } }
}
$Runner = $SDK.Multipass.Worker($Runner)
$SDK.Extend("Runner", $Runner)
```

### helpers/Worker.ps1 (NEW)

Helper that adds common methods (methods that only call `$this.*` abstract methods, not hypervisor-specific APIs). Called by both Multipass.ps1 and Vbox.ps1 worker creators.

**Analysis of existing Multipass worker methods:**

| Method | Dependencies | Common? |
|--------|--------------|---------|
| Ensure | `$this.Exists()`, `$this.Create()` | ✓ |
| Setup | `$this.Ensure()`, `$this.UntilInstalled()` | ✗ (UntilInstalled not on VBox) |
| Destroy | `$mod.SDK.Multipass.Destroy()` / `$mod.SDK.Vbox.Destroy()` | ✗ (different modules) |
| Test (new) | `$this.Exec()`, `$SDK.Testing.*`, `$SDK.Log.*` | ✓ |

```powershell
# Common worker methods - requires abstract methods to be defined first:
#   Exists(), Create(), Exec()
function Add-CommonWorkerMethods {
    param($Worker, $SDK)

    Add-ScriptMethods $Worker @{
        # Ensure VM exists, create if not
        Ensure = {
            if (-not $this.Exists()) {
                return $this.Create()
            }
            return $true
        }

        # Test: execute command, check pattern, record result
        Test = {
            param(
                [string]$TestId,
                [string]$Name,
                [string]$Command,
                [string]$ExpectedPattern
            )

            $SDK.Log.Debug("Running test: $Name")

            try {
                $result = $this.Exec($Command)
                $pass = $result.Success -and ($result.Output -join "`n") -match $ExpectedPattern

                $testResult = @{
                    Test = $TestId
                    Name = $Name
                    Pass = $pass
                    Output = $result.Output
                    Error = $result.Error
                }

                $SDK.Testing.Record($testResult)

                if ($pass) {
                    $SDK.Log.Write("[PASS] $Name", "Green")
                } else {
                    $SDK.Log.Write("[FAIL] $Name", "Red")
                    if ($result.Error) { $SDK.Log.Error("  Error: $($result.Error)") }
                }

                return $testResult
            }
            catch {
                $SDK.Log.Write("[FAIL] $Name - Exception: $_", "Red")
                $testResult = @{ Test = $TestId; Name = $Name; Pass = $false; Error = $_.ToString() }
                $SDK.Testing.Record($testResult)
                return $testResult
            }
        }
    }
}
```

**Required abstract methods** (must be defined by hypervisor module before calling helper):
- `Exists()` - returns bool
- `Create()` - creates VM, returns bool
- `Exec($Command)` - returns `@{ Success; Output; Error }`

### modules/Multipass.ps1 (MODIFY EXISTING)

Remove `Ensure` from `$mod.Worker.Methods` (moves to helpers/Worker.ps1). Workers are created dynamically:

**Config options:**
| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| Name | Yes | - | VM name |
| CPUs | No | 2 | Number of CPUs |
| Memory | No | "4G" | RAM allocation |
| Disk | No | "40G" | Disk size |
| Network | No | - | Network adapter name |
| CloudInit | No | - | Path to cloud-init.yaml |
| Image | No | - | Ubuntu image (default LTS) |

```powershell
$mod.Worker = @{
    Properties = @{
        Rendered = { ... }  # Merges Config with Defaults
        Name = { return $this.Rendered.Name }
        CPUs = { return $this.Rendered.CPUs }
        Memory = { return $this.Rendered.Memory }
        Disk = { return $this.Rendered.Disk }
        Network = { return $this.Rendered.Network }
        CloudInit = { return $this.Rendered.CloudInit }
    }
    Methods = @{
        # Hypervisor-specific methods:
        Info, Addresses, Address,
        Exists, Running, Create,
        Start, Shutdown, UntilShutdown,
        Status, UntilInstalled, Setup,  # Setup stays here (uses UntilInstalled)
        Mount, Unmount, Mounts, Mounted, Pull, Push,
        Exec, Shell,
        Destroy

        # REMOVED: Ensure (now in helpers/Worker.ps1)
    }
}

Add-ScriptMethods $Multipass @{
    Worker = {
        param($Base)
        Add-ScriptProperties $Base $mod.Worker.Properties
        Add-ScriptMethods $Base $mod.Worker.Methods

        # Add common methods (Ensure, Test)
        . "$PSScriptRoot\..\helpers\Worker.ps1"
        Add-CommonWorkerMethods $Base $mod.SDK

        return $Base
    }
}

# Example: Create a worker dynamically
# $worker = $SDK.Multipass.Worker(@{
#     Config = @{
#         Name = "my-runner"
#         CPUs = 2
#         Memory = "4G"
#         Disk = "15G"
#         Network = "Ethernet"      # optional
#         CloudInit = "path/to/cloud-init.yaml"  # optional
#     }
# })
```

### modules/Vbox.ps1 (ADD WORKER PATTERN)

Vbox.ps1 already has extensive helper methods. The Worker pattern should forward to these existing methods:

**Existing $SDK.Vbox methods:**
- Lifecycle: `Exists`, `Running`, `Start`, `Shutdown`, `UntilShutdown`, `Pause`, `Resume`, `Bump`
- Creation: `Create` (full VM with disk, DVD, network), `Destroy`
- Config: `Configure`, `Optimize`, `Hypervisor` (nested virt)
- Storage: `Drives`, `Attach`, `Give`, `Delete`, `Eject`, `Insert`
- Network: `GetGuestAdapter`

**Config options** (aligned with Multipass):
| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| Name | Yes | - | VM name |
| CPUs | No | 2 | Number of CPUs |
| Memory | No | 4096 | RAM in MB |
| Disk | No | 40960 | Disk size in MB |
| Network | No | - | Network adapter name |
| IsoPath | **Yes** | - | Path to autoinstall ISO |
| MediumPath | No | derived | Path for VM disk file |
| SSHUser | No | "ubuntu" | SSH username |
| SSHHost | No | "localhost" | SSH host |
| SSHPort | No | 2222 | SSH port |

```powershell
$mod.Configurator = @{
    Defaults = @{
        CPUs = 2
        Memory = 4096
        Disk = 40960
        SSHUser = "ubuntu"
        SSHHost = "localhost"
        SSHPort = 2222
    }
}

$mod.Worker = @{
    Properties = @{
        Rendered = {
            $config = $this.Config
            $defaults = if ($this.Defaults) { $this.Defaults } else { $mod.Configurator.Defaults }
            $rendered = & $mod.Configurator.Defaulter $config $defaults
            # Derive MediumPath from Name if not specified
            if (-not $rendered.MediumPath) {
                $rendered.MediumPath = "$env:TEMP\$($rendered.Name).vdi"
            }
            $this | Add-Member -MemberType NoteProperty -Name Rendered -Value $rendered -Force
            return $rendered
        }
        Name = { return $this.Rendered.Name }
        CPUs = { return $this.Rendered.CPUs }
        Memory = { return $this.Rendered.Memory }
        Disk = { return $this.Rendered.Disk }
        Network = { return $this.Rendered.Network }
        IsoPath = { return $this.Rendered.IsoPath }
        MediumPath = { return $this.Rendered.MediumPath }
        SSHUser = { return $this.Rendered.SSHUser }
        SSHHost = { return $this.Rendered.SSHHost }
        SSHPort = { return $this.Rendered.SSHPort }
    }
    Methods = @{
        # Forward to existing $SDK.Vbox methods
        Exists = {
            return $mod.SDK.Vbox.Exists($this.Name)
        }
        Running = {
            return $mod.SDK.Vbox.Running($this.Name)
        }
        Create = {
            return $mod.SDK.Vbox.Create(
                $this.Name,
                $this.MediumPath,
                $this.IsoPath,
                $this.Network,
                "Ubuntu_64",  # OSType
                "efi",        # Firmware
                "SATA",       # ControllerName
                $this.Disk,
                $this.Memory,
                $this.CPUs
            )
        }
        Start = {
            param([string]$Type = "headless")
            return $mod.SDK.Vbox.Start($this.Name, $Type)
        }
        Shutdown = {
            param([bool]$Force)
            return $mod.SDK.Vbox.Shutdown($this.Name, $Force)
        }
        UntilShutdown = {
            param([int]$TimeoutSeconds)
            return $mod.SDK.Vbox.UntilShutdown($this.Name, $TimeoutSeconds)
        }
        Destroy = {
            return $mod.SDK.Vbox.Destroy($this.Name)
        }
        Exec = {
            param([string]$Command)
            return $mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)
        }
    }
}

Add-ScriptMethods $Vbox @{
    Worker = {
        param(
            [Parameter(Mandatory = $true)]
            [ValidateScript({ $null -ne $_.Config -and $null -ne $_.Config.IsoPath })]
            $Base
        )
        Add-ScriptProperties $Base $mod.Worker.Properties
        Add-ScriptMethods $Base $mod.Worker.Methods

        # Add common methods (Ensure, Test)
        . "$PSScriptRoot\..\helpers\Worker.ps1"
        Add-CommonWorkerMethods $Base $mod.SDK

        return $Base
    }
}

# Example: Create a VBox worker (IsoPath mandatory)
# $vm = $SDK.Vbox.Worker(@{
#     Config = @{
#         Name = "autoinstall-test"
#         IsoPath = "/tmp/ubuntu-autoinstall.iso"  # mandatory
#         Network = "Ethernet"  # optional, same as Multipass
#     }
# })
```

### modules/CloudInitTest.ps1 (NEW)

Test module for cloud-init/incremental testing using Multipass workers.

Uses `$SDK.Settings.Virtualization.Runner` from `vm.config.yaml` as base config:

```powershell
$CloudInitTest = New-Object PSObject

Add-ScriptMethods $CloudInitTest @{
    Run = {
        param(
            [int]$Layer,
            [hashtable]$Overrides = @{}
        )

        # Build cloud-init for the specified layer
        $mod.SDK.Log.Info("Building cloud-init for layer $Layer...")
        $built = $mod.SDK.Builder.Build($Layer)
        if (-not $built) {
            throw "Failed to build cloud-init for layer $Layer"
        }

        # Get cloud-init path from Builder artifacts
        $artifacts = $mod.SDK.Builder.Artifacts
        if (-not $artifacts -or -not $artifacts.cloud_init) {
            throw "No cloud-init artifact found after build."
        }

        # Start with vm.config.yaml runner settings
        $baseConfig = $mod.SDK.Settings.Virtualization.Runner

        # Build final config: base -> cloud-init path -> overrides
        $config = @{}
        foreach ($key in $baseConfig.Keys) { $config[$key] = $baseConfig[$key] }
        $config.CloudInit = "$($mod.SDK.Root())/$($artifacts.cloud_init)"
        foreach ($key in $Overrides.Keys) { $config[$key] = $Overrides[$key] }

        # Create worker dynamically
        $worker = $mod.SDK.Multipass.Worker(@{ Config = $config })

        try {
            $mod.SDK.Log.Info("Setting up cloud-init test worker: $($config.Name)")
            $worker.Setup($true)

            $mod.SDK.Testing.Reset()
            foreach ($layer in 1..$Layer) {
                foreach ($fragment in $mod.SDK.Fragments.At($layer)) {
                    $worker.Test(
                        $fragment.Name,
                        "Test $($fragment.Name)",
                        $fragment.TestCommand,
                        $fragment.ExpectedPattern
                    )
                }
            }
            $mod.SDK.Testing.Summary()

            return @{
                Success = ($mod.SDK.Testing.FailCount -eq 0)
                Results = $mod.SDK.Testing.Results
                WorkerName = $config.Name
            }
        }
        finally {
            # Cleanup handled by caller or explicit call
        }
    }

    Cleanup = {
        param([string]$Name)
        # Default to vm.config.yaml runner name
        if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Runner.Name }
        if ($mod.SDK.Multipass.Exists($Name)) {
            $mod.SDK.Multipass.Destroy($Name)
        }
    }
}

$SDK.Extend("CloudInitTest", $CloudInitTest)
```

### modules/AutoinstallTest.ps1 (NEW)

Test module for autoinstall/ISO testing using VBox workers.

Uses `$SDK.Settings.Virtualization.Vbox` from `vm.config.yaml` as base config:

```powershell
$AutoinstallTest = New-Object PSObject

Add-ScriptMethods $AutoinstallTest @{
    Run = {
        param(
            [hashtable]$Overrides = @{}
        )

        # Get ISO path from Builder artifacts
        $artifacts = $mod.SDK.Builder.Artifacts
        if (-not $artifacts -or -not $artifacts.iso) {
            throw "No ISO artifact found. Build the ISO first."
        }

        # Start with vm.config.yaml vbox settings
        $baseConfig = $mod.SDK.Settings.Virtualization.Vbox

        # Build final config: base -> ISO path -> overrides
        $config = @{}
        foreach ($key in $baseConfig.Keys) { $config[$key] = $baseConfig[$key] }
        $config.IsoPath = $artifacts.iso
        # Map vm.config.yaml keys to worker config keys
        if ($config.disk_size) { $config.Disk = $config.disk_size; $config.Remove("disk_size") }
        foreach ($key in $Overrides.Keys) { $config[$key] = $Overrides[$key] }

        # Create worker dynamically
        $worker = $mod.SDK.Vbox.Worker(@{ Config = $config })

        try {
            $mod.SDK.Log.Info("Setting up autoinstall test worker: $($config.Name)")
            $worker.Ensure()
            $worker.Start()

            # Wait for SSH (no UntilInstalled on VBox yet)
            $mod.SDK.Log.Info("Waiting for SSH availability...")
            $mod.SDK.Network.WaitForSSH($worker.SSHHost, $worker.SSHPort, 600)

            $mod.SDK.Testing.Reset()
            foreach ($fragment in $mod.SDK.Fragments.IsoRequired()) {
                $worker.Test(
                    $fragment.Name,
                    "Test $($fragment.Name)",
                    $fragment.TestCommand,
                    $fragment.ExpectedPattern
                )
            }
            $mod.SDK.Testing.Summary()

            return @{
                Success = ($mod.SDK.Testing.FailCount -eq 0)
                Results = $mod.SDK.Testing.Results
                WorkerName = $config.Name
            }
        }
        finally {
            # Cleanup handled by caller or explicit call
        }
    }

    Cleanup = {
        param([string]$Name)
        # Default to vm.config.yaml vbox name
        if (-not $Name) { $Name = $mod.SDK.Settings.Virtualization.Vbox.Name }
        if ($mod.SDK.Vbox.Exists($Name)) {
            $mod.SDK.Vbox.Destroy($Name)
        }
    }
}

$SDK.Extend("AutoinstallTest", $AutoinstallTest)
```

### modules/Testing.ps1 (NEW - MERGED WITH TestLevels)

Test execution framework with layer-based test level derivation:

```powershell
$Testing = New-Object PSObject -Property @{
    Results = @()
    PassCount = 0
    FailCount = 0
}

# All is a ScriptProperty (live getter, no caching)
Add-ScriptProperties $Testing @{
    All = {
        return $mod.SDK.Fragments.Layers | ForEach-Object { $_.Layer } | Sort-Object -Unique
    }
}

Add-ScriptMethods $Testing @{
    # Result tracking
    Reset = {
        $this.Results = @()
        $this.PassCount = 0
        $this.FailCount = 0
    }
    Record = {
        param([hashtable]$Result)
        $this.Results += $Result
        if ($Result.Pass) { $this.PassCount++ } else { $this.FailCount++ }
    }
    Summary = {
        $mod.SDK.Log.Write("")
        $mod.SDK.Log.Write("========================================", "Cyan")
        $mod.SDK.Log.Write(" Test Summary", "Cyan")
        $mod.SDK.Log.Write("========================================", "Cyan")
        $mod.SDK.Log.Write("  Total:  $($this.PassCount + $this.FailCount)")
        $mod.SDK.Log.Write("  Passed: $($this.PassCount)", "Green")
        $failColor = if ($this.FailCount -gt 0) { "Red" } else { "Green" }
        $mod.SDK.Log.Write("  Failed: $($this.FailCount)", $failColor)
    }

    # Layer-based test derivation (merged from TestLevels)
    Fragments = {
        param([int]$Layer)
        return $mod.SDK.Fragments.UpTo($Layer) | ForEach-Object { $_.Name }
    }
    Verifications = {
        param([int]$Layer)
        $fragments = $mod.SDK.Fragments.At($Layer)
        return $fragments | ForEach-Object { "Test-$($_.Name)Fragment" }
    }
}
$SDK.Extend("Testing", $Testing)
```

---

## Target Test Script Size

After migration, test scripts should be ~50-100 lines, not 350-575 lines.

**Invoke-IncrementalTest.ps1** should become:
```powershell
param([int]$Layer, [switch]$SkipCleanup)

. "$PSScriptRoot\SDK.ps1"

# Setup builder (Build is called by CloudInitTest.Run with Layer)
$SDK.Builder.Stage()

# Run cloud-init tests (builds for layer, then tests)
$result = $SDK.CloudInitTest.Run($Layer)

# Cleanup
if (-not $SkipCleanup) {
    $SDK.CloudInitTest.Cleanup()
    $SDK.Builder.Destroy()
}

exit $(if ($result.Success) { 0 } else { 1 })
```

**Invoke-AutoinstallTest.ps1** should become:
```powershell
param([switch]$SkipCleanup)

. "$PSScriptRoot\SDK.ps1"

# Assumes ISO was already built (artifacts.iso populated)
# Run autoinstall tests (ISO path queried from artifacts automatically)
$result = $SDK.AutoinstallTest.Run(@{
    Network = "Ethernet"  # optional overrides
})

# Cleanup
if (-not $SkipCleanup) {
    $SDK.AutoinstallTest.Cleanup()
}

exit $(if ($result.Success) { 0 } else { 1 })
```

---

## Dependencies

- All fragments must have `build.yaml` before `$SDK.Fragments.Discover()` works
- Python builder-sdk changes (BOOK_0 PLAN.md) should complete first
- vm.config.yaml must be the only config source (remove vm.config.ps1 references)

---

---

## Required Changes Outside SDK

### Makefile Updates

The Makefile needs a `LAYER` option for layer-based cloud-init builds:

```makefile
# Fragment selection (override via command line)
INCLUDE ?=
EXCLUDE ?=
LAYER ?=

# Generate cloud-init config (renders scripts internally)
cloud-init: output/cloud-init.yaml

output/cloud-init.yaml: $(CLOUD_INIT_FRAGMENTS) $(SCRIPTS) $(CONFIGS)
ifdef LAYER
	python3 -m builder render cloud-init -o $@ --layer $(LAYER)
else
	python3 -m builder render cloud-init -o $@ $(INCLUDE) $(EXCLUDE)
endif
```

The Python builder also needs `--layer` / `-l` option support in `render cloud-init` command.

### Builder Methods Update

Add `Clean` method and update `Build` to call it:

```powershell
Add-ScriptMethods $Builder @{
    Clean = {
        $make = @("cd /home/ubuntu/infra-host", "make clean") -join " && "
        $result = $this.Exec($make)
        return $result.Success
    }

    Build = {
        param([int]$Layer)

        # Always clean first to prevent stale artifacts between layers
        $cleaned = $this.Clean()
        if (-not $cleaned) {
            $mod.SDK.Log.Warn("Clean failed, continuing with build...")
        }

        $target = if ($Layer) {
            "make cloud-init LAYER=$Layer"
        } else {
            "make all"
        }

        $make = @("cd /home/ubuntu/infra-host", $target) -join " && "
        $make_result = $this.Exec($make)
        return $make_result.Success
    }

    # ... existing Stage, InstallDependencies, Flush methods ...
}
```

---

## Implementation Order

1. **Create Logger.ps1** - must load first so other modules can use it
2. **Fix path references** (SDK.ps1) - required for module loading
3. **Create helpers/Worker.ps1** - `Add-CommonWorkerMethods()` for Ensure, Test
4. **Modify Multipass.ps1** - call Worker.ps1 helper in `$SDK.Multipass.Worker()`
5. **Modify Vbox.ps1** - add `$SDK.Vbox.Worker()` following Multipass pattern
6. **Create Fragments.ps1** - discovery-based fragment lookup
7. **Modify Network.ps1** - absorb Test-ViaSSH, add `WaitForSSH()`
8. **Create Testing.ps1** - test framework with `All`, `Fragments()`, `Verifications()`
9. **Create CloudInitTest.ps1** - multipass-based cloud-init testing module
10. **Create AutoinstallTest.ps1** - vbox-based autoinstall/ISO testing module
11. **Migrate Verifications.ps1** - use Worker.Test() method
12. **Refactor test scripts** - should shrink to ~15 lines
13. **Remove vm.config.ps1** references - use SDK.Settings

---

## Notes

- The SDK extension pattern (`$SDK.Extend()`) is sound and should be preserved
- `helpers/PowerShell.ps1` provides utilities used by all modules
- `helpers/Config.ps1` is for YAML merging, separate from test-level Config.ps1
- **Logger.ps1** must load first so all other modules can use `$SDK.Log.*`
- **Logger.Write()** is the core method - all other log methods call it (no direct Write-Host)
- **helpers/Worker.ps1** provides `Add-CommonWorkerMethods()` for: Ensure, Test
- **Multipass.ps1** removes Ensure from `$mod.Worker.Methods`, keeps Setup (uses UntilInstalled)
- **Multipass workers** optionally accept CloudInit path in Config
- **Vbox.ps1** forwards to existing helper methods, implements Worker pattern
- **Vbox workers** mandatorily require IsoPath in Config
- **No singleton $SDK.Runner** - workers are created dynamically
- **Testing.All** is a ScriptProperty (live getter), `Fragments()` and `Verifications()` are methods
- **Network.ps1** absorbs Test-ViaSSH, adds `WaitForSSH()` for Vbox
- **CloudInitTest.ps1** uses `vm.config.yaml` runner section + `$SDK.Builder.Artifacts.cloud_init`
- **AutoinstallTest.ps1** uses `vm.config.yaml` vbox section + `$SDK.Builder.Artifacts.iso`
- **Test scripts** reduced to ~15 lines - just call test modules and handle cleanup
