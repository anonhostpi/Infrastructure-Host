# Architecture: Book 0 Builder

Book 0 (`book-0-builder/`) contains two SDKs that together orchestrate the build, deployment, and testing of Ubuntu cloud-init and autoinstall artifacts.

## Overview

```
book-0-builder/
├── host-sdk/          PowerShell SDK - VM orchestration, testing, SSH
│   ├── SDK.ps1        Entry point, loads all modules
│   ├── helpers/       Utility functions (PowerShell.ps1, Config.ps1)
│   └── modules/       14 modules extending the SDK object
│
├── builder-sdk/       Python SDK - template rendering, artifact generation
│   ├── __main__.py    CLI entry point (render, list-fragments, artifacts)
│   ├── renderer.py    Jinja2 template rendering and fragment discovery
│   ├── context.py     Configuration loading and environment variable handling
│   ├── composer.py    Deep merge utility (dicts merge, arrays concat, scalars replace)
│   ├── filters.py     Jinja2 custom filters (base64, yaml, shell, hashing, network)
│   └── artifacts.py   Build manifest tracking (artifacts.yaml)
│
└── config/
    ├── build_layers.yaml   Layer name definitions (0-18)
    └── vm.config.yaml      Local VM settings (not tracked)
```

## Host SDK (PowerShell)

The host SDK is a module-based system where `SDK.ps1` creates a PSObject and each module extends it via `$SDK.Extend(name, object)`. No PowerShell classes are used; all objects are PSObjects with dynamically-attached script methods and properties.

### Core Methods (SDK.ps1)

- `Root()` - Git repository root path
- `Extend(name, object)` - Attach a module to the SDK
- `Job(scriptblock, timeout, vars)` - Async job execution with timeout

### Helpers

| File | Purpose |
|------|---------|
| `PowerShell.ps1` | `Add-ScriptMethods`, `Add-ScriptProperties`, `ConvertTo-OrderedHashtable`, `Test-Primitive` |
| `Config.ps1` | `Merge-DeepHashtable` (recursive config merging), `Build-TestConfig` (loads all `*.config.yaml` from book-1 and book-2) |

### Modules (load order)

| # | Module | Purpose |
|---|--------|---------|
| 1 | Logger | Structured logging with levels, colors, transcript support |
| 2 | Settings | Loads `vm.config.yaml`, `build_layers.yaml`, and all fragment `*.config.yaml` files. Converts YAML keys to PascalCase via `ConvertTo-PascalCase`. |
| 3 | Network | SSH/SCP operations, connectivity testing, `WaitForSSH`, interactive `Shell` |
| 4 | Worker | Base abstraction for VM workers. Adds `Setup`, `Test`, `UntilInstalled`, `Errored`, `Status`, `Ensure` to any worker object. Falls back to SSH-based `Exec`/`Pull`/`Push`/`Shell` when hypervisor module doesn't provide them. |
| 5 | Vbox | VirtualBox VM management via `VBoxManage` |
| 6 | HyperV | Hyper-V VM management (Generation 2, EFI). Requires elevation. |
| 7 | Multipass | Multipass VM management. Backend-agnostic (hyperv/virtualbox). Provides `Worker()` factory, `Invoke()` CLI wrapper, mount/transfer/exec. |
| 8 | Builder | Build orchestration. `Stage()` creates builder VM, mounts repo, installs deps. `Build(Layer)` runs `make`. `Runner(Config, Backend, Layer)` creates test VM from artifacts. |
| 9 | Fragments | Fragment discovery. Scans book-1 and book-2 for `build.yaml` files. `UpTo(layer)`, `At(layer)`, `IsoRequired()`. |
| 10 | Testing | Test result aggregation. `Record()`, `Summary()`, pass/fail counters. |
| 11 | Verifications | Discovers and runs `tests/{layer}/verifications.ps1` from fragments. `Discover(layer)`, `Load(path)`, `Run(layer, worker)`. |
| 12 | CloudInit | Empty placeholder, extended by CloudInitTest. |
| 13 | CloudInitTest | `Run(Layer)` - builds cloud-init, creates runner VM, runs layer verifications, reports results. |
| 14 | Autoinstall | Empty placeholder, extended by AutoinstallTest. |
| 15 | AutoinstallTest | `Run(Layer, Hypervisors)` - builds ISO, creates VBox/HyperV VMs, runs book-1 verifications. |

### Worker Pattern

All hypervisor modules (Multipass, Vbox, HyperV) produce Worker objects through a `Worker()` factory method. Each worker has:

