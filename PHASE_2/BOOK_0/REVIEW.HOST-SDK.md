# Code Review: HOST-SDK Structure

## Review Items

### 1. General.ps1 and Worker.ps1 Merge

**Clarification**: Worker.ps1 should adopt General.ps1's module shape. The methods in General.ps1 existed for workers.

**Current State**:
- Worker.ps1 exports a function `Add-CommonWorkerMethods` - should be a module method instead
- General.ps1 methods (`UntilInstalled`, `Errored`) were meant for workers but call `Network.SSH` directly

**Research - $this.Exec Viability**:
- VboxWorker.Exec already uses SSH internally: `$mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)`
- MultipassWorker.Exec uses `multipass exec`
- Both return `@{Output; ExitCode; Success}`

**Conclusion**: General.ps1 methods should use `$this.Exec()` instead of `Network.SSH`. This would work for both worker types since each implements Exec appropriately.

**Proposed Merge**:
- Move General.ps1 methods into Worker.ps1
- Convert `Add-CommonWorkerMethods` from exported function to module method
- Update methods to use `$this.Exec("cloud-init status --wait")` instead of `Network.SSH(...)`

---

### 2. Invoke-*.ps1 Scripts Use Old API

**Invoke-AutoinstallTest.ps1**:
```powershell
# Current (broken):
$result = $SDK.AutoinstallTest.Run(@{ ... })
$SDK.AutoinstallTest.Cleanup()

# Should be:
$result = $SDK.Autoinstall.Test.Run(@{ ... })
$SDK.Autoinstall.Cleanup()
```

**Invoke-IncrementalTest.ps1**:
```powershell
# Current (broken):
$result = $SDK.CloudInitTest.Run($Layer)
$SDK.CloudInitTest.Cleanup()

# Should be:
$result = $SDK.CloudInit.Test.Run($Layer)
$SDK.CloudInit.Cleanup()
```

---

### 3. SDK.Extend Third Argument

**Proposal**: Update `SDK.Extend` to accept optional third argument for target object.

**Current**:
```powershell
Extend = {
    param([string]$ModuleName, $ModuleObject)
    $this | Add-Member -MemberType NoteProperty -Name $ModuleName -Value $ModuleObject -Force
}
```

**Proposed**:
```powershell
Extend = {
    param([string]$ModuleName, $ModuleObject, $Target = $this)
    $Target | Add-Member -MemberType NoteProperty -Name $ModuleName -Value $ModuleObject -Force
}
```

**NoteProperty Instances (submodule candidates)**:

| File | Line | Current Usage | Candidate? |
|------|------|---------------|------------|
| SDK.ps1 | 32 | `$this \| Add-Member ... $ModuleName` | Base impl |
| AutoinstallTest.ps1 | 27 | `$SDK.Autoinstall \| Add-Member ... Test` | **Yes** |
| CloudInitTest.ps1 | 27 | `$SDK.CloudInit \| Add-Member ... Test` | **Yes** |
| Verifications.ps1 | 195 | `$SDK.Testing \| Add-Member ... Verifications` | **Yes** |
| Multipass.ps1 | 63 | `$this \| Add-Member ... Rendered` | No (caching) |
| Vbox.ps1 | 45 | `$this \| Add-Member ... Rendered` | No (caching) |

Submodules could use: `$SDK.Extend("Test", $TestObject, $SDK.CloudInit)`

---

### 4. SDK.Settings - Build Layers Config

**Request**: Add hashtable for `build_layers.yaml` values, similar to `Virtualization`.

**Current**: Fragments.ps1 loads `build_layers.yaml` directly into `$mod.LayersConfig`.

**Proposed**: Settings.ps1 should expose:
```powershell
$SDK.Settings.BuildLayers  # From build_layers.yaml
```

Then Fragments.ps1 would reference `$mod.SDK.Settings.BuildLayers` instead of loading the file itself.

---

### 5. CreateWorker → Worker Rename

**Instances to rename** (where "Worker" is not reserved):

