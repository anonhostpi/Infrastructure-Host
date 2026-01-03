# 1.2 Key Components

## Core Technologies

- **Ubuntu Server** - Base operating system (latest LTS recommended: 24.04)
- **Autoinstall** - Ubuntu's automated installation system (Subiquity-based)
- **Cloud-init** - Post-installation configuration automation
- **Jinja2 Build System** - Template-based configuration generation
- **libvirt/KVM** - Virtualization platform
- **Cockpit** - Web-based server management interface (via SSH tunnel)

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

Configuration is composed from multiple fragments that are merged at build time. See [Chapter 6](../CLOUD_INIT_CONFIGURATION/OVERVIEW.md) for fragment details.

### Jinja2 Build System
The build system generates deployment artifacts from templates:
- **BuildContext** - Loads `*.config.yaml` files and exposes them to templates
- **Custom Filters** - Shell quoting, password hashing, CIDR parsing
- **Fragment Composition** - Merges multiple cloud-init fragments via deep merge
- **Makefile Interface** - Standard `make` targets for building artifacts

See [Chapter 3](../BUILD_SYSTEM/OVERVIEW.md) for implementation details.

### libvirt/KVM
The virtualization layer for running VMs on the infrastructure host:
- **qemu-kvm** - Hardware-accelerated virtualization
- **libvirt** - VM management API and daemon
- **virsh** - Command-line VM management
- **multipass** - Ubuntu VM management for testing

See [6.9 Virtualization Fragment](../CLOUD_INIT_CONFIGURATION/VIRTUALIZATION_FRAGMENT.md) for configuration.

### Cockpit
Cockpit provides a web-based management interface for:
- System monitoring
- Virtual machine management (via cockpit-machines)
- Storage management
- Terminal access

**Access Method:** Cockpit binds to localhost only (port 443) and is accessed via SSH local port forwarding:

```bash
ssh -L 443:localhost:443 user@host
# Then open https://localhost in browser
```

This approach eliminates network exposure and leverages SSH for authentication. See [6.10 Cockpit Fragment](../CLOUD_INIT_CONFIGURATION/COCKPIT_FRAGMENT.md) for details.
