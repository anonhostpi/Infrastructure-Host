# 1.2 Key Components

## Core Technologies

- **Ubuntu Server** - Base operating system (latest LTS recommended: 22.04 or 24.04)
- **Autoinstall** - Ubuntu's automated installation system (Subiquity-based)
- **Cloud-init** - Post-installation configuration automation
- **Cockpit** - Web-based server management interface

## Component Roles

### Ubuntu Server
The foundation of the deployment. Ubuntu Server LTS provides long-term support and stability for infrastructure workloads.

### Autoinstall
Autoinstall is Ubuntu's answer to preseed/kickstart for automated installations. It uses a YAML-based configuration format and integrates with the Subiquity installer.

### Cloud-init
Cloud-init handles post-installation configuration including:
- Network configuration
- User and SSH key management
- Package installation
- Custom script execution
- Service configuration

### Cockpit
Cockpit provides a web-based management interface for:
- System monitoring
- Virtual machine management
- Container management
- Network configuration
- Storage management