| File | Current | Proposed |
|------|---------|----------|
| CloudInit.ps1:28 | `CreateWorker = {` | `Worker = {` |
| CloudInit.ps1 (caller) | `$mod.SDK.CloudInit.CreateWorker(...)` | `$mod.SDK.CloudInit.Worker(...)` |
| CloudInitTest.ps1:13 | `$mod.SDK.CloudInit.CreateWorker(...)` | `$mod.SDK.CloudInit.Worker(...)` |
| Autoinstall.ps1:16 | `CreateWorker = {` | `Worker = {` |
| Autoinstall.ps1 (caller) | (line 18 internal) | N/A |
| AutoinstallTest.ps1:13 | `$mod.SDK.Autoinstall.CreateWorker(...)` | `$mod.SDK.Autoinstall.Worker(...)` |

**Reserved** (do not rename):
- `$SDK.Multipass.Worker` - factory method
- `$SDK.Vbox.Worker` - factory method

---

### 6. Functions Starting with "Get"

| File | Method | Usage |
|------|--------|-------|
| Autoinstall.ps1:11 | `GetArtifacts` | Gets artifacts, throws if no ISO |
| Network.ps1:19 | `GetGuestAdapter` | Gets network adapter by name |
| Vbox.ps1:159 | `GetGuestAdapter` | Wrapper for Network.GetGuestAdapter |

---

## SDK Shape Documentation

### Core

```
$SDK
  .Path           : string                    # Path to SDK.ps1
  .Root()         → string                    # Git repository root
  .Extend($Name, $Object, $Target?)           # Add module to SDK (or target)
  .Job($ScriptBlock, $Timeout, $Env) → bool   # Run background job, returns true if timed out
```

### $SDK.Log

```
$SDK.Log
  .Level          : string                    # "Info" | "Debug"
  .Path           : string                    # Transcript path (if active)
  .Write($Message, $ForegroundColor, $BackgroundColor)
  .Debug($Message)
  .Info($Message)
  .Warn($Message)
  .Error($Message)
  .Step($Message, $Current, $Total)
  .Start($Path)                               # Start transcript
  .Stop()                                     # Stop transcript
```

### $SDK.Settings

```
$SDK.Settings
  .KeyPath        : string                    # SSH key path
  .Load($Path)    → hashtable                 # Load YAML config file
  .Virtualization : hashtable                 # From vm.config.yaml
  .BuildLayers    : hashtable                 # From build_layers.yaml (PROPOSED)

  # Dynamic properties from *.config.yaml files (PascalCase):
  .Identity       : hashtable                 # identity.config.yaml
  .Network        : hashtable                 # network.config.yaml
  .Image          : hashtable                 # image.config.yaml
  .Storage        : hashtable                 # storage.config.yaml
  .Testing        : hashtable                 # testing.config.yaml
  .Smtp           : hashtable                 # smtp.config.yaml
  .Cockpit        : hashtable                 # cockpit.config.yaml
  .ClaudeCode     : hashtable                 # claude_code.config.yaml
  .CopilotCli     : hashtable                 # copilot_cli.config.yaml
  .Opencode       : hashtable                 # opencode.config.yaml
```

### $SDK.Network

```
$SDK.Network
  .GetGuestAdapter($AdapterName) → NetAdapter
  .TestSSH($Address, $Port) → bool
  .WaitForSSH($Address, $Port, $TimeoutSeconds, $Throw) → bool
  .SSH($Username, $Address, $Port, $Command, $KeyPath) → @{Output; ExitCode; Success}
```

### $SDK.Worker

```
$SDK.Worker
  # After merge with General.ps1:
  .AddCommonMethods($Worker)                  # Adds Ensure, Test, UntilInstalled, Errored to worker
```

### $SDK.Multipass

```
$SDK.Multipass
  .Invoke(...args) → @{Output; ExitCode; Success}
  .Worker($Base) → MultipassWorker

  # VM Info
  .Info($VMName, $Format) → object
  .Addresses($VMName) → string[]
  .Address($VMName) → string
  .List() → object[]
  .Status($VMName) → string
  .Mounts($VMName) → object
  .Mounted($VMName, $HostPath) → object

  # VM Lifecycle
  .Exists($VMName) → bool
  .Running($VMName) → bool
  .Start($VMName) → bool
  .UntilInstalled($VMName) → bool
  .Shutdown($VMName, $Force) → bool
  .UntilShutdown($VMName, $TimeoutSeconds) → bool

  # VM Creation/Destruction
  .Create($VMName, $CloudInitPath, $Network, $CPUs, $Memory, $Disk, $Image) → bool
  .Destroy($VMName)
  .Purge() → bool

  # File Sharing
  .Mount($VMName, $HostPath, $GuestPath) → bool
  .Unmount($VMName, $GuestPath) → bool
  .Transfer($Source, $Destination) → bool

  # Execution
  .Exec($VMName, $Command, $WorkingDir) → @{Output; ExitCode; Success}
  .Shell($VMName)
```

