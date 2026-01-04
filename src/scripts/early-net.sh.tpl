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
