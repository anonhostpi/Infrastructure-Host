# Testing and Validation

This section covers testing the build artifacts before deploying to bare metal.

## Contents

- [6.1 Test Procedures](./TEST_PROCEDURES.md)
- [6.2 Validation Checks](./VALIDATION_CHECKS.md)

## Overview

Testing occurs in two phases:

1. **Cloud-init Testing** - Verify cloud-init.yml works with multipass before embedding in autoinstall
2. **Autoinstall Testing** - Build ISO and test full installation in VirtualBox

This approach catches configuration errors early before building the full ISO.

## Prerequisites

- Multipass installed on Windows
- VirtualBox installed (for autoinstall testing)
- Python 3 with PyYAML (`pip install pyyaml`)