### MultipassWorker (from $SDK.Multipass.Worker)

```
MultipassWorker
  .Config         : hashtable
  .Defaults       : hashtable
  .Rendered       : hashtable                 # Merged config
  .Name           : string
  .CPUs           : int
  .Memory         : string
  .Disk           : string
  .Network        : string
  .CloudInit      : string

  # Lifecycle (delegate to $SDK.Multipass)
  .Info() → object
  .Addresses() → string[]
  .Address() → string
  .Exists() → bool
  .Running() → bool
  .Create() → bool
  .Destroy() → bool
  .Start() → bool
  .Shutdown($Force) → bool
  .UntilShutdown($TimeoutSeconds) → bool
  .Status() → string
  .UntilInstalled() → bool
  .Setup($FailOnNotInitialized) → bool

  # File Sharing
  .Mount($SourcePath, $TargetPath) → bool
  .Unmount($TargetPath) → bool
  .Mounts() → object
  .Mounted($HostPath) → object
  .Pull($Source, $Destination) → bool
  .Push($Source, $Destination) → bool

  # Execution
  .Exec($Command, $WorkingDir) → @{Output; ExitCode; Success}
  .Shell()

  # From Add-CommonWorkerMethods (to become SDK.Worker.AddCommonMethods):
  .Ensure() → bool
  .Test($TestId, $Name, $Command, $ExpectedPattern) → @{...}
  .UntilInstalled() → bool                    # (from General.ps1 merge)
  .Errored() → bool                           # (from General.ps1 merge)
```

### $SDK.Vbox

```
$SDK.Vbox
  .Path           : string                    # VBoxManage.exe path
  .Invoke(...args) → @{Output; ExitCode; Success}
  .Worker($Base) → VboxWorker

  # Network
  .GetGuestAdapter($AdapterName) → string

  # Medium Helpers
  .Drives($VMName) → @{Controller; Port; Device; Path; IsDVD}[]
  .Attach($VMName, $ControllerName, $MediumPath, $Type, $Port, $Device) → bool
  .Give($VMName, $ControllerName, $MediumPath, $Size)
  .Delete($MediumPath)

  # DVD
  .Eject($VMName)
  .Insert($VMName, $ISOPath)

  # Lifecycle
  .Exists($VMName) → bool
  .Running($VMName) → bool
  .Pause($VMName) → bool
  .Resume($VMName) → bool
  .Bump($VMName) → bool
  .Start($VMName, $Type) → bool
  .Shutdown($VMName, $Force) → bool
  .UntilShutdown($VMName, $TimeoutSeconds) → bool

  # Configuration
  .Configure($VMName, $Settings) → bool
  .Optimize($VMName) → bool
  .Hypervisor($VMName) → bool

  # Creation/Destruction
  .Destroy($VMName)
  .Create($VMName, $MediumPath, $DVDPath, $AdapterName, $OSType, $Firmware, $ControllerName, $Size, $RAM, $CPU, $Optimize, $Hypervisor) → bool
```

### VboxWorker (from $SDK.Vbox.Worker)

```
VboxWorker
  .Config         : hashtable
  .Defaults       : hashtable
  .Rendered       : hashtable
  .Name           : string
  .CPUs           : int
  .Memory         : int
  .Disk           : int
  .Network        : string
  .IsoPath        : string
  .MediumPath     : string
  .SSHUser        : string
  .SSHHost        : string
  .SSHPort        : int

  # Lifecycle
  .Exists() → bool
  .Running() → bool
  .Start($Type) → bool
  .Shutdown($Force) → bool
  .UntilShutdown($TimeoutSeconds) → bool
  .Destroy() → bool
  .Create() → bool

  # Execution
  .Exec($Command) → @{Output; ExitCode; Success}

  # From Add-CommonWorkerMethods:
  .Ensure() → bool
  .Test($TestId, $Name, $Command, $ExpectedPattern) → @{...}
  .UntilInstalled() → bool                    # (from General.ps1 merge)
  .Errored() → bool                           # (from General.ps1 merge)
```

