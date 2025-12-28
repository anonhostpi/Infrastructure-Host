# Bare-Metal Ubuntu Deployment - Table of Contents

This document outlines the complete documentation structure for bare-metal Ubuntu deployment. Each section will be maintained as a separate file for modularity and maintainability.

---

## Documentation Structure

### Core Documentation (`docs/`)

#### 1. Overview & Architecture
**Directory:** `docs/OVERVIEW_ARCHITECTURE/`
- `OVERVIEW.md` - Main section overview
- `DEPLOYMENT_STRATEGY.md` - 1.1 Deployment Strategy
- `KEY_COMPONENTS.md` - 1.2 Key Components
- `ARCHITECTURE_BENEFITS.md` - 1.3 Architecture Benefits

#### 2. Hardware & BIOS Setup
**Directory:** `docs/HARDWARE_BIOS_SETUP/`
- `OVERVIEW.md` - Main section overview
- `HARDWARE_REQUIREMENTS.md` - 2.1 Hardware Requirements
- `PRE_INSTALLATION_CHECKLIST.md` - 2.2 Pre-Installation Hardware Checklist
- `BIOS_UEFI_CONFIGURATION.md` - 2.3 BIOS/UEFI Configuration
  - Includes: Access BIOS, Critical BIOS Settings, Boot Settings, Virtualization Support, Power Management, Storage Configuration, Network Settings, BIOS Configuration Checklist

#### 3. Network Configuration Planning
**Directory:** `docs/NETWORK_PLANNING/`
- `OVERVIEW.md` - Main section overview
- `NETWORK_INFORMATION_GATHERING.md` - 3.1 Network Information Gathering
- `NETWORK_TOPOLOGY.md` - 3.2 Network Topology Considerations
- `CLOUD_INIT_NETWORK_CONFIG.md` - 3.3 Network Configuration in Cloud-init

#### 4. Creating Ubuntu Autoinstall Media
**Directory:** `docs/AUTOINSTALL_MEDIA_CREATION/`
- `OVERVIEW.md` - Main section overview
- `DOWNLOAD_UBUNTU_ISO.md` - 4.1 Download Ubuntu Server ISO
- `AUTOINSTALL_CONFIGURATION.md` - 4.2 Autoinstall Configuration
- `BOOTABLE_MEDIA_METHODS.md` - 4.3 Methods to Create Bootable Media
  - Includes: Method A (Modify ISO), Method B (USB with separate files)

#### 5. Cloud-init Configuration
**Directory:** `docs/CLOUD_INIT_CONFIGURATION/`
- `OVERVIEW.md` - Main section overview
- `DATA_SOURCES.md` - 5.1 Cloud-init Data Sources
- `CONFIGURATION_STRUCTURE.md` - 5.2 Cloud-init Configuration Structure
- `CREATING_CLOUD_INIT_ISO.md` - 5.3 Creating Cloud-init ISO
- `VARIABLES_AND_TEMPLATING.md` - 5.4 Cloud-init Variables and Templating

#### 6. Deployment Process
**Directory:** `docs/DEPLOYMENT_PROCESS/`
- `OVERVIEW.md` - Main section overview
- `PRE_DEPLOYMENT_CHECKLIST.md` - 6.1 Pre-Deployment Checklist
- `STEP_BY_STEP_DEPLOYMENT.md` - 6.2 Step-by-Step Deployment
  - Includes: Boot from Installation Media, Monitor Autoinstall, First Boot - Cloud-init Execution, Attach Cloud-init Configuration
- `MONITORING_CLOUD_INIT.md` - 6.3 Monitoring Cloud-init Progress

#### 7. Post-Deployment Validation
**Directory:** `docs/POST_DEPLOYMENT_VALIDATION/`
- `OVERVIEW.md` - Main section overview
- `VALIDATION_CHECKLIST.md` - 7.1 System Validation Checklist
- `VALIDATION_COMMANDS.md` - 7.2 Validation Commands
- `COCKPIT_ACCESS.md` - 7.3 Cockpit Access and Configuration

#### 8. Troubleshooting
**Directory:** `docs/TROUBLESHOOTING/`
- `OVERVIEW.md` - Main section overview
- `COMMON_ISSUES.md` - 8.1 Common Issues
- `LOGS_AND_DEBUGGING.md` - 8.2 Logs and Debugging

#### 9. Multiple Server Deployment
**Directory:** `docs/MULTIPLE_SERVER_DEPLOYMENT/`
- `OVERVIEW.md` - Main section overview
- `TEMPLATING_STRATEGY.md` - 9.1 Templating Strategy
- `AUTOMATION_CONSIDERATIONS.md` - 9.2 Automation Considerations

#### 10. Security Hardening
**Directory:** `docs/SECURITY_HARDENING/`
- `OVERVIEW.md` - Main section overview
- `POST_DEPLOYMENT_SECURITY.md` - 10.1 Post-Deployment Security
- `FIREWALL_CONFIGURATION.md` - 10.2 Firewall Configuration
- `MONITORING_AND_LOGGING.md` - 10.3 Monitoring and Logging

