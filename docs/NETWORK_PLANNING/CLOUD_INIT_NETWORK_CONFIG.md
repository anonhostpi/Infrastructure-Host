# 4.3 Network Configuration in Cloud-init

Network configuration is handled via a secure, hardware-adaptive approach that auto-detects the correct NIC using ARP probes for known network identifiers.

## Strategy: ARP Probe Detection

Instead of using DHCP discovery (which broadcasts and opens attack surface), we:
1. Iterate over unconfigured interfaces
2. Bring each interface up (link only, no IP)
3. Use `arping` to probe for known gateway IP
4. Use `arping` to probe for known DNS server IP
5. If both respond, configure static IP on that interface
6. Validate with actual DNS query
7. If validation fails, unconfigure and try next interface

This approach:
- **No DHCP broadcast** - No rogue DHCP server risk
- **Targeted probes** - Only looks for known, trusted IPs
- **Validates before committing** - DNS query confirms connectivity
- **Self-healing** - Tries all interfaces until one works

## Configuration Files

Network setup is split into two files for modularity:

### build-network.py

Generates network environment variables from [network.config.yaml](../../network.config.yaml):

```python
#!/usr/bin/env python3
"""Network configuration generator for cloud-init and autoinstall."""

import yaml

def load_network_config(path='network.config.yaml'):
    """Load network configuration from YAML file."""
    with open(path) as f:
        return yaml.safe_load(f)

def generate_net_env(net_config):
    """Generate shell environment variables from network config."""
    host = net_config['host']
    dns = host['dns_servers']

    return f'''GATEWAY="{host['gateway']}"
DNS_PRIMARY="{dns[0]}"
DNS_SECONDARY="{dns[1]}"
DNS_TERTIARY="{dns[2]}"
DNS_SEARCH="{host['dns_search']}"
STATIC_IP="{host['ip_address'].split('/')[0]}"
CIDR="{host['ip_address'].split('/')[1]}"
'''

if __name__ == '__main__':
    net = load_network_config()
    print(generate_net_env(net))
```

### early-net.sh

Temporary network setup for autoinstall (runs during installation):

```bash
# Find interface by ARP probing known hosts
for iface in /sys/class/net/e*; do
  NIC=$(basename "$iface")
  [ "$NIC" = "lo" ] && continue

  ip link set "$NIC" up
  sleep 2

  if ! arping -c 2 -w 3 -I "$NIC" "$GATEWAY" >/dev/null 2>&1; then
    ip link set "$NIC" down
    continue
  fi

  if ! arping -c 2 -w 3 -I "$NIC" "$DNS_PRIMARY" >/dev/null 2>&1; then
    ip link set "$NIC" down
    continue
  fi

  ip addr add "$STATIC_IP/$CIDR" dev "$NIC"
  ip route add default via "$GATEWAY" dev "$NIC"
  echo "nameserver $DNS_PRIMARY" > /etc/resolv.conf
  break
done
```

Used by autoinstall `early-commands`. See [4.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md).

### net-setup.sh

Permanent network setup for cloud-init (runs on first boot):

```bash
# Skip if already configured (idempotent)
[ -f /etc/netplan/90-static.yaml ] && exit 0

# Find interface by ARP probing known hosts
for iface in /sys/class/net/e*; do
  NIC=$(basename "$iface")
  [ "$NIC" = "lo" ] && continue

  # Bring link up (no IP)
  ip link set "$NIC" up
  sleep 2

  # Probe for gateway via ARP
  if ! arping -c 2 -w 3 -I "$NIC" "$GATEWAY" >/dev/null 2>&1; then
    ip link set "$NIC" down
    continue
  fi

  # Probe for DNS via ARP
  if ! arping -c 2 -w 3 -I "$NIC" "$DNS_PRIMARY" >/dev/null 2>&1; then
    ip link set "$NIC" down
    continue
  fi

  logger "cloud-init: Found network on $NIC (GW=$GATEWAY, DNS=$DNS_PRIMARY)"

  # Configure interface temporarily
  ip addr add "$STATIC_IP/$CIDR" dev "$NIC"
  ip route add default via "$GATEWAY" dev "$NIC"

  # Validate with DNS query
  if host -W 3 google.com "$DNS_PRIMARY" >/dev/null 2>&1; then
    logger "cloud-init: DNS validated, writing netplan config"

    cat > /etc/netplan/90-static.yaml << EOF
network:
  version: 2
  ethernets:
    $NIC:
      dhcp4: false
      addresses:
        - $STATIC_IP/$CIDR
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$DNS_PRIMARY, $DNS_SECONDARY, $DNS_TERTIARY]
        search: [$DNS_SEARCH]
EOF
    netplan apply
    logger "cloud-init: Static network configuration applied to $NIC"
    exit 0
  fi

  # DNS failed, unconfigure and try next
  logger "cloud-init: DNS validation failed on $NIC, trying next"
  ip route del default via "$GATEWAY" dev "$NIC" 2>/dev/null
  ip addr del "$STATIC_IP/$CIDR" dev "$NIC" 2>/dev/null
  ip link set "$NIC" down
done

logger "cloud-init: ERROR - No valid network interface found"
exit 1
```

## Build-time Composition

During the build process, `build-network.py` is imported by `build-autoinstall.py`:
1. Load network config and generate env variables
2. Read shell scripts (`early-net.sh`, `net-setup.sh`)
3. Compose scripts by prefixing env to shell code

See [4.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) for the complete build script.

See [5.1 Configuration Structure](../CLOUD_INIT_CONFIGURATION/CONFIGURATION_STRUCTURE.md) for the complete cloud-init configuration.

## Environment Variables

| Variable | Source (network.config.yaml) | Description |
|----------|------------------------------|-------------|
| `GATEWAY` | `host.gateway` | Default gateway IP |
| `DNS_PRIMARY` | `host.dns_servers[0]` | Primary DNS server |
| `DNS_SECONDARY` | `host.dns_servers[1]` | Secondary DNS server |
| `DNS_TERTIARY` | `host.dns_servers[2]` | Tertiary DNS server |
| `DNS_SEARCH` | `host.dns_search` | DNS search domain |
| `STATIC_IP` | `host.ip_address` (IP part) | Static IP address |
| `CIDR` | `host.ip_address` (prefix part) | Network prefix length |

## How ARP Probing Works

```
┌─────────────┐     ARP: Who has <GATEWAY>?      ┌─────────────┐
│   Host NIC  │ ─────────────────────────────────▶│   Gateway   │
│  (no IP yet)│ ◀─────────────────────────────────│             │
└─────────────┘     ARP: <GATEWAY> is at XX:XX   └─────────────┘
```

- `arping` sends ARP requests at Layer 2 (no IP needed on host)
- If target responds, we know that NIC is on the correct network segment
- Gateway + DNS response = high confidence we're on the right network

## Cloud-init Timing

Cloud-init stages:
1. **Local** - Writes network config, runs `bootcmd`
2. **Network** - Network is up, package installation
3. **Final** - Runs `runcmd`, cleanup

The detection script runs in `bootcmd` because:
- Runs before any network config is applied
- Static config is in place before package installation
- `bootcmd` runs every boot (idempotent guard handles this)

## Security Benefits

| Approach | Risk |
|----------|------|
| DHCP Discovery | Rogue DHCP server can redirect traffic |
| ARP Probe | Only responds to known, trusted IPs |

- No broadcast requests that attackers can respond to
- Interface only configured after validating known infrastructure
- DNS validation confirms end-to-end connectivity
