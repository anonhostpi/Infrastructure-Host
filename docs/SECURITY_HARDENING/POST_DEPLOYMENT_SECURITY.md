# 11.1 Post-Deployment Security

> **Deprecated:** This content has been migrated to Chapter 6 cloud-init fragments and is applied automatically during deployment.

## Migrated Content

| Topic | Now In |
|-------|--------|
| SSH Hardening | [6.4 SSH Hardening Fragment](../CLOUD_INIT_CONFIGURATION/SSH_HARDENING_FRAGMENT.md) |
| Automatic Updates | [6.8 Package Security Fragment](../CLOUD_INIT_CONFIGURATION/PACKAGE_SECURITY_FRAGMENT.md) |
| fail2ban | [6.9 Security Monitoring Fragment](../CLOUD_INIT_CONFIGURATION/SECURITY_MONITORING_FRAGMENT.md) |
| Kernel Hardening | [6.2 Kernel Hardening Fragment](../CLOUD_INIT_CONFIGURATION/KERNEL_HARDENING_FRAGMENT.md) |

All security hardening in this section is now automated via cloud-init and does not require manual post-deployment action.

## Verification

After deployment, verify security settings are applied:

```bash
# SSH hardening
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"

# fail2ban
sudo fail2ban-client status

# Automatic updates
systemctl is-enabled unattended-upgrades
```

See [Chapter 7: Testing and Validation](../TESTING_AND_VALIDATION/OVERVIEW.md) for complete verification procedures.
