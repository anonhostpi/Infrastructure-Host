# 4.3 Network Scripts

Network configuration is handled via ARP probe detection scripts rendered from Jinja2 templates.

## Strategy: ARP Probe Detection

Instead of DHCP discovery (which broadcasts and opens attack surface), the scripts:

1. Iterate over unconfigured interfaces
2. Bring each interface up (link only, no IP)
3. Use `arping` to probe for known gateway IP
4. Use `arping` to probe for known DNS server IP
5. If both respond, configure static IP on that interface
6. Validate with actual DNS query
7. If validation fails, unconfigure and try next interface

**Benefits:**
- No DHCP broadcast - No rogue DHCP server risk
- Targeted probes - Only looks for known, trusted IPs
- Validates before committing - DNS query confirms connectivity
- Self-healing - Tries all interfaces until one works

## Script Templates

Scripts are Jinja2 templates in `src/scripts/` that render network values from `src/config/network.config.yaml`.

### early-net.sh.tpl

Temporary network setup for autoinstall (runs during installation via `early-commands`):

```bash
#!/bin/bash
# Auto-generated network detection script for autoinstall

GATEWAY={{ network.gateway | shell_quote }}
DNS_PRIMARY={{ network.dns_servers[0] | shell_quote }}
STATIC_IP={{ network.ip_address | ip_only | shell_quote }}
CIDR={{ network.ip_address | cidr_only | shell_quote }}

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

### net-setup.sh.tpl

Permanent network setup for cloud-init (runs on first boot via `bootcmd`):

```bash
#!/bin/bash
# Auto-generated network detection script for cloud-init

# Skip if already configured (idempotent)
[ -f /etc/netplan/90-static.yaml ] && exit 0

GATEWAY={{ network.gateway | shell_quote }}
DNS_PRIMARY={{ network.dns_servers[0] | shell_quote }}
DNS_SECONDARY={{ network.dns_servers[1] | shell_quote }}
DNS_TERTIARY={{ network.dns_servers[2] | shell_quote }}
DNS_SEARCH={{ network.dns_search | shell_quote }}
STATIC_IP={{ network.ip_address | ip_only | shell_quote }}
CIDR={{ network.ip_address | cidr_only | shell_quote }}

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

  logger "cloud-init: Found network on $NIC (GW=$GATEWAY, DNS=$DNS_PRIMARY)"

  ip addr add "$STATIC_IP/$CIDR" dev "$NIC"
  ip route add default via "$GATEWAY" dev "$NIC"

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

  logger "cloud-init: DNS validation failed on $NIC, trying next"
  ip route del default via "$GATEWAY" dev "$NIC" 2>/dev/null
  ip addr del "$STATIC_IP/$CIDR" dev "$NIC" 2>/dev/null
  ip link set "$NIC" down
done

logger "cloud-init: ERROR - No valid network interface found"
exit 1
```

## Filters Used

| Filter | Purpose | Example |
|--------|---------|---------|
| `shell_quote` | Safe shell quoting | `{{ network.gateway \| shell_quote }}` → `'192.168.1.1'` |
| `ip_only` | Extract IP from CIDR | `{{ network.ip_address \| ip_only }}` → `192.168.1.100` |
| `cidr_only` | Extract prefix from CIDR | `{{ network.ip_address \| cidr_only }}` → `24` |

See [3.2 Jinja2 Filters](../BUILD_SYSTEM/JINJA2_FILTERS.md) for full filter documentation.

## Build Output

```bash
make scripts
```

Renders templates to:
- `output/scripts/early-net.sh`
- `output/scripts/net-setup.sh`

These scripts are also available to cloud-init and autoinstall templates via the `scripts` context:

```yaml
# In cloud-init or autoinstall templates
bootcmd:
  - |
{{ scripts["net-setup.sh"] | indent(4) }}
```

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
