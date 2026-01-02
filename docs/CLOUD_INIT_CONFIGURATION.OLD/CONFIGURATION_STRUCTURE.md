# 6.1 Cloud-init Configuration Structure

Cloud-init configuration is stored in `cloud-init.yml` and embedded into autoinstall at build time. See [6.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) for the build process.

**Configuration Files:** Replace placeholders with values from:
- [network.config.yaml](../../network.config.yaml) - Hostname, IPs, gateway, DNS
- [identity.config.yaml](../../identity.config.yaml) - Username, password, SSH keys
- `cloud-init/*.yaml` - Optional fragment files merged into final config

## Cloud-init Template (cloud-init.yml)

```yaml
# Hostname - from network.config.yaml
hostname: <HOSTNAME>
fqdn: <HOSTNAME>.<DNS_SEARCH>
manage_etc_hosts: true

# Users - built by build-cloud-init.py from identity.config.yaml
# (users array is replaced at build time, placeholder shown for reference)
users:
  - name: <USERNAME>
    groups: [sudo, libvirt, kvm]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false
    passwd: <PASSWORD_HASH>
    ssh_authorized_keys:
      - <SSH_AUTHORIZED_KEY>

# Disable root login
disable_root: true

# SSH configuration
ssh_pwauth: true

# Timezone
timezone: America/Phoenix

# bootcmd: created by build-cloud-init.py
# See Chapter 3: NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md

# Package management
package_update: true
package_upgrade: true

# Packages to install
packages:
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - virtinst
  - cockpit
  - cockpit-machines

# Snap packages
snap:
  commands:
    - snap install multipass

# Systemd services to enable
runcmd:
  - systemctl enable libvirtd
  - systemctl start libvirtd
  - usermod -aG libvirt <USERNAME>
  - usermod -aG kvm <USERNAME>
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket
  - ufw allow 443/tcp
  - ufw --force enable
  - virsh net-autostart default
  - virsh net-start default || true

# Write files
write_files:
  - path: /etc/motd
    content: |
      ========================================
      Ubuntu Infrastructure Host
      Managed by cloud-init
      ========================================
    permissions: '0644'

  - path: /etc/cockpit/cockpit.conf
    content: |
      [WebService]
      AllowUnencrypted = false
    permissions: '0644'

# Final message
final_message: "Cloud-init complete! Cockpit at https://<HOST_IP>"
```

## build-cloud-init.py

Builds cloud-init configuration by:
1. Composing bootcmd from network config
2. Setting users array from identity config
3. Merging fragment files from `cloud-init/` directory
4. Replacing username placeholders in runcmd