#### 11. Appendix
**Directory:** `docs/APPENDIX/`
- `OVERVIEW.md` - Main section overview
- `REFERENCE_FILES.md` - 11.1 Reference Files
- `USEFUL_COMMANDS.md` - 11.2 Useful Commands
- `ADDITIONAL_RESOURCES.md` - 11.3 Additional Resources
- `HARDWARE_COMPATIBILITY.md` - 11.4 Hardware Compatibility

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
2. `docs/OVERVIEW_ARCHITECTURE/OVERVIEW.md` - Understand the approach
3. `docs/HARDWARE_BIOS_SETUP/OVERVIEW.md` - Prepare hardware
4. `docs/NETWORK_PLANNING/OVERVIEW.md` - Plan network configuration
5. `docs/AUTOINSTALL_MEDIA_CREATION/OVERVIEW.md` - Create installation media
6. `docs/CLOUD_INIT_CONFIGURATION/OVERVIEW.md` - Configure cloud-init
7. `docs/DEPLOYMENT_PROCESS/OVERVIEW.md` - Deploy
8. `docs/POST_DEPLOYMENT_VALIDATION/OVERVIEW.md` - Validate

### For Quick Deployment:
1. `examples/single-server/basic-server/` - Use example as starting point
2. `scripts/iso-creation/create-autoinstall-iso.sh` - Build ISO
3. `scripts/iso-creation/create-cloud-init-iso.sh` - Build cloud-init ISO
4. `docs/DEPLOYMENT_PROCESS/OVERVIEW.md` - Deploy
5. `scripts/deployment/validate-deployment.sh` - Validate

### For Multiple Servers:
1. `docs/MULTIPLE_SERVER_DEPLOYMENT/OVERVIEW.md` - Templating strategy
2. `examples/multi-server/lab-cluster/` - Review example
3. `scripts/templates/generate-multiple-hosts.sh` - Generate configs
4. `ansible/` or `terraform/` - Consider automation

### For Troubleshooting:
1. `docs/TROUBLESHOOTING/OVERVIEW.md` - Common issues
2. `docs/reference/troubleshooting-flowcharts.md` - Decision trees
3. `tests/validation/` - Run validation scripts

---

## Visual Directory Structure

