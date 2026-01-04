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
