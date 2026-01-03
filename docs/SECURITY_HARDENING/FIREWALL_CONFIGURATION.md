# 11.2 Firewall Configuration

> **Deprecated:** This content has been migrated to Chapter 6 cloud-init fragments and is applied automatically during deployment.

## Migrated Content

| Topic | Now In |
|-------|--------|
| UFW Base Policy | [6.5 UFW Fragment](../CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md) |
| SSH Rate Limiting | [6.5 UFW Fragment](../CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md) |
| Virtualization Forwarding | [6.10 Virtualization Fragment](../CLOUD_INIT_CONFIGURATION/VIRTUALIZATION_FRAGMENT.md) |

The base firewall configuration is now automated via cloud-init.

**Note:** Cockpit no longer requires a UFW rule - it binds to localhost only and is accessed via SSH tunnel. See [6.11 Cockpit Fragment](../CLOUD_INIT_CONFIGURATION/COCKPIT_FRAGMENT.md).

## Verification

After deployment, verify firewall is active:

```bash
sudo ufw status verbose
```

## Post-Deployment Additions

If you need to open additional ports after deployment:

```bash
# Allow specific port
sudo ufw allow 8080/tcp

# Allow from specific subnet
sudo ufw allow from 192.168.1.0/24 to any port 8080

# Delete rule
sudo ufw delete allow 8080/tcp
```

See [6.5 UFW Fragment](../CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md) for the complete base firewall policy.
