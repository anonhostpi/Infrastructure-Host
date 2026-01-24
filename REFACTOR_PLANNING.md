# REFACTOR.md Planning Document

This document tracks the incremental research needed to draft REFACTOR.md.

---

## Phase 1: Scope Reduction - Documentation Audit

Identify docs that are IN SCOPE (related to building Ubuntu images) vs OUT OF SCOPE (deployment, post-deployment, hardware setup for physical machines).

### Chapters to Audit

| Chapter | Status | Verdict | Notes |
|---------|--------|---------|-------|
| 1. Overview & Architecture | DONE | **REWRITE** | Keep arch concepts, remove deployment/Cockpit access details |
| 2. Hardware & BIOS Setup | DONE | **REMOVE** | Physical deployment - out of scope |
| 3. Build System | DONE | **KEEP** | Core to image building - moves to Book 0 |
| 4. Network Configuration Planning | DONE | **KEEP** | Config for network fragment - moves to Book 2/network |
| 5. Creating Ubuntu Autoinstall Media | DONE | **KEEP** | Core to image building - moves to Book 1 |
| 6. Cloud-init Configuration (fragments) | TODO | | Per-fragment audit needed - Book 2 |
| 7. Testing and Validation | DONE | **KEEP/REWORK** | Restructure into per-fragment tests |
| 8. Deployment Process | DONE | **REMOVE** | Physical deployment - out of scope |
| 9. Post-Deployment Validation | DONE | **REMOVE** | Post-deployment - out of scope |
| 10. Troubleshooting | DONE | **PARTIAL** | Keep build/test troubleshooting, remove deployment troubleshooting |
| 11. Appendix | DONE | **PARTIAL** | Keep reference files, remove 11.4 Hardware Compatibility |

---

## Phase 2: Fragment Analysis

Identify which fragments are REQUIRED (core/minimal build) vs OPTIONAL.

### Cloud-init Fragments to Audit

| Fragment | File | Status | Required? | Notes |
|----------|------|--------|-----------|-------|
| Network | 10-network.yaml.tpl | DONE | **YES** | Core - system needs networking |
| Kernel Hardening | 15-kernel.yaml.tpl | DONE | No | Security hardening - optional |
| Users | 20-users.yaml.tpl | DONE | **YES** | Core - system needs login user |
| SSH | 25-ssh.yaml.tpl | DONE | **YES** | Core - need remote access |
| UFW | 30-ufw.yaml.tpl | DONE | No | Firewall - optional security |
| System | 40-system.yaml.tpl | DONE | No | Locale/keyboard/timezone - has defaults |
| MSMTP | 45-msmtp.yaml.tpl | DONE | No | Email relay - optional |
| Packages | 50-packages.yaml.tpl | DONE | No | Empty packages list - placeholder |
| Pkg Security | 50-pkg-security.yaml.tpl | DONE | No | Unattended upgrades - optional |
| Security Mon | 55-security-mon.yaml.tpl | DONE | No | Monitoring tools - optional |
| Virtualization | 60-virtualization.yaml.tpl | DONE | No | KVM/libvirt - optional |
| Cockpit | 70-cockpit.yaml.tpl | DONE | No | Web UI - optional |
| Claude Code | 75-claude-code.yaml.tpl | DONE | No | AI tool - optional |
| Copilot CLI | 76-copilot-cli.yaml.tpl | DONE | No | AI tool - optional |
| OpenCode | 77-opencode.yaml.tpl | DONE | No | AI tool - optional |
| UI | 90-ui.yaml.tpl | DONE | No | Desktop customization - optional |
| Pkg Upgrade | 999-pkg-upgrade.yaml.tpl | DONE | No | Final upgrade - optional |

### Foundation Layer (Autoinstall)

| Component | File | Status | Notes |
|-----------|------|--------|-------|
| Base Autoinstall | src/autoinstall/base.yaml.tpl | DONE | **REQUIRED** - Core autoinstall template |
| Early Network Script | src/scripts/early-net.sh.tpl | DONE | **REQUIRED** - Used by base autoinstall |
| Net Setup Script | src/scripts/net-setup.sh.tpl | DONE | **REQUIRED** - Used by network fragment |
| User Setup Script | src/scripts/user-setup.sh.tpl | DONE | **REQUIRED** - Used by users fragment |
| Build ISO Script | src/scripts/build-iso.sh.tpl | DONE | **REQUIRED** - ISO creation |

**Required Configs for base.yaml.tpl:**
- `identity` (username, password)
- `network` (hostname)
- `storage` (layout, sizing_policy, match.size)
- `testing` (testing flag for shutdown behavior)

---

## Phase 3: SDK Inventory

### Current Host SDK (tests/lib/*.ps1) → Will become "Host SDK"

| File | Status | Verdict | Notes |
|------|--------|---------|-------|
| SDK.ps1 | DONE | **KEEP** | Entry point - loads all modules |
| Settings.ps1 | DONE | **KEEP** | Config loading from YAML |
| General.ps1 | DONE | **KEEP** | Cloud-init helpers |
| Network.ps1 | DONE | **KEEP** | Network utilities |
| Multipass.ps1 | DONE | **KEEP** | VM management abstraction |
| Builder.ps1 | DONE | **KEEP** | Build workflow orchestration |
| Vbox.ps1 | DONE | **KEEP** | VirtualBox automation |
| helpers/PowerShell.ps1 | DONE | **KEEP** | PSObject utilities |
| helpers/Config.ps1 | DONE | **RELOCATE** | Move to SDK core - mirrors Python BuildContext |
| Verifications.ps1 | DONE | **SPLIT** | Split into per-fragment test modules |

### Current Builder SDK (builder/*.py) → Will become "Builder SDK"

