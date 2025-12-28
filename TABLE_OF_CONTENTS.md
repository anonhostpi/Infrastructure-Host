# Bare-Metal Ubuntu Deployment - Table of Contents

This document outlines the complete documentation structure for bare-metal Ubuntu deployment. Each section will be maintained as a separate file for modularity and maintainability.

---

## Documentation Structure

### Core Documentation (`docs/`)

#### 1. Overview & Architecture
**Location:** `docs/OVERVIEW_ARCHITECTURE.md`
- 1.1 Deployment Strategy
- 1.2 Key Components
- 1.3 Architecture Benefits

#### 2. Hardware & BIOS Setup
**Location:** `docs/HARDWARE_BIOS_SETUP.md`
- 2.1 Hardware Requirements
- 2.2 Pre-Installation Hardware Checklist
- 2.3 BIOS/UEFI Configuration
  - Access BIOS
  - Critical BIOS Settings
  - Boot Settings
  - Virtualization Support
  - Power Management
  - Storage Configuration
  - Network Settings
  - BIOS Configuration Checklist

#### 3. Network Configuration Planning
**Location:** `docs/NETWORK_PLANNING.md`
- 3.1 Network Information Gathering
- 3.2 Network Topology Considerations
- 3.3 Network Configuration in Cloud-init

#### 4. Creating Ubuntu Autoinstall Media
**Location:** `docs/AUTOINSTALL_MEDIA_CREATION.md`
- 4.1 Download Ubuntu Server ISO
- 4.2 Autoinstall Configuration
- 4.3 Methods to Create Bootable Media
  - Method A: Modify ISO with autoinstall
  - Method B: USB with separate autoinstall files

#### 5. Cloud-init Configuration
**Location:** `docs/CLOUD_INIT_CONFIGURATION.md`
- 5.1 Cloud-init Data Sources
- 5.2 Cloud-init Configuration Structure
- 5.3 Creating Cloud-init ISO
- 5.4 Cloud-init Variables and Templating

#### 6. Deployment Process
**Location:** `docs/DEPLOYMENT_PROCESS.md`
- 6.1 Pre-Deployment Checklist
- 6.2 Step-by-Step Deployment
  - Step 1: Boot from Installation Media
  - Step 2: Monitor Autoinstall Process
  - Step 3: First Boot - Cloud-init Execution
  - Step 4: Attach Cloud-init Configuration
- 6.3 Monitoring Cloud-init Progress

#### 7. Post-Deployment Validation
**Location:** `docs/POST_DEPLOYMENT_VALIDATION.md`
- 7.1 System Validation Checklist
- 7.2 Validation Commands
- 7.3 Cockpit Access and Configuration

#### 8. Troubleshooting
**Location:** `docs/TROUBLESHOOTING.md`
- 8.1 Common Issues
- 8.2 Logs and Debugging

#### 9. Multiple Server Deployment
**Location:** `docs/MULTIPLE_SERVER_DEPLOYMENT.md`
- 9.1 Templating Strategy
- 9.2 Automation Considerations

#### 10. Security Hardening
**Location:** `docs/SECURITY_HARDENING.md`
- 10.1 Post-Deployment Security
- 10.2 Firewall Configuration
- 10.3 Monitoring and Logging

#### 11. Appendix
**Location:** `docs/APPENDIX.md`
- 11.1 Reference Files
- 11.2 Useful Commands
- 11.3 Additional Resources
- 11.4 Hardware Compatibility

---

### Configuration Templates (`config/`)

#### Autoinstall Configuration
**Location:** `config/autoinstall/`
- `user-data.yaml` - Autoinstall user-data template
- `meta-data.yaml` - Autoinstall meta-data template
- `grub.cfg` - GRUB configuration for autoinstall

#### Cloud-init Configuration
**Location:** `config/cloud-init/`
- `user-data.yaml` - Production cloud-init user-data template
- `user-data.minimal.yaml` - Minimal cloud-init for testing
- `meta-data.yaml` - Cloud-init meta-data template
- `network-config.yaml` - Network configuration template

