# 6.1 Network Fragment

**Template:** `fragment.yaml.tpl`

Sets hostname and FQDN, and runs the network detection script on boot.

## Template

```yaml
hostname: {{ network.hostname }}
fqdn: {{ network.hostname }}.{{ network.dns_search }}
manage_etc_hosts: true

bootcmd:
  # Wrap in subshell so exit doesn't terminate the combined bootcmd script
  - |
    (
    {{ scripts["net-setup.sh"] | indent(4) }}
    )
```

## Configuration Fields

| Field | Source | Description |
|-------|--------|-------------|
| `hostname` | `network.config.yaml` | Short hostname |
| `fqdn` | `network.config.yaml` | Fully qualified domain name |
| `manage_etc_hosts` | Static | Cloud-init manages `/etc/hosts` |

## bootcmd

The `bootcmd` array runs the network detection script from [Network Scripts](./SCRIPTS.md). This script:

1. Detects multipass environment and protects NAT interface (for testing)
2. Iterates over network interfaces
3. Uses ARP probing to find the interface that can reach the gateway
4. Writes static IP configuration to `/etc/netplan/90-static.yaml`
5. Validates connectivity with ping

The script is injected via the `scripts` context (see [Render CLI](../../../book-0-builder/docs/RENDER_CLI.md)).

> **Note:** The script does NOT call `netplan apply` - this avoids disrupting other interfaces during boot. Cloud-init automatically applies netplan configs, and the static IP takes effect on next boot or when manually applied.

## Cloud-init Timing

`bootcmd` runs during the **Local** stage:
- Runs every boot (script has idempotent guard)
- Runs before network is configured
- Runs before package installation

This ensures network is configured before any network-dependent operations.

## manage_etc_hosts

When `true`, cloud-init manages `/etc/hosts`:

```
127.0.1.1 kvm-host.local.lan kvm-host
127.0.0.1 localhost
```

This ensures hostname resolution works correctly for local services.
