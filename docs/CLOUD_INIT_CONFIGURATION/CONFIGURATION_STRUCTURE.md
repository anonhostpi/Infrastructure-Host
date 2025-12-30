# 5.1 Cloud-init Configuration Structure

**Configuration Files:** Replace placeholders with values from:
- [network.config.yaml](../../network.config.yaml) - Hostname, IPs, gateway, DNS
- [identity.config.yaml](../../identity.config.yaml) - Username, password, SSH keys

## Complete user-data Example

```yaml
#cloud-config

# Hostname - from network.config.yaml
hostname: <HOSTNAME>
fqdn: <HOSTNAME>.<DNS_SEARCH>

# Manage /etc/hosts
manage_etc_hosts: true

# Users - from identity.config.yaml
users:
  - name: <USERNAME>
    groups: [sudo, libvirt, kvm]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - <SSH_AUTHORIZED_KEY>

# Disable root login
disable_root: true

# SSH configuration
ssh_pwauth: true

# Timezone
timezone: America/Phoenix

# Network configuration
# NOTE: Do NOT configure network here - use secure ARP probing in bootcmd instead
# See Chapter 3: NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md for the arping approach
# This avoids DHCP broadcast risks and validates connectivity before committing

# Secure network detection via ARP probing (runs before network stage)
# Full script in Chapter 3: NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md
bootcmd:
  - |
    # Placeholder - see Chapter 3 for full arping-based network detection script
    # Key steps: probe for known gateway/DNS via arping, configure static IP, validate DNS
    logger "cloud-init: Network detection via ARP probing - see CLOUD_INIT_NETWORK_CONFIG.md"

# Package management
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Packages to install
packages:
  # Virtualization (KVM/QEMU)
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - virtinst

  # Cockpit web interface
  - cockpit
  - cockpit-machines

# Snap packages
snap:
  commands:
    - snap install multipass

# Systemd services to enable
runcmd:
  # Enable and start libvirtd
  - systemctl enable libvirtd
  - systemctl start libvirtd

  # Add user to libvirt group
  - usermod -aG libvirt <USERNAME>
  - usermod -aG kvm <USERNAME>

  # Enable and start Cockpit
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket

  # Configure firewall for Cockpit (port 9090)
  - ufw allow 9090/tcp
  - ufw --force enable

  # Configure libvirt default network
  - virsh net-autostart default
  - virsh net-start default || true

  # Set up br0 bridge for VMs (example - out of scope for this deployment)
  # - |
  #   cat > /etc/netplan/60-bridge.yaml << 'NETPLAN_EOF'
  #   network:
  #     version: 2
  #     bridges:
  #       br0:
  #         interfaces: []
  #         dhcp4: false
  #         addresses:
  #           - <BRIDGE_IP>/<CIDR>
  #   NETPLAN_EOF
  # - netplan apply || true

# Write files
write_files:
  # Custom MOTD
  - path: /etc/motd
    content: |
      ========================================
      Ubuntu Infrastructure Host
      Managed by cloud-init
      ========================================
    permissions: '0644'

  # Cockpit configuration
  - path: /etc/cockpit/cockpit.conf
    content: |
      [WebService]
      AllowUnencrypted = false
      UrlRoot = /cockpit
    permissions: '0644'

# Final message
final_message: "Cloud-init deployment complete! Cockpit available at https://<HOST_IP>:9090"

# Power state
power_state:
  mode: reboot
  timeout: 30
  condition: true
```

## meta-data Example

```yaml
instance-id: <HOSTNAME>
local-hostname: <HOSTNAME>
```

## Network Configuration Approach

**Recommended:** Use the secure ARP probing approach from Chapter 3 (`NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md`). This:
- Avoids DHCP broadcast (no rogue DHCP risk)
- Auto-detects correct NIC via known gateway/DNS probing
- Validates connectivity before committing configuration

**Not Recommended:** Static network-config file. While simpler, this:
- Requires knowing interface name in advance (varies by hardware)
- Opens attack surface if using DHCP fallback
- No validation before committing

## Placeholder Reference

| Placeholder | Source | Description |
|-------------|--------|-------------|
| `<HOSTNAME>` | network.config.yaml | System hostname |
| `<HOST_IP>` | network.config.yaml | Static IP address |
| `<DNS_SEARCH>` | network.config.yaml | DNS search domain |
| `<USERNAME>` | identity.config.yaml | Admin account username |
| `<SSH_AUTHORIZED_KEY>` | identity.config.yaml | SSH public key (optional) |