#### Network Templates
**Location:** `config/network/`
- `netplan-static.yaml` - Static IP configuration
- `netplan-bonded.yaml` - NIC bonding configuration
- `netplan-vlan.yaml` - VLAN configuration
- `netplan-bridge.yaml` - Bridge configuration for VMs

#### Service Configurations
**Location:** `config/services/`
- `cockpit.conf` - Cockpit web service configuration
- `docker-daemon.json` - Docker daemon configuration
- `ufw-rules.txt` - UFW firewall rules
- `motd` - Custom message of the day

---

### Scripts & Automation (`scripts/`)

#### ISO Creation Scripts
**Location:** `scripts/iso-creation/`
- `create-autoinstall-iso.sh` - Build custom autoinstall ISO
- `create-cloud-init-iso.sh` - Generate cloud-init configuration ISO
- `extract-iso.sh` - Extract Ubuntu ISO contents
- `rebuild-iso.sh` - Rebuild modified ISO

#### Deployment Scripts
**Location:** `scripts/deployment/`
- `generate-config.sh` - Generate per-host configurations
- `write-usb.sh` - Write ISO to USB drive
- `validate-deployment.sh` - Post-deployment validation script

#### Template Generation
**Location:** `scripts/templates/`
- `generate-multiple-hosts.sh` - Batch configuration generator
- `template-variables.env` - Environment variables for templating

#### Utilities
**Location:** `scripts/utils/`
- `check-virtualization.sh` - Verify virtualization support
- `password-hash-generator.sh` - Generate password hashes
- `validate-cloud-init.sh` - Validate cloud-init syntax
- `network-test.sh` - Network connectivity testing

---

### Examples (`examples/`)

#### Single Server Examples
**Location:** `examples/single-server/`
- `basic-server/` - Minimal configuration example
  - `user-data.yaml`
  - `meta-data.yaml`
  - `README.md`
- `virtualization-host/` - KVM/QEMU host example
  - `user-data.yaml`
  - `meta-data.yaml`
  - `network-config.yaml`
  - `README.md`
- `cockpit-management/` - Cockpit-focused example
  - `user-data.yaml`
  - `meta-data.yaml`
  - `README.md`

#### Multiple Server Examples
**Location:** `examples/multi-server/`
- `lab-cluster/` - 3-node lab cluster
  - `host-01/`
  - `host-02/`
  - `host-03/`
  - `generate-all.sh`
  - `README.md`
- `production-setup/` - Production deployment example
  - `templates/`
  - `inventory.yaml`
  - `README.md`

#### Network Configurations
**Location:** `examples/network/`
- `static-ip/` - Static IP examples
- `bonded-nics/` - NIC bonding examples
- `vlan-config/` - VLAN configuration examples
- `bridge-setup/` - VM bridge examples

---

### Testing & Validation (`tests/`)

#### Validation Scripts
**Location:** `tests/validation/`
- `test-system-config.sh` - System configuration tests
- `test-networking.sh` - Network connectivity tests
- `test-virtualization.sh` - KVM/libvirt tests
- `test-cockpit.sh` - Cockpit accessibility tests
- `test-cloud-init.sh` - Cloud-init execution tests

#### Test Fixtures
**Location:** `tests/fixtures/`
- `minimal-user-data.yaml` - Minimal test configuration
- `test-meta-data.yaml` - Test metadata
- `mock-network-config.yaml` - Mock network configuration

---

### Reference Documentation (`docs/reference/`)

#### Quick Reference
**Location:** `docs/reference/`
- `command-reference.md` - Useful commands quick reference
- `bios-keys-by-vendor.md` - BIOS access keys for different hardware
- `cloud-init-modules.md` - Cloud-init modules reference
- `netplan-reference.md` - Netplan configuration reference
- `troubleshooting-flowcharts.md` - Decision trees for common issues

