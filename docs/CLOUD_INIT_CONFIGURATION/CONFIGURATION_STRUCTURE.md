# 5.1 Cloud-init Configuration Structure

Cloud-init configuration is stored in `cloud-init.yml` and embedded into autoinstall at build time. See [4.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) for the build process.

**Configuration Files:** Replace placeholders with values from:
- [network.config.yaml](../../network.config.yaml) - Hostname, IPs, gateway, DNS
- [identity.config.yaml](../../identity.config.yaml) - Username, password, SSH keys

## Cloud-init Template (cloud-init.yml)

```yaml
# Hostname - from network.config.yaml
hostname: <HOSTNAME>
fqdn: <HOSTNAME>.<DNS_SEARCH>
manage_etc_hosts: true

# Users - from identity.config.yaml
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
  - ufw allow 9090/tcp
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
final_message: "Cloud-init complete! Cockpit at https://<HOST_IP>:9090"
```

## build-cloud-init.py

Builds cloud-init configuration with bootcmd composed from network config:

```python
#!/usr/bin/env python3
"""Build cloud-init configuration from template and network config."""

import yaml
from build_network import load_network_config, generate_net_env

def build_cloud_init(template_path='cloud-init.yml'):
    """Build cloud-init config with composed bootcmd."""
    # Generate network environment
    net_config = load_network_config()
    net_setup_env = generate_net_env(net_config)

    # Read network setup script
    with open('net-setup.sh') as f:
        net_setup_sh = f.read()

    # Compose bootcmd script (env + shell)
    bootcmd_script = net_setup_env + '\n' + net_setup_sh

    # Load template
    with open(template_path) as f:
        cloud_init = yaml.safe_load(f)

    # Create bootcmd array
    cloud_init['bootcmd'] = [bootcmd_script]

    return cloud_init

if __name__ == '__main__':
    cloud_init = build_cloud_init()
    with open('cloud-init-built.yaml', 'w') as f:
        f.write('#cloud-config\n')
        yaml.dump(cloud_init, f, default_flow_style=False)
    print('Generated cloud-init-built.yaml')
```

See [3.3 Network Configuration](../NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md) for script details.

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
| `bootcmd` | network.config.yaml + net-setup.sh | Network detection script (created by build-cloud-init.py) |
