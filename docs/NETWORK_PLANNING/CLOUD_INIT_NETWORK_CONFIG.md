# 3.3 Network Configuration in Cloud-init

Network configuration is handled via cloud-init using Netplan. This configuration uses a hardware-adaptive approach that auto-detects the correct NIC based on known network identifiers.

## Strategy: Gateway + DNS Detection

Since the gateway and primary DNS server are known, we can:
1. Boot with DHCP for initial connectivity
2. Detect which interface has a route to the known gateway
3. Validate we're on the correct network by checking DNS reachability
4. Apply static configuration to the detected interface

This eliminates the need to know MAC addresses or interface names ahead of time.

## Initial Network Config (DHCP Discovery)

```yaml
network:
  version: 2
  ethernets:
    discovery:
      match:
        name: "e*"  # Matches eth*, ens*, enp*, etc.
      dhcp4: true
```

## Network Detection and Static Configuration Script

Cloud-init `bootcmd` format:

```yaml
bootcmd:
  - |
    GATEWAY="10.0.0.1"
    DNS_PRIMARY="10.0.0.11"
    STATIC_IP="10.0.0.25/24"

    # Skip if already configured (idempotent)
    [ -f /etc/netplan/90-static.yaml ] && exit 0

    # Find interface with route to known gateway
    NIC=$(ip route | grep "default via $GATEWAY" | awk '{print $5}')

    if [ -z "$NIC" ]; then
      logger "cloud-init: No interface found with gateway $GATEWAY"
      exit 1
    fi

    # Validate primary DNS is reachable (confirms correct network)
    if ! ping -c 2 -W 3 "$DNS_PRIMARY" >/dev/null 2>&1; then
      logger "cloud-init: Cannot reach DNS $DNS_PRIMARY - wrong network?"
      exit 1
    fi

    # Verify DNS responds to queries
    if ! host -W 3 google.com "$DNS_PRIMARY" >/dev/null 2>&1; then
      logger "cloud-init: DNS server not responding to queries"
      exit 1
    fi

    logger "cloud-init: Network validated - NIC=$NIC GW=$GATEWAY DNS=$DNS_PRIMARY"

    # Apply static config to detected interface
    cat > /etc/netplan/90-static.yaml << EOF
    network:
      version: 2
      ethernets:
        $NIC:
          dhcp4: false
          addresses:
            - $STATIC_IP
          routes:
            - to: default
              via: $GATEWAY
          nameservers:
            addresses: [10.0.0.11, 1.1.1.1, 8.8.8.8]
            search: [hostpi.io]
    EOF

    netplan apply
    logger "cloud-init: Static network configuration applied to $NIC"
```

## Known Network Identifiers

| Identifier | Value |
|------------|-------|
| Gateway | `10.0.0.1` |
| Primary DNS | `10.0.0.11` |
| Static IP | `10.0.0.25/24` |
| DNS Search | `hostpi.io` |

## Cloud-init Timing

Cloud-init stages (simplified):
1. **Local** - Writes network config, runs `bootcmd`
2. **Network** - Network is up, package installation, etc.
3. **Final** - Runs `runcmd`, cleanup

The detection script runs in `bootcmd` because:
- DHCP discovery config is applied before `bootcmd` executes
- Static config must be in place before package installation
- `bootcmd` runs every boot (idempotent script is fine)

## Benefits

- **Hardware-agnostic**: No MAC address or interface name required
- **Self-validating**: Confirms correct network before applying static config
- **Self-documenting**: Failures logged with clear context
- **No intervention**: Fully automated, no user input required