- **Properties**: `Rendered`, `Name`, `CPUs`, `Memory`, `Disk`, `Network` (plus hypervisor-specific: `CloudInit`, `IsoPath`, `SSHUser`, etc.)
- **Lifecycle methods**: `Exists()`, `Running()`, `Create()`, `Destroy()`, `Start()`, `Shutdown()`
- **Execution methods**: `Exec(command)`, `Shell()`, `Pull(src, dst)`, `Push(src, dst)`
- **Test methods** (from Worker module): `Test(id, name, command, expected)`, `Setup(failOnError)`, `UntilInstalled()`

The Worker module attaches SSH-based fallback implementations, so any worker with `SSHUser`/`SSHHost`/`SSHPort` properties automatically gets `Exec`/`Pull`/`Push`/`Shell` via the Network module.

## Builder SDK (Python)

The builder SDK is a CLI tool (`python -m builder`) that renders Jinja2 templates from fragment directories into deployment artifacts.

### CLI Commands

```
python -m builder render cloud-init -o output.yaml [-l LAYER] [-i FRAG] [-x FRAG] [--for-iso]
python -m builder render autoinstall -o output.yaml
python -m builder render script -o output.sh TEMPLATE_PATH
python -m builder list-fragments
python -m builder artifacts set CATEGORY VALUE
python -m builder artifacts show
```

### Configuration Loading (context.py)

`BuildContext` loads configuration from multiple sources:

1. All `*.config.yaml` from book-1 and book-2 config directories
2. Auto-unwraps single-key files (e.g., `identity.config.yaml` containing `identity:` unwraps to just the value)
3. Applies testing overrides when `testing: true`
4. Loads OAuth credential fallbacks from local CLI tool configs
5. Environment variable overrides via `AUTOINSTALL_` prefix

### Fragment Discovery (renderer.py)

Scans `book-1-foundation/` and `book-2-cloud/` recursively for `build.yaml` files. Each fragment contains:

```
fragment-name/
├── build.yaml              Metadata: name, build_order, build_layer, iso_required
├── fragment.yaml.tpl       Jinja2 cloud-init template
├── config/                 Optional configuration
│   ├── *.config.yaml       Production config (gitignored)
│   └── *.config.yaml.example
├── scripts/                Optional helper scripts
│   └── *.sh.tpl            Jinja2 script templates
├── docs/                   Documentation
│   └── FRAGMENT.md
└── tests/
    └── {layer}/
        └── verifications.ps1   PowerShell test definitions
```

### Rendering Pipeline

1. Discover fragments, filter by layer/include/exclude
2. For each fragment, render `fragment.yaml.tpl` with `BuildContext`
3. Deep-merge all rendered fragments (dicts merge recursively, arrays concatenate)
4. Write output as `#cloud-config` YAML
5. Register in `output/artifacts.yaml`

## Build Layers

Fragments are organized into numbered build layers for incremental testing:

| Layer | Name | Fragments |
|-------|------|-----------|
| 0 | Base | base (book-1) |
| 1 | Network | network |
| 2 | Kernel Hardening | kernel |
| 3 | Users | users |
| 4 | SSH Hardening | ssh |
| 5 | UFW Firewall | ufw |
| 6 | System Settings | system |
| 7 | MSMTP Mail | msmtp |
| 8 | Package Security | packages, pkg-security |
| 9 | Security Monitoring | security-mon |
| 10 | Virtualization | virtualization |
| 11 | Cockpit | cockpit |
| 12 | Claude Code | claude-code |
| 13 | Copilot CLI | copilot-cli |
| 14 | OpenCode | opencode |
| 15 | UI Touches | ui |
| 16-18 | Package Updates | pkg-upgrade |

## Data Flow

```
                    *.config.yaml (from fragments)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   BuildContext      Build-TestConfig     Settings.ps1
   (Python)          (PowerShell)         (PowerShell)
        │                  │                  │
   renderer.py        Config.ps1          PascalCase
        │                  │              conversion
        │                  │                  │
   fragment.yaml.tpl       │            $SDK.Settings.*
   (Jinja2 render)         │
        │                  │
   deep_merge         Merge-DeepHashtable
        │                  │
   cloud-init.yaml    Test config
   artifacts.yaml     for Workers
```

Both SDKs independently load and merge the same `*.config.yaml` files. The Python SDK renders templates; the PowerShell SDK uses the config to parameterize test Workers and verification scripts.