### $SDK.Builder

```
$SDK.Builder (extends MultipassWorker)
  .Packages       : string[]                  # Required apt packages
  .Config         : hashtable                 # From Settings.Virtualization.Builder
  .Defaults       : hashtable

  # Build Operations
  .Clean() → bool
  .Flush() → bool                             # Destroy all registered runners + self
  .InstallDependencies() → bool
  .Build($Layer) → bool
  .Stage() → bool                             # Setup + Mount + InstallDependencies
  .RegisterRunner($Name, $Worker) → Worker

  # Inherited from MultipassWorker: all Multipass methods
```

### $SDK.Fragments

```
$SDK.Fragments
  .Layers         : @{Name; Path; Order; Layer; IsoRequired}[]  # All fragments sorted by Order
  .UpTo($Layer) → @{...}[]                    # Fragments with layer ≤ $Layer
  .At($Layer) → @{...}[]                      # Fragments at exactly $Layer
  .IsoRequired() → @{...}[]                   # Fragments with iso_required=true
  .LayerName($Layer) → string                 # Human-readable layer name
```

### $SDK.Testing

```
$SDK.Testing
  .Results        : hashtable[]
  .PassCount      : int
  .FailCount      : int
  .All            : int[]                     # All layer numbers

  .Reset()
  .Record($Result)
  .Summary()
  .Fragments($Layer) → string[]               # Fragment names up to layer
  .LevelName($Layer) → string                 # Layer name
  .LevelFragments($Layer) → string[]          # Fragment names up to layer
  .IncludeArgs($Layer) → string               # "-i frag1 -i frag2 ..."
```

### $SDK.Testing.Verifications (submodule)

```
$SDK.Testing.Verifications
  .Fork($Test, $Decision, $Reason)            # Log fork decision
  .Run($Worker, $Layer)                       # Run all verifications up to layer

  # Layer verification methods (each takes $Worker):
  .Network($Worker)                           # Layer 1: 6.1.1-6.1.5
  .Kernel($Worker)                            # Layer 2: 6.2.1-6.2.2
  .Users($Worker)                             # Layer 3: 6.3.1-6.3.4
  # Layers 4-18: SSH, UFW, System, MSMTP, PackageSecurity, SecurityMonitoring,
  #              Virtualization, Cockpit, ClaudeCode, CopilotCLI, OpenCode,
  #              UI, PackageManagerUpdates, UpdateSummary, NotificationFlush
  #              (not yet implemented)
```

### $SDK.CloudInit

```
$SDK.CloudInit
  .Build($Layer) → artifacts                  # Build cloud-init, return artifacts (idempotent)
  .Clean() → bool                             # Delegate to Builder.Clean()
  .Cleanup($Name)                             # Destroy runner by name
  .Worker($Layer, $Overrides) → MultipassWorker  # (renamed from CreateWorker)
```

### $SDK.CloudInit.Test (submodule)

```
$SDK.CloudInit.Test
  .Run($Layer, $Overrides) → @{Success; Results; Worker}
```

### $SDK.Autoinstall

```
$SDK.Autoinstall
  .GetArtifacts() → artifacts                 # Get artifacts (throws if no ISO)
  .Build($Layer) → artifacts                  # Build autoinstall (idempotent)
  .Clean() → bool                             # Delegate to Builder.Clean()
  .Cleanup($Name)                             # Destroy VBox VM by name
  .Worker($Overrides) → VboxWorker            # (renamed from CreateWorker)
```

### $SDK.Autoinstall.Test (submodule)

```
$SDK.Autoinstall.Test
  .Run($Overrides) → @{Success; Results; Worker}
```

---

## Summary

| Item | Status | Action |
|------|--------|--------|
| General.ps1 + Worker.ps1 | Merge | Merge General into Worker, use $this.Exec |
| SDK.Extend | Enhancement | Add optional $Target parameter |
| SDK.Settings.BuildLayers | New | Add build_layers.yaml config |
| CreateWorker → Worker | Rename | CloudInit, Autoinstall |
| Invoke-*.ps1 | Broken | Update API paths |
| Submodule pattern | Refactor | Use SDK.Extend with $Target |
