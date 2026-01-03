# Bare-Metal Ubuntu Deployment - Table of Contents

This document outlines the complete documentation structure for bare-metal Ubuntu deployment. Each section will be maintained as a separate file for modularity and maintainability.

---

## Documentation Structure

### Core Documentation (`docs/`)

#### 1. Overview & Architecture
**Directory:** `docs/OVERVIEW_ARCHITECTURE/`
- [x] [Overview](./docs/OVERVIEW_ARCHITECTURE/OVERVIEW.md)
  - [x] [1.1 Deployment Strategy](./docs/OVERVIEW_ARCHITECTURE/DEPLOYMENT_STRATEGY.md)
  - [x] [1.2 Key Components](./docs/OVERVIEW_ARCHITECTURE/KEY_COMPONENTS.md)
  - [x] [1.3 Architecture Benefits](./docs/OVERVIEW_ARCHITECTURE/ARCHITECTURE_BENEFITS.md)

#### 2. Hardware & BIOS Setup
**Directory:** `docs/HARDWARE_BIOS_SETUP/`
- [x] [Overview](./docs/HARDWARE_BIOS_SETUP/OVERVIEW.md)
  - [x] [2.1 Hardware Requirements](./docs/HARDWARE_BIOS_SETUP/HARDWARE_REQUIREMENTS.md)
  - [x] [2.2 Pre-Installation Hardware Checklist](./docs/HARDWARE_BIOS_SETUP/PRE_INSTALLATION_CHECKLIST.md)
  - [x] [2.3 BIOS/UEFI Configuration](./docs/HARDWARE_BIOS_SETUP/BIOS_UEFI_CONFIGURATION.md)

#### 3. Build System
**Directory:** `docs/BUILD_SYSTEM/`
- [ ] [Overview](./docs/BUILD_SYSTEM/OVERVIEW.md)
  - [ ] [3.1 BuildContext](./docs/BUILD_SYSTEM/BUILD_CONTEXT.md)
  - [ ] [3.2 Jinja2 Filters](./docs/BUILD_SYSTEM/JINJA2_FILTERS.md)
  - [ ] [3.3 Render CLI](./docs/BUILD_SYSTEM/RENDER_CLI.md)
  - [ ] [3.4 Makefile Interface](./docs/BUILD_SYSTEM/MAKEFILE_INTERFACE.md)

#### 4. Network Configuration Planning
**Directory:** `docs/NETWORK_PLANNING/`
- [ ] [Overview](./docs/NETWORK_PLANNING/OVERVIEW.md)
  - [x] [4.1 Network Information Gathering](./docs/NETWORK_PLANNING/NETWORK_INFORMATION_GATHERING.md)
  - [x] [4.2 Network Topology Considerations](./docs/NETWORK_PLANNING/NETWORK_TOPOLOGY.md)
  - [ ] [4.3 Network Scripts](./docs/NETWORK_PLANNING/NETWORK_SCRIPTS.md)

#### 5. Creating Ubuntu Autoinstall Media
**Directory:** `docs/AUTOINSTALL_MEDIA_CREATION/`
- [ ] [Overview](./docs/AUTOINSTALL_MEDIA_CREATION/OVERVIEW.md)
  - [ ] [5.1 Download Ubuntu Server ISO](./docs/AUTOINSTALL_MEDIA_CREATION/DOWNLOAD_UBUNTU_ISO.md)
  - [ ] [5.2 Autoinstall Configuration](./docs/AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md)
  - [ ] [5.3 Bootable Media Creation](./docs/AUTOINSTALL_MEDIA_CREATION/TESTED_BOOTABLE_MEDIA_CREATION.md)

