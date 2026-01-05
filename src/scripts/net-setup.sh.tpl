#!/bin/bash
# Auto-generated network detection script for cloud-init
# Runs on first boot via bootcmd

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

logger "cloud-init net-setup: Found $IFACES ethernet interface(s)"

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

  logger "cloud-init net-setup: Checking interface $NIC ($NIC_MAC)"

  # Bring interface up
  ip link set "$NIC" up 2>/dev/null

  # Wait for carrier (physical link) with timeout
  CARRIER_WAIT=0
  while [ $CARRIER_WAIT -lt 10 ]; do
    CARRIER=$(cat "/sys/class/net/$NIC/carrier" 2>/dev/null || echo 0)
    [ "$CARRIER" = "1" ] && break
    sleep 1
    CARRIER_WAIT=$((CARRIER_WAIT + 1))
  done

  if [ "$CARRIER" != "1" ]; then
    logger "cloud-init net-setup: $NIC has no carrier (cable/link down)"
    continue
  fi

  logger "cloud-init net-setup: $NIC carrier up, probing gateway"

  # ARP probe the gateway - retry a few times for slow links
  # Use busybox arping (arping isn't standalone in minimal Ubuntu)
  ARP_OK=0
  for attempt in 1 2 3; do
    if busybox arping -c 2 -w 3 -I "$NIC" "$GATEWAY" >/dev/null 2>&1; then
      ARP_OK=1
      break
    fi
    sleep 1
  done

  if [ "$ARP_OK" != "1" ]; then
    logger "cloud-init net-setup: $NIC cannot reach gateway $GATEWAY via ARP"
    continue
  fi

  logger "cloud-init net-setup: $NIC can reach gateway $GATEWAY"
  FOUND_INTERFACE="$NIC"
  break
done

if [ -z "$FOUND_INTERFACE" ]; then
  logger "cloud-init net-setup: WARNING - No interface can reach gateway $GATEWAY, falling back to DHCP"
  exit 0
fi

NIC="$FOUND_INTERFACE"
logger "cloud-init net-setup: Configuring $NIC with $STATIC_IP/$CIDR"

# Apply temporary IP configuration
ip addr add "$STATIC_IP/$CIDR" dev "$NIC" 2>/dev/null
ip route add default via "$GATEWAY" dev "$NIC" 2>/dev/null

# Verify connectivity by pinging the gateway
if ! ping -c 2 -W 3 "$GATEWAY" >/dev/null 2>&1; then
  logger "cloud-init net-setup: ERROR - Cannot ping gateway after IP config"
  ip route del default via "$GATEWAY" dev "$NIC" 2>/dev/null
  ip addr del "$STATIC_IP/$CIDR" dev "$NIC" 2>/dev/null
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
