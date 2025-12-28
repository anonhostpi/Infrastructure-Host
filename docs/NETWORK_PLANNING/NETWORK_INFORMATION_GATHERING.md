# 3.1 Network Information Gathering

Before deployment, collect the following information for each server.

## Per-Server Network Details

| Field | Example | Your Value |
|-------|---------|------------|
| Hostname | `host-XX` | |
| Primary IP Address | `10.0.1.X/24` | |
| Gateway | `10.0.1.1` | |
| DNS Servers | `8.8.8.8, 8.8.4.4` | |
| DNS Search Domain | `example.local` | |
| VLAN ID (if applicable) | `100` | |
| NIC MAC Address | `AA:BB:CC:DD:EE:FF` | |

## Network Planning Template

```yaml
# Network Planning Document
servers:
  - hostname: ubuntu-host-01
    ip_address: 10.0.1.101/24
    gateway: 10.0.1.1
    dns_servers:
      - 8.8.8.8
      - 8.8.4.4
    dns_search: example.local
    mac_address: AA:BB:CC:DD:EE:01
    vlan: null

  - hostname: ubuntu-host-02
    ip_address: 10.0.1.102/24
    gateway: 10.0.1.1
    dns_servers:
      - 8.8.8.8
      - 8.8.4.4
    dns_search: example.local
    mac_address: AA:BB:CC:DD:EE:02
    vlan: null
```

## Information Sources

- **IP Addresses**: Network administrator or IPAM system
- **Gateway/DNS**: Network documentation or `ip route` / `cat /etc/resolv.conf` on existing systems
- **MAC Addresses**: BIOS/UEFI, server labels, or `ip link show` on existing systems
- **VLAN IDs**: Network team or switch configuration
