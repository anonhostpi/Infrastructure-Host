# 4.1 Network Information Gathering

Before deployment, collect the following information for the server.

## Host Network Configuration

See `network.config.yaml` (not tracked in git) for actual values.

| Field | Placeholder |
|-------|-------------|
| Hostname | `<HOSTNAME>` |
| Primary IP Address | `<HOST_IP>/<CIDR>` |
| Gateway | `<GATEWAY>` |
| DNS Servers | `<DNS_PRIMARY>`, `<DNS_SECONDARY>`, `<DNS_TERTIARY>` |
| DNS Search Domain | `<DNS_SEARCH>` |
| VLAN ID | N/A |

## Network Configuration Template

```yaml
# Host Network Configuration
# Copy to network.config.yaml and fill in values
host:
  hostname: <HOSTNAME>
  ip_address: <HOST_IP>/<CIDR>
  gateway: <GATEWAY>
  dns_servers:
    - <DNS_PRIMARY>    # Primary (local)
    - <DNS_SECONDARY>  # Secondary
    - <DNS_TERTIARY>   # Tertiary
  dns_search: <DNS_SEARCH>
```

## Information Sources

- **IP Addresses**: Network administrator or IPAM system
- **Gateway/DNS**: Network documentation or `ip route` / `cat /etc/resolv.conf` on existing systems
- **MAC Addresses**: BIOS/UEFI, server labels, or `ip link show` on existing systems
- **VLAN IDs**: Network team or switch configuration
