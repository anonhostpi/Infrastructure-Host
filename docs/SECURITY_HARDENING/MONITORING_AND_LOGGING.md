# 10.3 Monitoring and Logging

## Recommended Additions

Consider adding to cloud-init:

- Centralized logging (rsyslog to remote server)
- Monitoring agents (Prometheus node exporter, Telegraf)
- AIDE (file integrity monitoring)

## Prometheus Node Exporter

Already included in the base cloud-init configuration:

```yaml
packages:
  - prometheus-node-exporter
```

Access metrics at: `http://<host-ip>:9100/metrics`

## Centralized Logging

Configure rsyslog to forward logs:

```bash
# /etc/rsyslog.d/50-remote.conf
*.* @logserver.example.com:514
```

## AIDE (File Integrity Monitoring)

```bash
# Install AIDE
sudo apt install aide

# Initialize database
sudo aideinit

# Check for changes
sudo aide --check
```

## Log Locations

| Log | Location |
|-----|----------|
| System | `/var/log/syslog` |
| Authentication | `/var/log/auth.log` |
| Cloud-init | `/var/log/cloud-init.log` |
| Firewall | `/var/log/ufw.log` |

## Monitoring Best Practices

1. **Centralize logs** - Send all logs to a central server
2. **Set up alerts** - Configure alerting for critical events
3. **Regular audits** - Review logs and security configuration periodically
4. **Backup monitoring** - Ensure monitoring survives server issues