```
Infrastructure-Host/
├── README.md
├── TABLE_OF_CONTENTS.md
├── BARE_METAL_DEPLOYMENT_PLAN.md (legacy reference)
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
│
├── docs/
│   ├── OVERVIEW_ARCHITECTURE/
│   │   ├── OVERVIEW.md
│   │   ├── DEPLOYMENT_STRATEGY.md
│   │   ├── KEY_COMPONENTS.md
│   │   └── ARCHITECTURE_BENEFITS.md
│   ├── HARDWARE_BIOS_SETUP/
│   │   ├── OVERVIEW.md
│   │   ├── HARDWARE_REQUIREMENTS.md
│   │   ├── PRE_INSTALLATION_CHECKLIST.md
│   │   └── BIOS_UEFI_CONFIGURATION.md
│   ├── NETWORK_PLANNING/
│   │   ├── OVERVIEW.md
│   │   ├── NETWORK_INFORMATION_GATHERING.md
│   │   ├── NETWORK_TOPOLOGY.md
│   │   └── CLOUD_INIT_NETWORK_CONFIG.md
│   ├── AUTOINSTALL_MEDIA_CREATION/
│   │   ├── OVERVIEW.md
│   │   ├── DOWNLOAD_UBUNTU_ISO.md
│   │   ├── AUTOINSTALL_CONFIGURATION.md
│   │   └── BOOTABLE_MEDIA_METHODS.md
│   ├── CLOUD_INIT_CONFIGURATION/
│   │   ├── OVERVIEW.md
│   │   ├── DATA_SOURCES.md
│   │   ├── CONFIGURATION_STRUCTURE.md
│   │   ├── CREATING_CLOUD_INIT_ISO.md
│   │   └── VARIABLES_AND_TEMPLATING.md
│   ├── DEPLOYMENT_PROCESS/
│   │   ├── OVERVIEW.md
│   │   ├── PRE_DEPLOYMENT_CHECKLIST.md
│   │   ├── STEP_BY_STEP_DEPLOYMENT.md
│   │   └── MONITORING_CLOUD_INIT.md
│   ├── POST_DEPLOYMENT_VALIDATION/
│   │   ├── OVERVIEW.md
│   │   ├── VALIDATION_CHECKLIST.md
│   │   ├── VALIDATION_COMMANDS.md
│   │   └── COCKPIT_ACCESS.md
│   ├── TROUBLESHOOTING/
│   │   ├── OVERVIEW.md
│   │   ├── COMMON_ISSUES.md
│   │   └── LOGS_AND_DEBUGGING.md
│   ├── MULTIPLE_SERVER_DEPLOYMENT/
│   │   ├── OVERVIEW.md
│   │   ├── TEMPLATING_STRATEGY.md
│   │   └── AUTOMATION_CONSIDERATIONS.md
│   ├── SECURITY_HARDENING/
│   │   ├── OVERVIEW.md
│   │   ├── POST_DEPLOYMENT_SECURITY.md
│   │   ├── FIREWALL_CONFIGURATION.md
│   │   └── MONITORING_AND_LOGGING.md
│   ├── APPENDIX/
│   │   ├── OVERVIEW.md
│   │   ├── REFERENCE_FILES.md
│   │   ├── USEFUL_COMMANDS.md
│   │   ├── ADDITIONAL_RESOURCES.md
│   │   └── HARDWARE_COMPATIBILITY.md
│   └── reference/
│       ├── command-reference.md
│       ├── bios-keys-by-vendor.md
│       ├── cloud-init-modules.md
│       ├── netplan-reference.md
│       ├── troubleshooting-flowcharts.md
│       └── hardware/
│           ├── tested-hardware.md
│           ├── network-cards.md
│           └── raid-controllers.md
│
├── config/
│   ├── autoinstall/
│   │   ├── user-data.yaml
│   │   ├── meta-data.yaml
│   │   └── grub.cfg
│   ├── cloud-init/
│   │   ├── user-data.yaml
│   │   ├── user-data.minimal.yaml
│   │   ├── meta-data.yaml
│   │   └── network-config.yaml
│   ├── network/
│   │   ├── netplan-static.yaml
│   │   ├── netplan-bonded.yaml
│   │   ├── netplan-vlan.yaml
│   │   └── netplan-bridge.yaml
│   └── services/
│       ├── cockpit.conf
│       ├── docker-daemon.json
│       ├── ufw-rules.txt
│       └── motd
│
├── scripts/
│   ├── iso-creation/
│   │   ├── create-autoinstall-iso.sh
│   │   ├── create-cloud-init-iso.sh
│   │   ├── extract-iso.sh
│   │   └── rebuild-iso.sh
│   ├── deployment/
│   │   ├── generate-config.sh
│   │   ├── write-usb.sh
│   │   └── validate-deployment.sh
│   ├── templates/
│   │   ├── generate-multiple-hosts.sh
│   │   └── template-variables.env
│   └── utils/
│       ├── check-virtualization.sh
│       ├── password-hash-generator.sh
│       ├── validate-cloud-init.sh
│       └── network-test.sh
│
├── examples/
│   ├── single-server/
│   │   ├── basic-server/
│   │   │   ├── user-data.yaml
│   │   │   ├── meta-data.yaml
│   │   │   └── README.md
│   │   ├── virtualization-host/
│   │   │   ├── user-data.yaml
│   │   │   ├── meta-data.yaml
│   │   │   ├── network-config.yaml
│   │   │   └── README.md
│   │   └── cockpit-management/
│   │       ├── user-data.yaml
│   │       ├── meta-data.yaml
│   │       └── README.md
│   ├── multi-server/
│   │   ├── lab-cluster/
│   │   │   ├── host-01/
│   │   │   ├── host-02/
│   │   │   ├── host-03/
│   │   │   ├── generate-all.sh
│   │   │   └── README.md
│   │   └── production-setup/
│   │       ├── templates/
│   │       ├── inventory.yaml
│   │       └── README.md
│   └── network/
│       ├── static-ip/
│       ├── bonded-nics/
│       ├── vlan-config/
│       └── bridge-setup/
│
├── tests/
│   ├── validation/
│   │   ├── test-system-config.sh
│   │   ├── test-networking.sh
│   │   ├── test-virtualization.sh
│   │   ├── test-cockpit.sh
│   │   └── test-cloud-init.sh
│   └── fixtures/
│       ├── minimal-user-data.yaml
│       ├── test-meta-data.yaml
│       └── mock-network-config.yaml
│
├── ansible/ (optional)
│   ├── playbooks/
│   ├── roles/
│   ├── inventory/
│   ├── group_vars/
│   └── README.md
│
└── terraform/ (optional)
    ├── modules/
    ├── environments/
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

---

## File Organization Principles

1. **Modularity** - Each document focuses on a single topic
2. **Reusability** - Configuration templates can be used independently
3. **Scalability** - Structure supports both single and multiple server deployments
4. **Automation-Ready** - Scripts and templates enable CI/CD integration
5. **Version Control Friendly** - Small, focused files are easier to track and merge
6. **Hierarchical Organization** - Major sections are directories; subsections are files within those directories

---

## Version Information

- **Table of Contents Version:** 2.0
- **Created:** 2025-12-27
- **Last Updated:** 2025-12-27
- **Purpose:** Documentation structure and organization guide
- **Status:** Planning - files to be created based on this structure
- **Structure:** Hierarchical directory-based organization with OVERVIEW.md files

---

## Notes

- All file paths are relative to repository root
- Documentation follows hierarchical structure: each major section is a directory with `OVERVIEW.md` and subsection files
- Major sections use `UPPER_UNDERSCORE_CASE` for directory names
- All markdown files use `UPPER_UNDERSCORE_CASE.md` naming convention
- Each section directory contains an `OVERVIEW.md` file as the entry point
- `.yaml` extension used for consistency (can also use `.yml`)
- Scripts should be executable: `chmod +x scripts/**/*.sh`
- Example configurations include inline documentation
- Reference documentation supplements main documentation
- Optional automation directories (Ansible, Terraform) can be added as needed
