# 3.1 Network Information Gathering

Before deployment, collect the following information for the server.

## Host Network Configuration

| Field | Value |
|-------|-------|
| Hostname | `lab` |
| Primary IP Address | `10.0.0.25/24` |
| Gateway | `10.0.0.1` |
| DNS Servers | `10.0.0.11`, `1.1.1.1`, `8.8.8.8` |
| DNS Search Domain | `hostpi.io` |
| VLAN ID | N/A |

## Network Configuration

```yaml
# Host Network Configuration
host:
  hostname: lab
  ip_address: 10.0.0.25/24
  gateway: 10.0.0.1
  dns_servers:
    - 10.0.0.11  # Primary (local)
    - 1.1.1.1       # Cloudflare
    - 8.8.8.8       # Google
  dns_search: hostpi.io
```

## Information Sources

- **IP Addresses**: Network administrator or IPAM system
- **Gateway/DNS**: Network documentation or `ip route` / `cat /etc/resolv.conf` on existing systems
- **MAC Addresses**: BIOS/UEFI, server labels, or `ip link show` on existing systems
- **VLAN IDs**: Network team or switch configuration
