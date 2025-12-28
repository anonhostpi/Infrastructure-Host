# 3.3 Network Configuration in Cloud-init

**NOTE:** Refer to [network.config.yaml](../../network.config.yaml) for the exact values to be used in the script below.

Network configuration is handled via cloud-init using a secure, hardware-adaptive approach that auto-detects the correct NIC using ARP probes for known network identifiers.

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

## No Initial Network Config Required

Unlike DHCP discovery, this approach requires **no network configuration** in cloud-init's network section. The `bootcmd` script handles everything.

## Network Detection Script

Cloud-init `bootcmd` format (replace placeholders with values from `network.config.yaml`):

```yaml
bootcmd:
  - |
    GATEWAY="<GATEWAY>"
    DNS_PRIMARY="<DNS_PRIMARY>"
    STATIC_IP="<HOST_IP>"
    CIDR="<CIDR>"

    # Skip if already configured (idempotent)
    [ -f /etc/netplan/90-static.yaml ] && exit 0

    # Test mode: if hostname contains "test", preserve eth0 for multipass
    TESTMODE=false
    if hostname | grep -qi "test"; then
      TESTMODE=true
      logger "cloud-init: TEST MODE - preserving eth0 for multipass"
    fi

    # Find interface by ARP probing known hosts
    for iface in /sys/class/net/e*; do
      NIC=$(basename "$iface")
      [ "$NIC" = "lo" ] && continue

      # In test mode, skip eth0 (multipass transport)
      if $TESTMODE && [ "$NIC" = "eth0" ]; then
        logger "cloud-init: TEST MODE - skipping eth0"
        continue
      fi

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
            addresses: [<DNS_PRIMARY>, <DNS_SECONDARY>, <DNS_TERTIARY>]
            search: [<DNS_SEARCH>]
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

## Known Network Identifiers

| Identifier | Placeholder |
|------------|-------------|
| Gateway | `<GATEWAY>` |
| Primary DNS | `<DNS_PRIMARY>` |
| Static IP | `<HOST_IP>` |
| CIDR | `<CIDR>` |
| DNS Search | `<DNS_SEARCH>` |

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

Cloud-init stages (simplified):
1. **Local** - Writes network config, runs `bootcmd`
2. **Network** - Network is up, package installation, etc.
3. **Final** - Runs `runcmd`, cleanup

The detection script runs in `bootcmd` because:
- Runs before any network config is applied
- Static config is in place before package installation
- `bootcmd` runs every boot (idempotent guard handles this)

## Test Mode (Multipass)

When testing with multipass on Hyper-V, eth0 is the transport for `multipass shell` and `multipass exec`. The script detects test mode by checking if the hostname contains "test":

```bash
# Launch test VM with multipass
multipass launch --name test-cloud-init --cloud-init user-data.yaml
```

In test mode:
- eth0 is skipped during NIC probing
- Multipass transport remains functional
- Other interfaces are probed normally

## Security Benefits

| Approach | Risk |
|----------|------|
| DHCP Discovery | Rogue DHCP server can redirect traffic |
| ARP Probe | Only responds to known, trusted IPs |

- No broadcast requests that attackers can respond to
- Interface only configured after validating known infrastructure
- DNS validation confirms end-to-end connectivity
