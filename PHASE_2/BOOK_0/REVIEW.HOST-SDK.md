# HOST-SDK Shape Documentation

```yaml
SDK:
  Path: string                                    # Path to SDK.ps1
  Root: () → string                               # Git repository root
  Extend: ($Name, $Object, $Target?) → void       # Add module to SDK (or target)
  Job: ($ScriptBlock, $Timeout, $Env) → bool      # Run background job, returns true if timed out

  Log:
    Level: string                                 # "Info" | "Debug"
    Path: string                                  # Transcript path (if active)
    Write: ($Message, $ForegroundColor?, $BackgroundColor?) → void
    Debug: ($Message) → void
    Info: ($Message) → void
    Warn: ($Message) → void
    Error: ($Message) → void
    Step: ($Message, $Current, $Total) → void
    Start: ($Path) → void                         # Start transcript
    Stop: () → void                               # Stop transcript

  Settings:
    KeyPath: string                               # SSH key path
    Load: ($Path) → hashtable                     # Load YAML config file
    Virtualization: hashtable                     # From vm.config.yaml
    Layers: hashtable                             # From build_layers.yaml (PROPOSED)
    # Dynamic properties from *.config.yaml (PascalCase):
    Identity: hashtable
    Network: hashtable
    Image: hashtable
    Storage: hashtable
    Testing: hashtable
    Smtp: hashtable
    Cockpit: hashtable
    ClaudeCode: hashtable
    CopilotCli: hashtable
    Opencode: hashtable

  Network:
    GetGuestAdapter: ($AdapterName) → NetAdapter
    TestSSH: ($Address, $Port?) → bool
    WaitForSSH: ($Address, $Port?, $TimeoutSeconds?, $Throw?) → bool
    SSH: ($Username, $Address, $Port?, $Command?, $KeyPath?) → ExecResult

  Worker:
    AddCommonMethods: ($Worker) → void            # Adds Ensure, Test, UntilInstalled, Errored

  Multipass:
    Invoke: (...args) → ExecResult
    Worker: ($Base) → MultipassWorker
    # VM Info
    Info: ($VMName, $Format?) → object
    Addresses: ($VMName) → string[]
    Address: ($VMName) → string
    List: () → object[]
    Status: ($VMName) → string
    Mounts: ($VMName) → object
    Mounted: ($VMName, $HostPath) → object
    # VM Lifecycle
    Exists: ($VMName) → bool
    Running: ($VMName) → bool
    Start: ($VMName) → bool
    UntilInstalled: ($VMName) → bool
    Shutdown: ($VMName, $Force?) → bool
    UntilShutdown: ($VMName, $TimeoutSeconds?) → bool
    # VM Creation/Destruction
    Create: ($VMName, $CloudInitPath?, $Network?, $CPUs?, $Memory?, $Disk?, $Image?) → bool
    Destroy: ($VMName) → void
    Purge: () → bool
    # File Sharing
    Mount: ($VMName, $HostPath, $GuestPath) → bool
    Unmount: ($VMName, $GuestPath?) → bool
    Transfer: ($Source, $Destination) → bool
    # Execution
    Exec: ($VMName, $Command, $WorkingDir?) → ExecResult
    Shell: ($VMName) → void

  Vbox:
    Path: string                                  # VBoxManage.exe path
    Invoke: (...args) → ExecResult
    Worker: ($Base) → VboxWorker
    # Network
    GetGuestAdapter: ($AdapterName) → string
    # Medium Helpers
    Drives: ($VMName) → DriveInfo[]
    Attach: ($VMName, $ControllerName, $MediumPath, $Type?, $Port?, $Device?) → bool
    Give: ($VMName, $ControllerName, $MediumPath, $Size) → void
    Delete: ($MediumPath) → void
    # DVD
    Eject: ($VMName) → void
    Insert: ($VMName, $ISOPath) → void
    # Lifecycle
    Exists: ($VMName) → bool
    Running: ($VMName) → bool
    Pause: ($VMName) → bool
    Resume: ($VMName) → bool
    Bump: ($VMName) → bool
    Start: ($VMName, $Type?) → bool
    Shutdown: ($VMName, $Force?) → bool
    UntilShutdown: ($VMName, $TimeoutSeconds?) → bool
    # Configuration
    Configure: ($VMName, $Settings) → bool
    Optimize: ($VMName) → bool
    Hypervisor: ($VMName) → bool
    # Creation/Destruction
    Destroy: ($VMName) → void
    Create: ($VMName, $MediumPath, $DVDPath?, $AdapterName?, $OSType?, $Firmware?, $ControllerName?, $Size?, $RAM?, $CPU?, $Optimize?, $Hypervisor?) → bool

  Builder:                                        # extends MultipassWorker
    Packages: string[]                            # Required apt packages
    Config: hashtable                             # From Settings.Virtualization.Builder
    Defaults: hashtable
    # Build Operations
    Clean: () → bool
    Flush: () → bool                              # Destroy all registered runners + self
    InstallDependencies: () → bool
    Build: ($Layer?) → bool
    Stage: () → bool                              # Setup + Mount + InstallDependencies
    RegisterRunner: ($Name, $Worker) → Worker
    # Inherited: all MultipassWorker members

  Fragments:
    Layers: FragmentInfo[]                        # All fragments sorted by Order
    UpTo: ($Layer) → FragmentInfo[]               # Fragments with layer ≤ $Layer
    At: ($Layer) → FragmentInfo[]                 # Fragments at exactly $Layer
    IsoRequired: () → FragmentInfo[]              # Fragments with iso_required=true
    LayerName: ($Layer) → string                  # Human-readable layer name

  Testing:
    Results: TestResult[]
    PassCount: int
    FailCount: int
    All: int[]                                    # All layer numbers
    Reset: () → void
    Record: ($Result) → void
    Summary: () → void
    Fragments: ($Layer) → string[]                # Fragment names up to layer
    LevelName: ($Layer) → string                  # Layer name
    LevelFragments: ($Layer) → string[]           # Fragment names up to layer
    IncludeArgs: ($Layer) → string                # "-i frag1 -i frag2 ..."
    Verifications:                                # submodule
      Fork: ($Test, $Decision, $Reason?) → void   # Log fork decision
      Run: ($Worker, $Layer) → void               # Run all verifications up to layer
      Network: ($Worker) → void                   # Layer 1: 6.1.1-6.1.5
      Kernel: ($Worker) → void                    # Layer 2: 6.2.1-6.2.2
      Users: ($Worker) → void                     # Layer 3: 6.3.1-6.3.4
      # Layers 4-18: not yet implemented

  CloudInit:
    Build: ($Layer) → Artifacts                   # Build cloud-init (idempotent)
    Clean: () → bool                              # Delegate to Builder.Clean()
    Cleanup: ($Name?) → void                      # Destroy runner by name
    Worker: ($Layer, $Overrides?) → MultipassWorker
    Test:                                         # submodule
      Run: ($Layer, $Overrides?) → TestRunResult

  Autoinstall:
    Build: ($Layer) → Artifacts                   # Build autoinstall (idempotent)
    Clean: () → bool                              # Delegate to Builder.Clean()
    Cleanup: ($Name?) → void                      # Destroy VBox VM by name
    Worker: ($Overrides?) → VboxWorker
    Test:                                         # submodule
      Run: ($Overrides?) → TestRunResult

# Interfaces

ExecResult:
  Output: string | string[]
  ExitCode: int
  Success: bool

TestResult:
  Test: string
  Name: string
  Pass: bool
  Output: string | string[]
  Error: string

TestRunResult:
  Success: bool
  Results: TestResult[]
  Worker: MultipassWorker | VboxWorker

FragmentInfo:
  Name: string
  Path: string
  Order: int
  Layer: int | int[]
  IsoRequired: bool

DriveInfo:
  Controller: string
  Port: int
  Device: int
  Path: string
  IsDVD: bool

Artifacts:
  cloud_init: string                              # Path to cloud-init.yaml
  autoinstall: string                             # Path to user-data
  iso: string                                     # Path to ISO file
  scripts: hashtable                              # Script name → path

MultipassWorker:
  Config: hashtable
  Defaults: hashtable
  Rendered: hashtable                             # Merged config (cached)
  Name: string
  CPUs: int
  Memory: string
  Disk: string
  Network: string
  CloudInit: string
  # Lifecycle
  Info: () → object
  Addresses: () → string[]
  Address: () → string
  Exists: () → bool
  Running: () → bool
  Create: () → bool
  Destroy: () → bool
  Start: () → bool
  Shutdown: ($Force?) → bool
  UntilShutdown: ($TimeoutSeconds?) → bool
  Status: () → string
  UntilInstalled: () → bool
  Setup: ($FailOnNotInitialized?) → bool
  # File Sharing
  Mount: ($SourcePath, $TargetPath) → bool
  Unmount: ($TargetPath?) → bool
  Mounts: () → object
  Mounted: ($HostPath) → object
  Pull: ($Source, $Destination) → bool
  Push: ($Source, $Destination) → bool
  # Execution
  Exec: ($Command, $WorkingDir?) → ExecResult
  Shell: () → void
  # From Worker.AddCommonMethods
  Ensure: () → bool
  Test: ($TestId, $Name, $Command, $ExpectedPattern) → TestResult
  Errored: () → bool                              # (from General.ps1 merge)

VboxWorker:
  Config: hashtable
  Defaults: hashtable
  Rendered: hashtable
  Name: string
  CPUs: int
  Memory: int
  Disk: int
  Network: string
  IsoPath: string
  MediumPath: string
  SSHUser: string
  SSHHost: string
  SSHPort: int
  # Lifecycle
  Exists: () → bool
  Running: () → bool
  Start: ($Type?) → bool
  Shutdown: ($Force?) → bool
  UntilShutdown: ($TimeoutSeconds?) → bool
  Destroy: () → bool
  Create: () → bool
  # Execution
  Exec: ($Command) → ExecResult
  # From Worker.AddCommonMethods
  Ensure: () → bool
  Test: ($TestId, $Name, $Command, $ExpectedPattern) → TestResult
  UntilInstalled: () → bool                       # (from General.ps1 merge)
  Errored: () → bool                              # (from General.ps1 merge)
```
