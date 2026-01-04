# 8.1 Pre-Deployment Checklist

Complete this checklist before deploying to bare metal.

## Prerequisites

- [ ] Chapter 7 testing completed successfully
- [ ] Autoinstall ISO built and validated
- [ ] Physical access to target server (or remote console)

## Hardware Checklist

- [ ] BIOS configured (see [Chapter 2](../HARDWARE_BIOS_SETUP/OVERVIEW.md))
  - [ ] Virtualization extensions enabled (VT-x/AMD-V)
  - [ ] UEFI mode enabled
  - [ ] Boot order set to USB/CD first
- [ ] Target disk identified and ready to be wiped
- [ ] Network cable connected

## Configuration Checklist

- [ ] `network.config.yaml` has correct values for production:
  - [ ] Static IP address for this server
  - [ ] Gateway IP reachable from target network
  - [ ] DNS servers reachable from target network
  - [ ] Hostname matches intended use
- [ ] `identity.config.yaml` has secure credentials:
  - [ ] Strong password set
  - [ ] SSH key configured (recommended)

## Media Checklist

- [ ] Autoinstall ISO transferred to bootable media:
  - USB drive, OR
  - Virtual media (IPMI/iLO/iDRAC), OR
  - Network boot (if configured)
- [ ] ISO verified bootable in Chapter 7 VirtualBox test

## Network Checklist

- [ ] Target IP address reserved (not in use)
- [ ] Gateway responds to ARP (required for arping detection)
- [ ] Primary DNS server responds to ARP (required for arping detection)
- [ ] Firewall rules allow traffic to/from target IP

## Access Checklist

- [ ] Console access available:
  - Physical monitor/keyboard, OR
  - IPMI/iLO/iDRAC remote console
- [ ] SSH client ready for post-deployment access
- [ ] Network path to target IP confirmed from workstation

## Go/No-Go

Only proceed if ALL items are checked. The autoinstall process will:
- **Wipe the target disk** (ZFS layout)
- Configure static IP via arping detection
- Create admin user with configured credentials
- Install KVM, Cockpit, and multipass

If any item is missing, the deployment may fail or produce an incorrectly configured system.
