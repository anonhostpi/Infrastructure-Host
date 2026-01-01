# 10.2 Firewall Configuration

## UFW Configuration via Cloud-init

```yaml
runcmd:
  # Configure UFW
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow ssh
  - ufw allow 9090/tcp    # Cockpit
  - ufw --force enable
```

## Common UFW Commands

```bash
# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose

# Allow specific ports
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 9090/tcp    # Cockpit

# Allow from specific subnet
sudo ufw allow from <SUBNET>/<CIDR>

# Deny specific port
sudo ufw deny 23/tcp

# Delete rule
sudo ufw delete allow 80/tcp

# Reset to defaults
sudo ufw reset
```

## Recommended Firewall Rules

| Port | Service | Action |
|------|---------|--------|
| 22/tcp | SSH | Allow |
| 9090/tcp | Cockpit | Allow |
| 80/tcp | HTTP | Allow if needed |
| 443/tcp | HTTPS | Allow if needed |
| 16509/tcp | Libvirt | Allow from trusted IPs |

## Firewall for Virtualization

If running VMs with bridged networking:

```bash
# Allow forwarding
sudo ufw route allow in on br0

# Or edit /etc/default/ufw
DEFAULT_FORWARD_POLICY="ACCEPT"
```
