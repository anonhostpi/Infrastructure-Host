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

#### 3. Network Configuration Planning
**Directory:** `docs/NETWORK_PLANNING/`
- [ ] [Overview](./docs/NETWORK_PLANNING/OVERVIEW.md)
  - [x] [3.1 Network Information Gathering](./docs/NETWORK_PLANNING/NETWORK_INFORMATION_GATHERING.md)
  - [ ] [3.2 Network Topology Considerations](./docs/NETWORK_PLANNING/NETWORK_TOPOLOGY.md)
  - [ ] [3.3 Network Configuration in Cloud-init](./docs/NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md)

#### 4. Creating Ubuntu Autoinstall Media
**Directory:** `docs/AUTOINSTALL_MEDIA_CREATION/`
- [Overview](./docs/AUTOINSTALL_MEDIA_CREATION/OVERVIEW.md)
- [4.1 Download Ubuntu Server ISO](./docs/AUTOINSTALL_MEDIA_CREATION/DOWNLOAD_UBUNTU_ISO.md)
- [4.2 Autoinstall Configuration](./docs/AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md)
- [4.3 Methods to Create Bootable Media](./docs/AUTOINSTALL_MEDIA_CREATION/BOOTABLE_MEDIA_METHODS.md)

#### 5. Cloud-init Configuration
**Directory:** `docs/CLOUD_INIT_CONFIGURATION/`
- [Overview](./docs/CLOUD_INIT_CONFIGURATION/OVERVIEW.md)
- [5.1 Cloud-init Data Sources](./docs/CLOUD_INIT_CONFIGURATION/DATA_SOURCES.md)
- [5.2 Cloud-init Configuration Structure](./docs/CLOUD_INIT_CONFIGURATION/CONFIGURATION_STRUCTURE.md)
- [5.3 Creating Cloud-init ISO](./docs/CLOUD_INIT_CONFIGURATION/CREATING_CLOUD_INIT_ISO.md)
- [5.4 Cloud-init Variables and Templating](./docs/CLOUD_INIT_CONFIGURATION/VARIABLES_AND_TEMPLATING.md)

#### 6. Deployment Process
**Directory:** `docs/DEPLOYMENT_PROCESS/`
- [Overview](./docs/DEPLOYMENT_PROCESS/OVERVIEW.md)
- [6.1 Pre-Deployment Checklist](./docs/DEPLOYMENT_PROCESS/PRE_DEPLOYMENT_CHECKLIST.md)
- [6.2 Step-by-Step Deployment](./docs/DEPLOYMENT_PROCESS/STEP_BY_STEP_DEPLOYMENT.md)
- [6.3 Monitoring Cloud-init Progress](./docs/DEPLOYMENT_PROCESS/MONITORING_CLOUD_INIT.md)

#### 7. Post-Deployment Validation
**Directory:** `docs/POST_DEPLOYMENT_VALIDATION/`
- [Overview](./docs/POST_DEPLOYMENT_VALIDATION/OVERVIEW.md)
- [7.1 System Validation Checklist](./docs/POST_DEPLOYMENT_VALIDATION/VALIDATION_CHECKLIST.md)
- [7.2 Validation Commands](./docs/POST_DEPLOYMENT_VALIDATION/VALIDATION_COMMANDS.md)
- [7.3 Cockpit Access and Configuration](./docs/POST_DEPLOYMENT_VALIDATION/COCKPIT_ACCESS.md)

#### 8. Troubleshooting
**Directory:** `docs/TROUBLESHOOTING/`
- [Overview](./docs/TROUBLESHOOTING/OVERVIEW.md)
- [8.1 Common Issues](./docs/TROUBLESHOOTING/COMMON_ISSUES.md)
- [8.2 Logs and Debugging](./docs/TROUBLESHOOTING/LOGS_AND_DEBUGGING.md)

#### 9. Multiple Server Deployment
**Directory:** `docs/MULTIPLE_SERVER_DEPLOYMENT/`
- [Overview](./docs/MULTIPLE_SERVER_DEPLOYMENT/OVERVIEW.md)
- [9.1 Templating Strategy](./docs/MULTIPLE_SERVER_DEPLOYMENT/TEMPLATING_STRATEGY.md)
- [9.2 Automation Considerations](./docs/MULTIPLE_SERVER_DEPLOYMENT/AUTOMATION_CONSIDERATIONS.md)

#### 10. Security Hardening
**Directory:** `docs/SECURITY_HARDENING/`
- [Overview](./docs/SECURITY_HARDENING/OVERVIEW.md)
- [10.1 Post-Deployment Security](./docs/SECURITY_HARDENING/POST_DEPLOYMENT_SECURITY.md)
- [10.2 Firewall Configuration](./docs/SECURITY_HARDENING/FIREWALL_CONFIGURATION.md)
- [10.3 Monitoring and Logging](./docs/SECURITY_HARDENING/MONITORING_AND_LOGGING.md)

#### 11. Appendix
**Directory:** `docs/APPENDIX/`
- [Overview](./docs/APPENDIX/OVERVIEW.md)
- [11.1 Reference Files](./docs/APPENDIX/REFERENCE_FILES.md)
- [11.2 Useful Commands](./docs/APPENDIX/USEFUL_COMMANDS.md)
- [11.3 Additional Resources](./docs/APPENDIX/ADDITIONAL_RESOURCES.md)
- [11.4 Hardware Compatibility](./docs/APPENDIX/HARDWARE_COMPATIBILITY.md)
