# Ubuntu Image Builder - Refactor Plan

This document outlines the refactoring of Infrastructure-Host into a focused Ubuntu image building system with self-contained, fragment-based architecture.

---

## Goals

1. **Scope Reduction**: Focus exclusively on building Ubuntu images (autoinstall ISO, cloud-init configs)
2. **Fragment Architecture**: Each component (network, users, ssh, etc.) is self-contained with its config, scripts, tests, and docs
3. **SDK Unification**: Document and organize both Host SDK (PowerShell) and Builder SDK (Python) together
4. **Required Fragment Marking**: Clearly indicate which fragments are required for ISO/autoinstall builds
5. **Dual Ordering**: Separate build order (alphanumeric) from test order (incremental)

---

## Scope Changes

### What's In Scope

This project focuses on **building Ubuntu images** - specifically:

- Autoinstall ISO creation
- Cloud-init configuration generation
- Template rendering and fragment composition
- Build and test tooling (Host SDK + Builder SDK)

### What's Out of Scope

These topics are about **physical deployment** and don't belong in an image-building project:

- Hardware setup and BIOS configuration
- Physical deployment processes
- Post-deployment validation
- Hardware compatibility lists

### Documentation Audit

| Chapter | Topic                      | Scope   | Action      | Destination           | Notes                                             |
| ------- | -------------------------- | ------- | ----------- | --------------------- | ------------------------------------------------- |
| 1       | Overview & Architecture    | PARTIAL | **REWRITE** | Root README           | Keep arch concepts, remove deployment details     |
| 2       | Hardware & BIOS Setup      | OUT     | **REMOVE**  | -                     | Physical deployment                               |
| 3       | Build System               | IN      | **KEEP**    | Book 0 docs           | Core to image building                            |
| 4       | Network Planning           | IN      | **KEEP**    | Book 2 - network/docs | Config for network fragment                       |
| 5       | Autoinstall Media Creation | IN      | **KEEP**    | Book 1 - base/docs    | Core to image building                            |
| 6       | Cloud-init Fragments       | IN      | **KEEP**    | Book 2 - per-fragment | Split into per-fragment docs                      |
| 7       | Testing and Validation     | IN      | **REWORK**  | Per-fragment tests    | Restructure into per-fragment test modules        |
| 8       | Deployment Process         | OUT     | **REMOVE**  | -                     | Physical deployment                               |
| 9       | Post-Deployment Validation | OUT     | **REMOVE**  | -                     | Post-deployment                                   |
| 10      | Troubleshooting            | PARTIAL | **PARTIAL** | Book 0 docs           | Keep build/test issues, remove deployment issues  |
| 11      | Appendix                   | PARTIAL | **PARTIAL** | Book 0 docs           | Keep reference files, remove 11.4 Hardware Compat |

---

## New Structure

### Book Organization

```
ubuntu-image-builder/
├── book-0-builder/      # Builder Layer - SDKs, tooling, VM config
├── book-1-foundation/   # Foundation Layer - Base autoinstall (fragmentable)
├── book-2-cloud/        # Cloud Layer - Cloud-init fragments
└── output/              # Build artifacts
```

### Book 0 - Builder Layer

Contains both SDKs, shared build tooling, and VM configuration.

```
book-0-builder/
├── README.md
│
├── config/
│   ├── vm.config.yaml.example   # Example VM config (tracked)
│   └── vm.config.yaml           # Actual VM config (gitignored)
│
├── host-sdk/                    # PowerShell (Windows host)
│   ├── SDK.ps1                  # Entry point
│   ├── modules/
│   │   ├── Settings.ps1         # Config loading
│   │   ├── General.ps1          # Cloud-init helpers
│   │   ├── Network.ps1          # Network utilities
│   │   ├── Multipass.ps1        # VM management
│   │   ├── Builder.ps1          # Build workflow
│   │   └── Vbox.ps1             # VirtualBox automation
│   └── helpers/
│       ├── PowerShell.ps1       # PSObject utilities
│       └── Config.ps1           # Config merging
│
├── builder-sdk/                 # Python (build VM)
│   ├── __init__.py
│   ├── __main__.py              # CLI: python -m builder
│   ├── context.py               # BuildContext
│   ├── renderer.py              # Template rendering
│   ├── composer.py              # Fragment merging
│   ├── filters.py               # Jinja2 filters
│   └── artifacts.py             # Artifact tracking
│
└── docs/
    ├── HOST_SDK.md              # Host SDK reference
    ├── BUILDER_SDK.md           # Builder SDK reference
    └── CLI_REFERENCE.md         # CLI commands
```