| File | Status | Verdict | Notes |
|------|--------|---------|-------|
| __init__.py | DONE | **KEEP** | Package marker |
| __main__.py | DONE | **KEEP** | CLI entry point |
| context.py | DONE | **KEEP** | BuildContext - config loading |
| renderer.py | DONE | **KEEP** | Template rendering engine |
| composer.py | DONE | **KEEP** | Deep merge for fragments |
| filters.py | DONE | **KEEP** | Jinja2 custom filters |
| artifacts.py | DONE | **KEEP** | Build artifact tracking |

---

## Phase 4: New Structure Design

Based on TODO.md layers:
- Book 0 - Builder Layer: Both SDKs, shared tooling
- Book 1 - Foundation Layer: Base autoinstall
- Book 2 - Cloud Layer: Cloud-init fragments

### Proposed Directory Structure

```
ubuntu-image-builder/
├── README.md
├── Makefile
├── REFACTOR.md
│
├── book-0-builder/                    # Builder Layer
│   ├── README.md                      # Book 0 overview
│   │
│   ├── host-sdk/                      # PowerShell Host SDK
│   │   ├── SDK.ps1                    # Entry point
│   │   ├── modules/
│   │   │   ├── Settings.ps1
│   │   │   ├── General.ps1
│   │   │   ├── Network.ps1
│   │   │   ├── Multipass.ps1
│   │   │   ├── Builder.ps1
│   │   │   └── Vbox.ps1
│   │   └── helpers/
│   │       ├── PowerShell.ps1
│   │       └── Config.ps1
│   │
│   ├── builder-sdk/                   # Python Builder SDK
│   │   ├── __init__.py
│   │   ├── __main__.py
│   │   ├── context.py
│   │   ├── renderer.py
│   │   ├── composer.py
│   │   ├── filters.py
│   │   └── artifacts.py
│   │
│   └── docs/
│       ├── HOST_SDK.md
│       ├── BUILDER_SDK.md
│       └── CLI_REFERENCE.md
│
├── book-1-foundation/                 # Foundation Layer (Autoinstall)
│   ├── README.md                      # Book 1 overview
│   ├── fragment.yaml                  # Fragment metadata (required: true)
│   │
│   ├── config/
│   │   ├── identity.config.yaml
│   │   ├── storage.config.yaml
│   │   ├── image.config.yaml
│   │   └── testing.config.yaml
│   │
│   ├── templates/
│   │   ├── base.yaml.tpl              # Main autoinstall template
│   │   └── scripts/
│   │       ├── early-net.sh.tpl
│   │       └── build-iso.sh.tpl
│   │
│   ├── tests/
│   │   └── Test-Foundation.ps1
│   │
│   └── docs/
│       ├── AUTOINSTALL_CONFIGURATION.md
│       └── ISO_CREATION.md
│
├── book-2-cloud/                      # Cloud Layer (Cloud-init fragments)
│   ├── README.md                      # Book 2 overview
│   │
│   ├── 10-network/                    # REQUIRED fragment
│   │   ├── fragment.yaml              # required: true
│   │   ├── config/
│   │   │   └── network.config.yaml
│   │   ├── templates/
│   │   │   ├── 10-network.yaml.tpl
│   │   │   └── scripts/
│   │   │       └── net-setup.sh.tpl
│   │   ├── tests/
│   │   │   └── Test-Network.ps1
│   │   └── docs/
│   │       └── NETWORK_FRAGMENT.md
│   │
│   ├── 20-users/                      # REQUIRED fragment
│   │   ├── fragment.yaml              # required: true
│   │   ├── config/
│   │   │   └── identity.config.yaml   # (shared with foundation)
│   │   ├── templates/
│   │   │   ├── 20-users.yaml.tpl
│   │   │   └── scripts/
│   │   │       └── user-setup.sh.tpl
│   │   ├── tests/
│   │   │   └── Test-Users.ps1
│   │   └── docs/
│   │       └── USERS_FRAGMENT.md
│   │
│   ├── 25-ssh/                        # REQUIRED fragment
│   │   ├── fragment.yaml              # required: true
│   │   ├── config/
│   │   │   └── ssh.config.yaml
│   │   ├── templates/
│   │   │   └── 25-ssh.yaml.tpl
│   │   ├── tests/
│   │   │   └── Test-SSH.ps1
│   │   └── docs/
│   │       └── SSH_FRAGMENT.md
│   │
│   ├── 15-kernel/                     # Optional fragment
│   │   ├── fragment.yaml              # required: false
│   │   └── ...
│   │
│   └── ... (other optional fragments)
│
└── output/                            # Build artifacts
    ├── artifacts.yaml
    ├── cloud-init.yaml
    ├── user-data
    └── scripts/
```

### Fragment Metadata (fragment.yaml)

Each fragment has a `fragment.yaml` that describes it:

```yaml
name: network
description: Network configuration with static IP via arping detection
required: true  # Required for minimal build
order: 10       # Sort order in merged cloud-init

dependencies:
  configs:
    - network.config.yaml
  scripts:
    - net-setup.sh.tpl

provides:
  cloud_init_keys:
    - bootcmd
    - write_files
```

### Required Fragment Indicator

Fragments marked `required: true` in their `fragment.yaml` are needed for a minimal bootable image:
- **book-1-foundation**: Always required (it IS the autoinstall)
- **book-2-cloud/10-network**: Required - system needs networking
- **book-2-cloud/20-users**: Required - system needs login user
- **book-2-cloud/25-ssh**: Required - need remote access

---

## Progress Tracking

- [x] Phase 1: Documentation audit complete
- [x] Phase 2: Fragment analysis complete
- [x] Phase 3: SDK inventory complete
- [x] Phase 4: New structure designed
- [x] REFACTOR.md drafted
