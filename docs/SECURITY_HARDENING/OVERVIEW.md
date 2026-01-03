# Security Hardening

This section covers post-deployment security enhancements beyond the automated configuration.

## Migration Notice

Most security hardening is now automated via cloud-init fragments in [Chapter 6](../CLOUD_INIT_CONFIGURATION/OVERVIEW.md):

| Topic | Migrated To |
|-------|-------------|
| SSH Hardening | [6.4 SSH Hardening Fragment](../CLOUD_INIT_CONFIGURATION/SSH_HARDENING_FRAGMENT.md) |
| Firewall (UFW) | [6.5 UFW Fragment](../CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md) |
| Automatic Updates | [6.8 Package Security Fragment](../CLOUD_INIT_CONFIGURATION/PACKAGE_SECURITY_FRAGMENT.md) |
| fail2ban | [6.9 Security Monitoring Fragment](../CLOUD_INIT_CONFIGURATION/SECURITY_MONITORING_FRAGMENT.md) |
| Kernel Hardening | [6.2 Kernel Hardening Fragment](../CLOUD_INIT_CONFIGURATION/KERNEL_HARDENING_FRAGMENT.md) |

## Remaining Topics

This chapter covers **optional post-deployment enhancements** not included in automated deployment:

- [11.1 Post-Deployment Security](./POST_DEPLOYMENT_SECURITY.md) - Deprecated, see Chapter 6
- [11.2 Firewall Configuration](./FIREWALL_CONFIGURATION.md) - Deprecated, see Chapter 6
- [11.3 Monitoring and Logging](./MONITORING_AND_LOGGING.md) - Optional monitoring tools

## Optional Monitoring Additions

These tools are not part of the base deployment but may be added post-deployment:

| Tool | Purpose | Status |
|------|---------|--------|
| Prometheus node exporter | Metrics collection | Optional |
| AIDE | File integrity monitoring | Optional |
| rsyslog remote | Centralized logging | Optional |

See [11.3 Monitoring and Logging](./MONITORING_AND_LOGGING.md) for implementation details.
