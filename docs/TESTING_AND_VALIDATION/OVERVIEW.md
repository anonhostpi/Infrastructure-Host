# Testing and Validation

This section covers testing build artifacts before deploying to bare metal.

## Contents

- [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md)
- [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md)

## Overview

Testing occurs in two phases:

1. **Cloud-init Testing** - Verify rendered cloud-init works with multipass before embedding in autoinstall
2. **Autoinstall Testing** - Build ISO and test full installation in VirtualBox

This approach catches configuration errors early before building the full ISO.

## Build System Integration

Testing uses the build system from [Chapter 3](../BUILD_SYSTEM/OVERVIEW.md):

```bash
# Render all templates
make all

# Individual targets
make cloud-init    # output/cloud-init.yaml
make autoinstall   # output/user-data
make scripts       # output/scripts/*.sh
```

See [3.4 Makefile Interface](../BUILD_SYSTEM/MAKEFILE_INTERFACE.md) for complete build commands.

## Prerequisites

- Multipass installed on Windows
- VirtualBox installed (for autoinstall testing)
- Python 3 with dependencies: `pip install -r requirements.txt`

## Test Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Configure                                                   │
│     Create src/config/*.config.yaml files                       │
├─────────────────────────────────────────────────────────────────┤
│  2. Build                                                       │
│     make all                                                    │
├─────────────────────────────────────────────────────────────────┤
│  3. Test cloud-init (Phase 1)                                   │
│     multipass launch --cloud-init output/cloud-init.yaml        │
├─────────────────────────────────────────────────────────────────┤
│  4. Test autoinstall (Phase 2)                                  │
│     Build ISO, boot in VirtualBox                               │
├─────────────────────────────────────────────────────────────────┤
│  5. Deploy to bare metal                                        │
│     Write ISO to USB, boot target hardware                      │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration Files

Before testing, ensure these config files exist in `src/config/`:

| File | Purpose | Reference |
|------|---------|-----------|
| `network.config.yaml` | IP, gateway, DNS | [4.1 Network Info](../NETWORK_PLANNING/NETWORK_INFORMATION_GATHERING.md) |
| `identity.config.yaml` | Username, SSH keys | [5.2 Autoinstall Config](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) |
| `storage.config.yaml` | Disk selection | [5.2 Autoinstall Config](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) |
| `image.config.yaml` | Ubuntu release | [5.1 Download ISO](../AUTOINSTALL_MEDIA_CREATION/DOWNLOAD_UBUNTU_ISO.md) |
| `smtp.config.yaml` | Email notifications (optional) | [6.7 MSMTP Fragment](../CLOUD_INIT_CONFIGURATION/MSMTP_FRAGMENT.md) |
| `opencode.config.yaml` | AI coding agent (optional) | [6.12 OpenCode Fragment](../CLOUD_INIT_CONFIGURATION/OPENCODE_FRAGMENT.md) |