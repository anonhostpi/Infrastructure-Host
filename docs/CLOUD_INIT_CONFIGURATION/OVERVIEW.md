# Cloud-init Configuration

This section covers the cloud-init configuration embedded in autoinstall.

## Contents

- [5.1 Cloud-init Configuration Structure](./CONFIGURATION_STRUCTURE.md)
- [5.2 Variables and Templating](./VARIABLES_AND_TEMPLATING.md)

## Overview

Cloud-init handles post-installation configuration on first boot:
- User creation and SSH key setup
- Network configuration via arping detection
- Package installation (KVM, Cockpit, multipass)
- Service enablement and firewall configuration

The cloud-init configuration is embedded in the autoinstall `user-data` field rather than being a separate file. See [4.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) for the complete configuration.