#### 6. Cloud-init Configuration
**Directory:** `docs/CLOUD_INIT_CONFIGURATION/`
- [ ] [Overview](./docs/CLOUD_INIT_CONFIGURATION/OVERVIEW.md)
  - [ ] [6.1 Network Fragment](./docs/CLOUD_INIT_CONFIGURATION/NETWORK_FRAGMENT.md)
  - [ ] [6.2 Kernel Hardening Fragment](./docs/CLOUD_INIT_CONFIGURATION/KERNEL_HARDENING_FRAGMENT.md)
  - [ ] [6.3 Users Fragment](./docs/CLOUD_INIT_CONFIGURATION/USERS_FRAGMENT.md)
  - [ ] [6.4 SSH Hardening Fragment](./docs/CLOUD_INIT_CONFIGURATION/SSH_HARDENING_FRAGMENT.md)
  - [ ] [6.5 UFW Fragment](./docs/CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md)
  - [ ] [6.6 System Settings Fragment](./docs/CLOUD_INIT_CONFIGURATION/SYSTEM_SETTINGS_FRAGMENT.md)
  - [ ] [6.7 MSMTP Fragment](./docs/CLOUD_INIT_CONFIGURATION/MSMTP_FRAGMENT.md)
  - [ ] [6.8 Package Security Fragment](./docs/CLOUD_INIT_CONFIGURATION/PACKAGE_SECURITY_FRAGMENT.md)
  - [ ] [6.9 Security Monitoring Fragment](./docs/CLOUD_INIT_CONFIGURATION/SECURITY_MONITORING_FRAGMENT.md)
  - [ ] [6.10 Virtualization Fragment](./docs/CLOUD_INIT_CONFIGURATION/VIRTUALIZATION_FRAGMENT.md)
  - [ ] [6.11 Cockpit Fragment](./docs/CLOUD_INIT_CONFIGURATION/COCKPIT_FRAGMENT.md)
  - [ ] [6.12 UI Touches Fragment](./docs/CLOUD_INIT_CONFIGURATION/UI_TOUCHES_FRAGMENT.md)

#### 7. Testing and Validation
**Directory:** `docs/TESTING_AND_VALIDATION/`
- [ ] [Overview](./docs/TESTING_AND_VALIDATION/OVERVIEW.md)
  - [ ] [7.1 Cloud-init Testing](./docs/TESTING_AND_VALIDATION/CLOUD_INIT_TESTING.md)
  - [ ] [7.2 Autoinstall Testing](./docs/TESTING_AND_VALIDATION/AUTOINSTALL_TESTING.md)

#### 8. Deployment Process
**Directory:** `docs/DEPLOYMENT_PROCESS/`
- [Overview](./docs/DEPLOYMENT_PROCESS/OVERVIEW.md)
- [8.1 Pre-Deployment Checklist](./docs/DEPLOYMENT_PROCESS/PRE_DEPLOYMENT_CHECKLIST.md)
- [8.2 Step-by-Step Deployment](./docs/DEPLOYMENT_PROCESS/STEP_BY_STEP_DEPLOYMENT.md)
- [8.3 Monitoring Cloud-init Progress](./docs/DEPLOYMENT_PROCESS/MONITORING_CLOUD_INIT.md)

#### 9. Post-Deployment Validation
**Directory:** `docs/POST_DEPLOYMENT_VALIDATION/`
- [Overview](./docs/POST_DEPLOYMENT_VALIDATION/OVERVIEW.md)
- [9.1 System Validation Checklist](./docs/POST_DEPLOYMENT_VALIDATION/VALIDATION_CHECKLIST.md)
- [9.2 Validation Commands](./docs/POST_DEPLOYMENT_VALIDATION/VALIDATION_COMMANDS.md)
- [9.3 Cockpit Access and Configuration](./docs/POST_DEPLOYMENT_VALIDATION/COCKPIT_ACCESS.md)

#### 10. Troubleshooting
**Directory:** `docs/TROUBLESHOOTING/`
- [Overview](./docs/TROUBLESHOOTING/OVERVIEW.md)
- [10.1 Common Issues](./docs/TROUBLESHOOTING/COMMON_ISSUES.md)
- [10.2 Logs and Debugging](./docs/TROUBLESHOOTING/LOGS_AND_DEBUGGING.md)

#### 11. Security Hardening
**Directory:** `docs/SECURITY_HARDENING/`
- [Overview](./docs/SECURITY_HARDENING/OVERVIEW.md)
- [11.1 Post-Deployment Security](./docs/SECURITY_HARDENING/POST_DEPLOYMENT_SECURITY.md)
- [11.2 Firewall Configuration](./docs/SECURITY_HARDENING/FIREWALL_CONFIGURATION.md)
- [11.3 Monitoring and Logging](./docs/SECURITY_HARDENING/MONITORING_AND_LOGGING.md)

#### 12. Appendix
**Directory:** `docs/APPENDIX/`
- [Overview](./docs/APPENDIX/OVERVIEW.md)
- [12.1 Reference Files](./docs/APPENDIX/REFERENCE_FILES.md)
- [12.2 Useful Commands](./docs/APPENDIX/USEFUL_COMMANDS.md)
- [12.3 Additional Resources](./docs/APPENDIX/ADDITIONAL_RESOURCES.md)
- [12.4 Hardware Compatibility](./docs/APPENDIX/HARDWARE_COMPATIBILITY.md)