### Book 1 - Foundation Layer

The base autoinstall configuration. Structured identically to Book 2 fragments.

```
book-1-foundation/
├── README.md
│
├── base/                        # Base autoinstall fragment (REQUIRED)
│   ├── build.yaml               # Fragment metadata
│   ├── config/
│   │   ├── production.yaml      # Production config
│   │   └── testing.yaml         # Testing overlay
│   ├── fragment.yaml.tpl        # Main autoinstall template
│   ├── scripts/
│   │   ├── early-net.sh.tpl     # Network detection
│   │   └── build-iso.sh.tpl     # ISO creation
│   ├── tests/
│   │   └── Test-Base.ps1
│   └── docs/
│       ├── AUTOINSTALL.md
│       └── ISO_CREATION.md
```

### Book 2 - Cloud Layer

Cloud-init fragments. Each fragment is self-contained.

```
book-2-cloud/
├── README.md
│
├── network/                     # REQUIRED (build_order: 10)
│   ├── build.yaml               # Fragment metadata
│   ├── config/
│   │   ├── production.yaml      # Production config
│   │   └── testing.yaml         # Testing overlay (optional)
│   ├── fragment.yaml.tpl        # Cloud-init template
│   ├── scripts/
│   │   └── net-setup.sh.tpl
│   ├── tests/
│   │   └── Test-Network.ps1
│   └── docs/
│       └── NETWORK.md
│
├── users/                       # REQUIRED (build_order: 20)
│   ├── build.yaml
│   ├── config/
│   │   ├── production.yaml
│   │   └── testing.yaml
│   ├── fragment.yaml.tpl
│   ├── scripts/
│   │   └── user-setup.sh.tpl
│   ├── tests/
│   │   └── Test-Users.ps1
│   └── docs/
│       └── USERS.md
│
├── ssh/                         # REQUIRED (build_order: 25)
│   ├── build.yaml
│   ├── config/
│   │   └── production.yaml
│   ├── fragment.yaml.tpl
│   ├── tests/
│   │   └── Test-SSH.ps1
│   └── docs/
│       └── SSH.md
│
├── kernel/                      # Optional (build_order: 15)
├── ufw/                         # Optional (build_order: 30)
├── system/                      # Optional (build_order: 40)
├── msmtp/                       # Optional (build_order: 45)
├── packages/                    # Optional (build_order: 50)
├── pkg-security/                # Optional (build_order: 50)
├── security-mon/                # Optional (build_order: 55)
├── virtualization/              # Optional (build_order: 60)
├── cockpit/                     # Optional (build_order: 70)
├── claude-code/                 # Optional (build_order: 75)
├── copilot-cli/                 # Optional (build_order: 76)
├── opencode/                    # Optional (build_order: 77)
├── ui/                          # Optional (build_order: 90)
└── pkg-upgrade/                 # Optional (build_order: 999)
```

---

## Fragment Metadata (build.yaml)

Each fragment has a `build.yaml` describing its properties:

```yaml
name: network
description: Static IP configuration via arping detection
required: true # Required for ISO/autoinstall builds (not multipass runner)
build_order: 10 # Alphanumeric order for build output
build_layer: 1 # Incremental build layer (1 = foundation)
```

### Required vs Optional

The `required` flag affects **ISO and autoinstall builds only**:

- Required fragments are always included in production builds
- Multipass runner tests don't need this flag (multipass has its own exec)

| Fragment      | required | Reason                                      |
| ------------- | -------- | ------------------------------------------- |
| base (Book 1) | true     | Core autoinstall - defines OS installation  |
| network       | true     | System needs networking for remote access   |
| users         | true     | System needs a login user                   |
| ssh           | true     | Remote access required for headless servers |
| All others    | false    | Optional features                           |

### Dual Ordering System

