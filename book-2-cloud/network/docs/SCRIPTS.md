# 4.3 Network Scripts

Network configuration is handled via ARP probe detection scripts rendered from Jinja2 templates.

## Strategy: ARP Probe Detection

Instead of DHCP discovery (which broadcasts and opens attack surface), the scripts:

1. Wait for ethernet interfaces to appear (up to 30 seconds)
2. For each interface:
   - Bring interface up (link only, no IP)
   - Wait for carrier (physical link) with 10 second timeout
   - Use `busybox arping` to probe for known gateway IP (3 retries)
3. If gateway responds, configure static IP on that interface
4. Validate with ping to gateway
5. If validation fails, unconfigure and try next interface
6. Write netplan config with secure permissions (0600)

**Benefits:**
- No DHCP broadcast - No rogue DHCP server risk
- Targeted probes - Only looks for known, trusted IPs
- Validates before committing - DNS query confirms connectivity
- Self-healing - Tries all interfaces until one works

## Script Templates

Scripts are Jinja2 templates in `scripts/` that render network values from `config/network.config.yaml`.

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

  ip link set "$NIC" up 2>/dev/null

  # Wait for carrier (physical link)
  CARRIER_WAIT=0
  while [ $CARRIER_WAIT -lt 10 ]; do
    CARRIER=$(cat "/sys/class/net/$NIC/carrier" 2>/dev/null || echo 0)
    [ "$CARRIER" = "1" ] && break
    sleep 1
    CARRIER_WAIT=$((CARRIER_WAIT + 1))
  done
  [ "$CARRIER" != "1" ] && continue

  # ARP probe the gateway (busybox arping - standalone arping not available)
  if ! busybox arping -c 2 -w 3 -I "$NIC" "$GATEWAY" >/dev/null 2>&1; then
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

logger "cloud-init net-setup: Starting network detection (GW=$GATEWAY, IP=$STATIC_IP/$CIDR)"

# Detect multipass environment by looking for non-optional interfaces in netplan
# Non-optional interfaces are multipass's NAT interface - we must not touch them
PROTECTED_MAC=""
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
if [ -f "$NETPLAN_FILE" ]; then
  # Use Python + PyYAML (available in Ubuntu at bootcmd time) to properly parse netplan
  # Find interfaces where optional != true - these are required (multipass NAT)
  PROTECTED_MAC=$(python3 << 'PYTHON'
import yaml
try:
    with open('/etc/netplan/50-cloud-init.yaml') as f:
        data = yaml.safe_load(f)
    if 'network' in data and 'ethernets' in data['network']:
        for name, config in data['network']['ethernets'].items():
            if not config.get('optional', False):
                mac = config.get('match', {}).get('macaddress', '')
                if mac:
                    print(mac)
                    break
except:
    pass
PYTHON
)

  if [ -n "$PROTECTED_MAC" ]; then
    logger "cloud-init net-setup: Multipass detected - protecting interface with MAC $PROTECTED_MAC"
  fi
fi

# Wait for at least one ethernet interface to appear
WAIT_COUNT=0
while [ $WAIT_COUNT -lt 30 ]; do
  IFACES=$(ls -1 /sys/class/net/ 2>/dev/null | grep -E '^e' | wc -l)
  [ "$IFACES" -gt 0 ] && break
  sleep 1
  WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ "$IFACES" -eq 0 ]; then
  logger "cloud-init net-setup: WARNING - No ethernet interfaces found after 30s, falling back to DHCP"
  exit 0
fi

