# 3.3 Network Configuration in Cloud-init

Network configuration is handled via cloud-init using Netplan (Ubuntu's network configuration tool).

## Basic Static IP Configuration

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 10.0.1.100/24
      gateway4: 10.0.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - example.local
```

## DHCP Configuration

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: true
```

## Bonded NIC Configuration

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
    ens19:
      dhcp4: false
  bonds:
    bond0:
      interfaces:
        - ens18
        - ens19
      addresses:
        - 10.0.1.100/24
      gateway4: 10.0.1.1
      parameters:
        mode: 802.3ad
        lacp-rate: fast
        mii-monitor-interval: 100
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

## VLAN Configuration

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
  vlans:
    vlan100:
      id: 100
      link: ens18
      addresses:
        - 10.0.100.10/24
      gateway4: 10.0.100.1
```

## Bridge Configuration (for VMs)

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
  bridges:
    br0:
      interfaces:
        - ens18
      addresses:
        - 10.0.1.100/24
      gateway4: 10.0.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      parameters:
        stp: false
        forward-delay: 0
```

## Notes

- Interface names (e.g., `ens18`) vary by hardware; check with `ip link show`
- Use `netplan try` to test configurations with automatic rollback
- Cloud-init applies network config before other modules