#### Hardware Compatibility
**Location:** `docs/reference/hardware/`
- `tested-hardware.md` - Verified hardware configurations
- `network-cards.md` - Network card compatibility
- `raid-controllers.md` - RAID controller compatibility

---

### Ansible Automation (Optional)
**Location:** `ansible/`
- `playbooks/`
  - `create-cloud-init.yml` - Automate cloud-init ISO creation
  - `deploy-bare-metal.yml` - Orchestrate deployment
  - `validate-deployment.yml` - Post-deployment validation
- `roles/`
  - `cloud-init-generator/` - Cloud-init generation role
  - `iso-builder/` - ISO creation role
- `inventory/`
  - `hosts.yaml` - Inventory file template
- `group_vars/`
  - `all.yml` - Global variables
- `README.md` - Ansible automation documentation

---

### Terraform Infrastructure (Optional)
**Location:** `terraform/`
- `modules/`
  - `bare-metal-server/` - Server provisioning module
  - `network-config/` - Network configuration module
- `environments/`
  - `dev/` - Development environment
  - `prod/` - Production environment
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `README.md` - Terraform documentation

---

## Project Root Files

- `README.md` - Project overview and quick start guide
- `TABLE_OF_CONTENTS.md` - This file - complete documentation index
- `BARE_METAL_DEPLOYMENT_PLAN.md` - Consolidated documentation (legacy/reference)
- `CHANGELOG.md` - Version history and changes
- `CONTRIBUTING.md` - Contribution guidelines
- `LICENSE` - License information
- `.gitignore` - Git ignore patterns

---

## Recommended Reading Order

### For First-Time Users:
1. `README.md` - Start here
2. `docs/OVERVIEW_ARCHITECTURE.md` - Understand the approach
3. `docs/HARDWARE_BIOS_SETUP.md` - Prepare hardware
4. `docs/NETWORK_PLANNING.md` - Plan network configuration
5. `docs/AUTOINSTALL_MEDIA_CREATION.md` - Create installation media
6. `docs/CLOUD_INIT_CONFIGURATION.md` - Configure cloud-init
7. `docs/DEPLOYMENT_PROCESS.md` - Deploy
8. `docs/POST_DEPLOYMENT_VALIDATION.md` - Validate

### For Quick Deployment:
1. `examples/single-server/basic-server/` - Use example as starting point
2. `scripts/iso-creation/create-autoinstall-iso.sh` - Build ISO
3. `scripts/iso-creation/create-cloud-init-iso.sh` - Build cloud-init ISO
4. `docs/DEPLOYMENT_PROCESS.md` - Deploy
5. `scripts/deployment/validate-deployment.sh` - Validate

### For Multiple Servers:
1. `docs/MULTIPLE_SERVER_DEPLOYMENT.md` - Templating strategy
2. `examples/multi-server/lab-cluster/` - Review example
3. `scripts/templates/generate-multiple-hosts.sh` - Generate configs
4. `ansible/` or `terraform/` - Consider automation

### For Troubleshooting:
1. `docs/TROUBLESHOOTING.md` - Common issues
2. `docs/reference/troubleshooting-flowcharts.md` - Decision trees
3. `tests/validation/` - Run validation scripts

---

## File Organization Principles

1. **Modularity** - Each document focuses on a single topic
2. **Reusability** - Configuration templates can be used independently
3. **Scalability** - Structure supports both single and multiple server deployments
4. **Automation-Ready** - Scripts and templates enable CI/CD integration
5. **Version Control Friendly** - Small, focused files are easier to track and merge

---

## Version Information

- **Table of Contents Version:** 1.0
- **Created:** 2025-12-27
- **Purpose:** Documentation structure and organization guide
- **Status:** Planning - files to be created based on this structure

---

## Notes

- All file paths are relative to repository root
- `.yaml` extension used for consistency (can also use `.yml`)
- Scripts should be executable: `chmod +x scripts/**/*.sh`
- Example configurations include inline documentation
- Reference documentation supplements main documentation
- Optional automation directories (Ansible, Terraform) can be added as needed
