#!/bin/bash
# Auto-generated network detection script for autoinstall
# Runs during installation via early-commands

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
