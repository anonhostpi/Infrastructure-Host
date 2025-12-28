# 5.2 Cloud-init Configuration Structure

## Complete user-data Example

```yaml
#cloud-config

# Hostname
hostname: ubuntu-host-01
fqdn: ubuntu-host-01.example.local

# Manage /etc/hosts
manage_etc_hosts: true

# Users
users:
  - name: admin
    groups: [sudo, docker]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... user@workstation

# Disable root login
disable_root: true

# SSH configuration
ssh_pwauth: false
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... user@workstation

# Timezone
timezone: America/New_York

# Network configuration (static IP)
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - <HOST_IP>/<CIDR>
      routes:
        - to: default
          via: <GATEWAY>
      nameservers:
        addresses:
          - <DNS_PRIMARY>
          - <DNS_SECONDARY>
        search:
          - <DNS_SEARCH>

# Package management
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Packages to install
packages:
  # System utilities
  - vim
  - tmux
  - htop
  - curl
  - wget
  - git
  - net-tools
  - dnsutils

  # Virtualization (KVM/QEMU)
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - bridge-utils
  - virt-manager
  - virtinst

  # Cockpit web interface
  - cockpit
  - cockpit-machines
  - cockpit-podman
  - cockpit-networkmanager

  # Container runtime
  - docker.io
  - docker-compose

  # Monitoring
  - prometheus-node-exporter

# Systemd services to enable
runcmd:
  # Enable and start libvirtd
  - systemctl enable libvirtd
  - systemctl start libvirtd

  # Add admin user to libvirt group
  - usermod -aG libvirt admin
  - usermod -aG kvm admin

  # Enable and start Cockpit
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket

  # Configure firewall for Cockpit (port 9090)
  - ufw allow 9090/tcp
  - ufw --force enable

  # Enable and start Docker
  - systemctl enable docker
  - systemctl start docker

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

  # Docker daemon configuration
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        }
      }
    permissions: '0644'

  # Cockpit configuration
  - path: /etc/cockpit/cockpit.conf
    content: |
      [WebService]
      AllowUnencrypted = false
      UrlRoot = /cockpit
    permissions: '0644'

# Final message
final_message: "Cloud-init deployment complete! System is ready. Cockpit available at https://<host-ip>:9090"

# Power state
power_state:
  mode: reboot
  timeout: 30
  condition: true
```

## meta-data Example

```yaml
instance-id: ubuntu-host-01
local-hostname: ubuntu-host-01
```

## Optional network-config

Alternative to embedding network config in user-data:

```yaml
version: 2
ethernets:
  ens18:
    dhcp4: false
    addresses:
      - <HOST_IP>/<CIDR>
    routes:
      - to: default
        via: <GATEWAY>
    nameservers:
      addresses:
        - <DNS_PRIMARY>
        - <DNS_SECONDARY>
      search:
        - <DNS_SEARCH>
```
