# 4.1 Network Information Gathering

Before deployment, collect the following information for the server.

## Host Network Configuration

Network configuration is stored in `src/config/network.config.yaml` (not tracked in git).

| Field | Description |
|-------|-------------|
| Hostname | Server hostname |
| IP Address | Static IP with CIDR prefix (e.g., `192.168.1.100/24`) |
| Gateway | Default gateway IP |
| DNS Servers | List of DNS server IPs |
| DNS Search | DNS search domain |

## Configuration File

Create `src/config/network.config.yaml`:

```yaml
network:
  hostname: kvm-host
  ip_address: 192.168.1.100/24
  gateway: 192.168.1.1
  dns_servers:
    - 192.168.1.1
    - 8.8.8.8
    - 8.8.4.4
  dns_search: local.lan
```

**Note:** The `network:` top-level key matches the filename, so BuildContext auto-unwraps it. Templates access values as `{{ network.hostname }}`, `{{ network.gateway }}`, etc.

## Template Usage

Once configured, network values are available in all templates:

```jinja
{# In any .tpl file #}
hostname: {{ network.hostname }}
gateway: {{ network.gateway }}
static_ip: {{ network.ip_address | ip_only }}
cidr: {{ network.ip_address | cidr_only }}
```

See [3.1 BuildContext](../BUILD_SYSTEM/BUILD_CONTEXT.md) for configuration loading details.

## Information Sources

- **IP Addresses**: Network administrator or IPAM system
- **Gateway/DNS**: Network documentation or `ip route` / `cat /etc/resolv.conf` on existing systems
- **MAC Addresses**: BIOS/UEFI, server labels, or `ip link show` on existing systems

## Environment Variable Overrides

Network values can be overridden at build time via environment variables:

```bash
export AUTOINSTALL_NETWORK_HOSTNAME=prod-server
export AUTOINSTALL_NETWORK_GATEWAY=10.0.0.1
make cloud-init
```

See [3.1 BuildContext - Environment Variable Overrides](../BUILD_SYSTEM/BUILD_CONTEXT.md#environment-variable-overrides) for details.
