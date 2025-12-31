# 7.1 Pre-Deployment Checklist

Complete this checklist before beginning deployment.

## Checklist

- [ ] BIOS configured (virtualization enabled, boot order set)
- [ ] Network details documented (IP, gateway, DNS)
- [ ] SSH public key ready for cloud-init
- [ ] Autoinstall ISO created and tested
- [ ] Cloud-init ISO created with correct configurations
- [ ] Backup of any existing data (if applicable)
- [ ] USB devices or ISO files ready

## Verification Steps

### BIOS Configuration
- Virtualization extensions enabled
- Boot order set to USB/CD first
- UEFI mode enabled (recommended)

### Network Readiness
- IP address reserved/documented
- Gateway and DNS servers confirmed
- Switch port configured (if using VLANs)

### Media Preparation
- Autoinstall ISO verified and bootable
- Cloud-init ISO created with correct user-data
- Media accessible (USB, virtual media, etc.)

### Access Preparation
- Console access available (physical, IPMI, iLO, iDRAC)
- SSH key pair generated
- Network path to server confirmed

## Go/No-Go Decision

Only proceed if ALL checklist items are complete. Missing any item may result in a failed or incomplete deployment.
