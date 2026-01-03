# 1.1 Deployment Strategy

This plan outlines the deployment of Ubuntu Server on bare-metal hardware using USB/ISO boot with autoinstall and cloud-init for automated configuration.

## Deployment Flow

```
Hardware Preparation → BIOS Configuration → Configuration Generation →
Custom ISO Creation → Boot & Autoinstall → Cloud-init Execution →
Post-Deploy Validation
```

## Process Overview

1. **Hardware Preparation** - Verify hardware meets requirements (see [Chapter 2](../HARDWARE_BIOS_SETUP/OVERVIEW.md))
2. **BIOS Configuration** - Enable virtualization, set boot order, configure power management
3. **Configuration Generation** - Generate autoinstall and cloud-init configs from templates (see [Chapter 3](../BUILD_SYSTEM/OVERVIEW.md))
4. **Custom ISO Creation** - Build autoinstall ISO with embedded configuration (see [Chapter 5](../AUTOINSTALL_MEDIA_CREATION/OVERVIEW.md))
5. **Boot & Autoinstall** - Boot from media, automated installation proceeds
6. **Cloud-init Execution** - Post-install configuration applies automatically (see [Chapter 6](../CLOUD_INIT_CONFIGURATION/OVERVIEW.md))
7. **Post-Deploy Validation** - Verify all services and configurations are correct
