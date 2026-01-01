# 11.1 Reference Files

## Minimal Cloud-init for Testing

```yaml
#cloud-config
hostname: test-host
users:
  - name: testuser
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... user@host
```

## Minimal meta-data

```yaml
instance-id: test-host-01
local-hostname: test-host
```

## Minimal Autoinstall

```yaml
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  identity:
    hostname: ubuntu-server
    username: admin
    password: "$6$rounds=4096$salt$hash"
  ssh:
    install-server: true
  packages:
    - cloud-init
  shutdown: reboot
```

## Network Configuration

**Do NOT use DHCP** - it creates a broadcast attack surface.

Use the secure ARP probing approach from Chapter 3 (`NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md`):
- Probes for known gateway/DNS via arping (no broadcast)
- Auto-detects correct NIC
- Validates connectivity before committing

See `bootcmd` script in Chapter 3 for the full implementation.
