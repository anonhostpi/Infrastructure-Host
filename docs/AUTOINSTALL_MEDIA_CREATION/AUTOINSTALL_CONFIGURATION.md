# 4.2 Autoinstall Configuration

Autoinstall uses a `user-data` file for installation automation. The cloud-init configuration is combined at build time from a separate file.

**Configuration Files:** Replace placeholders with values from:
- [network.config.yaml](../../network.config.yaml) - Hostname, IPs, gateway, DNS

## Directory Structure

```bash
mkdir -p autoinstall/nocloud
cd autoinstall/nocloud
```

## Create meta-data

Create an empty `meta-data` file (required but can be empty):

```bash
touch meta-data
```

## Autoinstall Template (autoinstall.yml)

```yaml
#cloud-config
autoinstall:
  version: 1

  # Locale and keyboard
  locale: en_US.UTF-8
  keyboard:
    layout: us

  # Network: disabled here - configured via early-commands using arping
  # See Chapter 3: NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md
  network:
    version: 2
    renderer: networkd

  # early-commands: created by build-autoinstall.py

  # Storage configuration
  storage:
    layout:
      name: zfs
      sizing-policy: all

  # SSH server
  ssh:
    install-server: true
    allow-pw: true

  # Late commands (runs at end of installation)
  late-commands:
    - curtin in-target --target=/target -- systemctl enable ssh

  # Reboot after installation
  shutdown: reboot

  # user-data field is populated at build time from cloud-init.yml
```

## Building the Final user-data

### build-autoinstall.py

The build script:
1. Imports `build_network` to generate `net_setup_env`
2. Composes `early-commands` from `net_setup_env` + `early-net.sh`
3. Imports `build_cloud_init` to get cloud-init with `bootcmd` already composed
4. Embeds cloud-init into autoinstall

```python
#!/usr/bin/env python3
"""Build autoinstall user-data from templates and network config."""

import yaml
from build_network import load_network_config, generate_net_env
from build_cloud_init import build_cloud_init

# Generate network environment from config
net_config = load_network_config()
net_setup_env = generate_net_env(net_config)

# Read early-net script
with open('early-net.sh') as f:
    early_net_sh = f.read()

# Compose early-commands script (env + shell)
early_net_script = net_setup_env + '\n' + early_net_sh

# Load autoinstall template
with open('autoinstall.yml') as f:
    autoinstall = yaml.safe_load(f)

# Create early-commands array
autoinstall['autoinstall']['early-commands'] = [early_net_script]

# Get cloud-init with bootcmd already composed
cloud_init = build_cloud_init()

# Embed cloud-init in autoinstall
autoinstall['autoinstall']['user-data'] = cloud_init

# Write final user-data
with open('user-data', 'w') as f:
    f.write('#cloud-config\n')
    yaml.dump(autoinstall, f, default_flow_style=False)

print('Generated user-data')
```

The build script also:
- Replaces other placeholders (`<HOSTNAME>`, `<USERNAME>`, etc.)
- Generates password hash: `openssl passwd -6 "$PASSWORD"`

See [3.3 Network Configuration](../NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md) for script details.

## YAML Formatting Notes

**Critical:** Avoid inline comments within list items. This causes YAML parsing errors:

```yaml
# WRONG - will cause "Malformed autoinstall" error
late-commands:
  - echo 'done'  # This comment breaks it

# CORRECT
late-commands:
  - echo 'done'
```

## Storage Layout Options

| Layout | Description |
|--------|-------------|
| `zfs` | ZFS root filesystem (recommended for virtualization hosts) |
| `lvm` | LVM with single volume group |
| `direct` | Direct partitioning without LVM |

## Build Artifacts

| Artifact | Source | Description |
|----------|--------|-------------|
| `early-commands` | network.config.yaml + early-net.sh | Early network setup (created by build-autoinstall.py) |