| Field         | Purpose                             | Example         |
| ------------- | ----------------------------------- | --------------- |
| `build_order` | Fragment merge order within a layer | 10, 15, 20, 999 |
| `build_layer` | Incremental build layer             | 1, 2, 3, 8      |

**`build_order`** - Controls the order fragments are merged into the final cloud-init output:

- Defined in `build.yaml`, not directory name (directories can use simple names like `network/`, `kernel/`)
- Lower numbers merge first, higher numbers merge last
- Example: `pkg-upgrade` with `build_order: 999` merges last to ensure package upgrades run after all other packages are installed

**`build_layer`** - Defines incremental build layers (similar to Docker layers):

- Fragments are organized into layers (1, 2, 3, etc.) for incremental builds
- Building/testing at layer N includes ALL fragments from layers 1 through N
- Multiple fragments can share the same layer when they belong together
- Enables partial builds for faster iteration and debugging

Example layer progression:

- Layer 1: Network only
- Layer 2: Network + Kernel
- Layer 3: Network + Kernel + Users
- Layer 8: All above + Packages + Package Security + Package Upgrade

Use cases:

- Build minimal image (required layers only)
- Test up to a specific layer without building everything
- Debug a specific layer by building only up to that point

**Why they differ:**
| Fragment | build_order | build_layer | Reason |
| -------- | ----------- | ----------- | ------ |
| network | 10 | 1 | Foundation layer |
| pkg-upgrade | 999 | 8 | Merges last in output, but belongs to packages layer |

---

## Config Structure

### Production vs Testing Configs

Each fragment has separate config files:

```
fragment/config/
├── production.yaml    # Production configuration
└── testing.yaml       # Testing overlay (optional)
```

The Host SDK sets the build mode:

- **Production build**: Uses `production.yaml` only
- **Test build**: Layers `testing.yaml` on top of `production.yaml`

This replaces the old `testing.config.yaml` with a `testing: true` flag.

---

## SDK Naming

| Old Name               | New Name        | Purpose                                                 |
| ---------------------- | --------------- | ------------------------------------------------------- |
| tests/lib (PowerShell) | **Host SDK**    | Runs on Windows host - orchestrates builds and tests    |
| builder/ (Python)      | **Builder SDK** | Runs in build VM - renders templates, creates artifacts |

The Host SDK handles:

- Build orchestration
- Test orchestration (multipass runner + VirtualBox)
- Config merging (production + testing overlay)

---

## Migration Phases

### Phase 1: File Movement (No Content Changes)

Move existing files to new locations. No reading or modifying content.

**Files that stay in place:**

- Makefile
- .gitignore
- pyproject.toml

**VM Config Migration:**

- Move `vm.config.yaml.example` to `book-0-builder/config/`
- Move `vm.config.yaml` to `book-0-builder/config/` (will be gitignored)
- Remove `vm.config.ps1` and `vm.config.ps1.example` (YAML only)

### Phase 2: Content Updates

After Phase 1, update file contents:

- Update import paths in both SDKs
- Create `build.yaml` metadata files
- Split configs into `production.yaml` / `testing.yaml`
- Update Makefile for new paths

### Phase 3: Testing

- Verify minimal build (required fragments only)
- Verify full build (all fragments)
- Run per-fragment tests through multipass
- Run per-fragment tests through VirtualBox

---

## Decisions Made

1. **Ordering**: Option A - dual order fields in build.yaml
2. **Required scope**: Only affects ISO/autoinstall, not multipass runner
3. **Config naming**: `production.yaml` and `testing.yaml` (not `<fragment>.config.yaml`)
4. **Template naming**: `fragment.yaml.tpl` at fragment root (not in templates/)
5. **Scripts location**: `scripts/` at fragment root (not templates/scripts/)
6. **Metadata file**: `build.yaml` (not fragment.yaml)
7. **Metadata content**: name, description, required, build_order, build_layer only
8. **VM config**: YAML only, example tracked, actual gitignored, in Book 0

---

## Questions Resolved

1. **Shared configs**: Each fragment has its own config. Shared values are duplicated where needed.

2. **Fragment discovery**: Builder SDK auto-discovers fragments by scanning for `build.yaml` files.

3. **Incremental builds**: SDK builds/tests fragments layer by layer using `build_layer` sequence.