# Find interface by ARP probing the gateway
FOUND_INTERFACE=""
for iface in /sys/class/net/e*; do
  NIC=$(basename "$iface")
  NIC_MAC=$(cat "/sys/class/net/$NIC/address" 2>/dev/null | tr '[:upper:]' '[:lower:]')

  # Skip protected interface (multipass NAT)
  if [ -n "$PROTECTED_MAC" ]; then
    PROTECTED_MAC_LOWER=$(echo "$PROTECTED_MAC" | tr '[:upper:]' '[:lower:]')
    if [ "$NIC_MAC" = "$PROTECTED_MAC_LOWER" ]; then
      logger "cloud-init net-setup: Skipping $NIC (protected multipass interface)"
      continue
    fi
  fi

  ip link set "$NIC" up 2>/dev/null

  # Wait for carrier (physical link) with timeout
  CARRIER_WAIT=0
  while [ $CARRIER_WAIT -lt 10 ]; do
    CARRIER=$(cat "/sys/class/net/$NIC/carrier" 2>/dev/null || echo 0)
    [ "$CARRIER" = "1" ] && break
    sleep 1
    CARRIER_WAIT=$((CARRIER_WAIT + 1))
  done

  [ "$CARRIER" != "1" ] && continue

  # ARP probe the gateway (busybox arping - standalone arping not available)
  ARP_OK=0
  for attempt in 1 2 3; do
    if busybox arping -c 2 -w 3 -I "$NIC" "$GATEWAY" >/dev/null 2>&1; then
      ARP_OK=1
      break
    fi
    sleep 1
  done

  [ "$ARP_OK" != "1" ] && continue

  logger "cloud-init net-setup: $NIC can reach gateway $GATEWAY"
  FOUND_INTERFACE="$NIC"
  break
done

if [ -z "$FOUND_INTERFACE" ]; then
  logger "cloud-init net-setup: WARNING - No interface can reach gateway $GATEWAY, falling back to DHCP"
  exit 0
fi

NIC="$FOUND_INTERFACE"
ip addr add "$STATIC_IP/$CIDR" dev "$NIC" 2>/dev/null
ip route add default via "$GATEWAY" dev "$NIC" 2>/dev/null

# Verify connectivity by pinging the gateway
if ! ping -c 2 -W 3 "$GATEWAY" >/dev/null 2>&1; then
  logger "cloud-init net-setup: ERROR - Cannot ping gateway after IP config"
  exit 1
fi

logger "cloud-init net-setup: Gateway reachable, writing netplan config"

# Write permanent netplan configuration (with secure permissions)
umask 077
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

# Note: We do NOT call netplan apply here - it can disrupt other interfaces
# The config will take effect on next boot, or can be applied manually
logger "cloud-init net-setup: Static network configuration written to $NIC"
logger "cloud-init net-setup: Config will apply on next boot (run 'sudo netplan apply' to apply now)"
exit 0
```

**Key implementation details:**
- Detects multipass by parsing `/etc/netplan/50-cloud-init.yaml` for non-optional interfaces
- Skips protected interfaces (multipass NAT) to maintain test connectivity
- Uses `busybox arping` (standalone `arping` package not available at bootcmd time)
- Waits for carrier (physical link) before ARP probing
- Retries ARP 3 times for slow-starting links
- Uses `ping` for validation (`host` command not available at bootcmd time)
- Sets `umask 077` before writing netplan config (required by netplan)
- Does NOT call `netplan apply` - avoids disrupting other interfaces; cloud-init applies configs automatically

## Multipass Testing Behavior

When testing with multipass, the bridged interface will have two IP addresses:
- DHCP address from multipass's `50-cloud-init.yaml`
- Static address from our `90-static.yaml`

This is expected. In production (bare metal), only our `90-static.yaml` exists.

## Filters Used

| Filter | Purpose | Example |
|--------|---------|---------|
| `shell_quote` | Safe shell quoting | `{{ network.gateway \| shell_quote }}` → `'192.168.1.1'` |
| `ip_only` | Extract IP from CIDR | `{{ network.ip_address \| ip_only }}` → `192.168.1.100` |
| `cidr_only` | Extract prefix from CIDR | `{{ network.ip_address \| cidr_only }}` → `24` |

See [Jinja2 Filters](../../../book-0-builder/docs/JINJA2_FILTERS.md) for full filter documentation.

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

- `busybox arping` sends ARP requests at Layer 2 (no IP needed on host)
- If target responds, we know that NIC is on the correct network segment
- Gateway response = high confidence we're on the right network

**Why `busybox arping`?**

The standalone `arping` command requires the `arping` package, which isn't available at bootcmd time (packages haven't been installed yet). However, `busybox` is part of the base Ubuntu system and includes an `arping` implementation.

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