```python
#!/usr/bin/env python3
"""Build cloud-init configuration from template, network, identity, and fragments."""

import yaml
import crypt
import os
from pathlib import Path
from build_network import load_network_config, generate_net_env


def load_identity_config(path='identity.config.yaml'):
    """Load identity configuration."""
    with open(path) as f:
        return yaml.safe_load(f)['identity']


def generate_password_hash(password):
    """Generate SHA-512 password hash for cloud-init."""
    salt = crypt.mksalt(crypt.METHOD_SHA512)
    return crypt.crypt(password, salt)


def build_users(identity_config):
    """Build users array from identity config."""
    user = {
        'name': identity_config['username'],
        'groups': ['sudo', 'libvirt', 'kvm'],
        'shell': '/bin/bash',
        'sudo': ['ALL=(ALL) NOPASSWD:ALL'],
        'lock_passwd': False,
        'passwd': generate_password_hash(identity_config['password']),
    }

    # Add SSH keys if provided
    ssh_keys = identity_config.get('ssh_authorized_keys', [])
    if ssh_keys:
        user['ssh_authorized_keys'] = ssh_keys

    return [user]


def deep_merge(base, override):
    """
    Deep merge override into base.
    - Dicts are recursively merged
    - Lists are extended (override appended to base)
    - Scalars are replaced by override
    """
    if not isinstance(base, dict) or not isinstance(override, dict):
        return override

    result = base.copy()
    for key, value in override.items():
        if key in result:
            if isinstance(result[key], dict) and isinstance(value, dict):
                # Recursively merge dicts
                result[key] = deep_merge(result[key], value)
            elif isinstance(result[key], list) and isinstance(value, list):
                # Extend lists
                result[key] = result[key] + value
            else:
                # Replace scalar values
                result[key] = value
        else:
            result[key] = value

    return result


def merge_fragments(cloud_init, fragments_dir='cloud-init'):
    """
    Merge all .yaml files from fragments_dir into cloud_init.
    Files are processed in sorted order (use numeric prefixes for ordering).
    """
    fragments_path = Path(fragments_dir)
    if not fragments_path.exists():
        return cloud_init

    # Get all .yaml files, sorted alphabetically
    fragment_files = sorted(fragments_path.glob('*.yaml'))

    for fragment_file in fragment_files:
        print(f'  Merging fragment: {fragment_file.name}')
        with open(fragment_file) as f:
            fragment = yaml.safe_load(f)
            if fragment:  # Skip empty files
                cloud_init = deep_merge(cloud_init, fragment)

    return cloud_init


def build_cloud_init(template_path='cloud-init.yml'):
    """Build cloud-init config with network bootcmd, identity, and fragments."""
    # Load configurations
    net_config = load_network_config()
    identity_config = load_identity_config()

    # Generate network environment
    net_setup_env = generate_net_env(net_config)

    # Read network setup script
    with open('net-setup.sh') as f:
        net_setup_sh = f.read()

    # Compose bootcmd script (env + shell)
    bootcmd_script = net_setup_env + '\n' + net_setup_sh

    # Load template
    with open(template_path) as f:
        cloud_init = yaml.safe_load(f)

    # Set bootcmd
    cloud_init['bootcmd'] = [bootcmd_script]

    # Set users from identity config
    cloud_init['users'] = build_users(identity_config)

    # Merge fragment files from cloud-init/ directory
    cloud_init = merge_fragments(cloud_init)

    # Replace <USERNAME> in runcmd entries
    username = identity_config['username']
    if 'runcmd' in cloud_init:
        cloud_init['runcmd'] = [
            cmd.replace('<USERNAME>', username) if isinstance(cmd, str) else cmd
            for cmd in cloud_init['runcmd']
        ]

    return cloud_init


if __name__ == '__main__':
    print('Building cloud-init configuration...')
    cloud_init = build_cloud_init()
    with open('cloud-init-built.yaml', 'w') as f:
        f.write('#cloud-config\n')
        yaml.dump(cloud_init, f, default_flow_style=False)
    print('Generated cloud-init-built.yaml')
```

See [3.3 Network Configuration](../NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md) for network script details.

## Cloud-init Fragments

The `cloud-init/` directory contains optional fragment files that are deep-merged into the base configuration. This allows segmenting configuration by purpose.

### Fragment Ordering

Files are processed in alphabetical order. Use numeric prefixes to control merge order:

```
cloud-init/
├── 10-security.yaml      # Merged first
├── 20-monitoring.yaml    # Merged second
└── 30-custom.yaml        # Merged last
```

### Merge Behavior

| Type | Behavior |
|------|----------|
| Dicts | Recursively merged (keys combined) |
| Lists | Extended (fragment items appended) |
| Scalars | Replaced by fragment value |

### Example Fragment

`cloud-init/10-security.yaml`:
```yaml
# Security hardening packages and configuration
packages:
  - fail2ban
  - auditd
  - unattended-upgrades

write_files:
  - path: /etc/ssh/sshd_config.d/99-hardening.conf
    permissions: '0644'
    content: |
      PasswordAuthentication no
      MaxAuthTries 3
      X11Forwarding no

runcmd:
  - systemctl enable fail2ban
  - systemctl start fail2ban
```

This fragment adds packages to the base `packages` list, appends to `write_files`, and extends `runcmd`.

## Testing

Test cloud-init configuration with multipass before embedding in autoinstall. See [6.1 Test Procedures](../TESTING_AND_VALIDATION/TEST_PROCEDURES.md) for the complete testing workflow.

## Placeholder Reference

| Placeholder | Source | Description |
|-------------|--------|-------------|
| `<HOSTNAME>` | network.config.yaml | System hostname |
| `<HOST_IP>` | network.config.yaml | Static IP address |
| `<DNS_SEARCH>` | network.config.yaml | DNS search domain |
| `<USERNAME>` | identity.config.yaml | Admin account username |
| `<PASSWORD_HASH>` | identity.config.yaml | Password hash (generated at build) |
| `<SSH_AUTHORIZED_KEY>` | identity.config.yaml | SSH public key (optional) |

## Build Artifacts

| Artifact | Source | Description |
|----------|--------|-------------|
| `bootcmd` | network.config.yaml + net-setup.sh | Network detection script |
| `users` | identity.config.yaml | Admin user with hashed password and SSH keys |
| `packages`, `write_files`, `runcmd`, etc. | cloud-init.yml + cloud-init/*.yaml | Base config merged with fragments |
| `runcmd` | Template + fragments + identity.config.yaml | Commands with USERNAME replaced |
