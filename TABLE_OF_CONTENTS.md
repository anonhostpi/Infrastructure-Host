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
