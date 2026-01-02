# Creating Ubuntu Autoinstall Media

This section covers creating bootable installation media with autoinstall configuration.

## Contents

- [5.1 Download Ubuntu Server ISO](./DOWNLOAD_UBUNTU_ISO.md)
- [5.2 Autoinstall Configuration](./AUTOINSTALL_CONFIGURATION.md)
- [5.3 Bootable Media Creation](./TESTED_BOOTABLE_MEDIA_CREATION.md)

## Overview

Ubuntu's autoinstall feature allows fully automated installation without manual intervention. The build system generates `user-data` from Jinja2 templates, embedding both autoinstall directives and cloud-init configuration.
