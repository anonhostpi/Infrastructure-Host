# Testing and Validation

This section covers testing build artifacts before deploying to bare metal.

> **CRITICAL: NOTHING RUNS ON THE WINDOWS HOST**
>
> **All building AND testing happens inside VMs:**
>
> | Task | Where it runs |
> |------|---------------|
> | `make cloud-init` | Builder VM (multipass) |
> | `make autoinstall` | Builder VM (multipass) |
> | `make iso` | Builder VM (multipass) |
> | Cloud-init fragment tests | Test VM (multipass) |
> | Autoinstall ISO tests | Test VM (VirtualBox) |
>
> The Windows host only orchestrates VMs via PowerShell scripts that source `vm.config.ps1`.
> **Never run Python, make, or test scripts directly on Windows.**

## Contents

- [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md)
- [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md)

## Overview

Testing occurs in two phases:

1. **Cloud-init Testing** (7.1) - Test fragment configuration with **multipass**. Validates all cloud-init fragments (security, services, packages, user experience). **Most testing happens here.**
2. **Autoinstall Testing** (7.2) - Test full installation in **VirtualBox**. Validates autoinstall-specific components only (ZFS root, boot process, ISO structure).

This approach catches configuration errors early before building the full ISO.

## Testing Platform Policy

| Test Type | Platform | Reason |
|-----------|----------|--------|
| All Chapter 6 fragments | **Multipass** | Fast iteration, full cloud-init support |
| Network configuration | **Multipass** (bridged) | Bridged mode supports static IP testing |
| Security hardening | **Multipass** | All sysctl, SSH, UFW tests work |
| Services (Cockpit, libvirt, fail2ban) | **Multipass** | Full service testing capability |
| User experience (MOTD, aliases, CLI tools) | **Multipass** | Complete shell environment |
| ZFS root filesystem | **VirtualBox** | Requires real disk partitioning |
| ISO boot process | **VirtualBox** | Requires UEFI boot from ISO |
| GRUB autoinstall entry | **VirtualBox** | Requires boot from ISO |

**Rule:** Use multipass for everything except autoinstall-specific tests that require the ISO boot process or ZFS root filesystem.

## Build System Integration

Testing uses the build system from [Chapter 3](../BUILD_SYSTEM/OVERVIEW.md). **All builds run on the Builder VM:**

```powershell
# From Windows - run build on Builder VM
. .\vm.config.ps1
multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && make cloud-init"
```

See [3.4 Makefile Interface](../BUILD_SYSTEM/MAKEFILE_INTERFACE.md) for complete build commands.

## Prerequisites

**On Windows host:**
- Multipass installed
- VirtualBox installed (for autoinstall testing)
- PowerShell

**On Builder VM (installed automatically):**
- Python 3 with dependencies: `pip install -r requirements.txt`
- make, git

## Test Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Configure (one-time)                                        │
│     Create book-*/*/config/*.config.yaml and vm.config.yaml     │
├─────────────────────────────────────────────────────────────────┤
│  2. Launch Builder VM                                           │
│     multipass launch + mount repo                               │
├─────────────────────────────────────────────────────────────────┤
│  3. Build (on Builder VM)                                       │
│     multipass exec $BuilderVMName -- make all                   │
├─────────────────────────────────────────────────────────────────┤
│  4. Test cloud-init (Phase 1 - on Test VM)                      │
│     multipass launch --cloud-init output/cloud-init.yaml        │
├─────────────────────────────────────────────────────────────────┤
│  5. Test autoinstall (Phase 2 - on VirtualBox VM)               │
│     Build ISO, boot in VirtualBox                               │
├─────────────────────────────────────────────────────────────────┤
│  6. Deploy to bare metal                                        │
│     Write ISO to USB, boot target hardware                      │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration Files

Configuration files are created **once** from examples and **persist** - they contain values from earlier chapters. **Do not delete or recreate them.**

```powershell
# Required configs (in book-*/*/config/)
cp book-1-foundation/network/config/network.config.yaml.example book-1-foundation/network/config/network.config.yaml
cp book-2-cloud/users/config/identity.config.yaml.example book-2-cloud/users/config/identity.config.yaml
cp book-2-cloud/packages/config/storage.config.yaml.example book-2-cloud/packages/config/storage.config.yaml
cp book-0-builder/config/image.config.yaml.example book-0-builder/config/image.config.yaml

# Optional configs
cp book-2-cloud/msmtp/config/smtp.config.yaml.example book-2-cloud/msmtp/config/smtp.config.yaml
cp book-2-cloud/ai-cli/config/opencode.config.yaml.example book-2-cloud/ai-cli/config/opencode.config.yaml

# VM test settings (in repo root)
cp vm.config.yaml.example vm.config.yaml
```

| File | Purpose | Reference |
|------|---------|-----------|
| `network.config.yaml` | IP, gateway, DNS | [4.1 Network Info](../NETWORK_PLANNING/NETWORK_INFORMATION_GATHERING.md) |
| `identity.config.yaml` | Username, SSH keys | [5.2 Autoinstall Config](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) |
| `storage.config.yaml` | Disk selection | [5.2 Autoinstall Config](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) |
| `image.config.yaml` | Ubuntu release | [5.1 Download ISO](../AUTOINSTALL_MEDIA_CREATION/DOWNLOAD_UBUNTU_ISO.md) |
| `smtp.config.yaml` | Email (optional) | [6.7 MSMTP Fragment](../CLOUD_INIT_CONFIGURATION/MSMTP_FRAGMENT.md) |
| `opencode.config.yaml` | AI agent (optional) | [6.12 OpenCode Fragment](../CLOUD_INIT_CONFIGURATION/OPENCODE_FRAGMENT.md) |
| `vm.config.ps1` | VM settings (repo root) | [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md) |