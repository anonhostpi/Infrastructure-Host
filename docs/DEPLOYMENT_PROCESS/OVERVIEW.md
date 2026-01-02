# Deployment Process

Deploy the autoinstall ISO to bare metal hardware.

## Contents

- [8.1 Pre-Deployment Checklist](./PRE_DEPLOYMENT_CHECKLIST.md)
- [8.2 Step-by-Step Deployment](./STEP_BY_STEP_DEPLOYMENT.md)
- [8.3 Monitoring Cloud-init Progress](./MONITORING_CLOUD_INIT.md)

## Overview

This chapter guides you through deploying the autoinstall ISO to bare metal. The deployment process has two phases:

1. **Autoinstall Phase** - Boot from ISO, automatic partitioning with ZFS, base OS install
2. **Cloud-init Phase** - First boot configuration: arping network detection, static IP, packages, services

### What Gets Deployed

| Component | Configuration |
|-----------|---------------|
| Storage | ZFS root pool with boot partition |
| Network | Static IP via arping interface detection |
| User | Admin account with password and SSH key |
| Packages | KVM, libvirt, Cockpit, multipass |
| Services | libvirtd, cockpit.socket, UFW firewall |

### Prerequisites

Before deploying, ensure you have:

- Completed [Chapter 6: Testing and Validation](../TESTING_AND_VALIDATION/OVERVIEW.md)
- Autoinstall ISO built and validated
- Target hardware with BIOS configured per [Chapter 2](../HARDWARE_BIOS_SETUP/OVERVIEW.md)
- Network environment with gateway/DNS responding to ARP
