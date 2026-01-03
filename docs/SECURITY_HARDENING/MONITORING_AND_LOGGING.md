# 11.3 Monitoring and Logging

Optional monitoring tools that can be added post-deployment. These are not part of the base automated deployment.

## Optional Monitoring Tools

| Tool | Purpose | Effort |
|------|---------|--------|
| Prometheus node exporter | System metrics | Low |
| AIDE | File integrity monitoring | Medium |
| rsyslog remote | Centralized logging | Medium |

---

## Prometheus Node Exporter

Exposes system metrics for Prometheus scraping.

### Installation

```bash
sudo apt install prometheus-node-exporter
sudo systemctl enable prometheus-node-exporter
```

### Verification

```bash
curl http://localhost:9100/metrics | head -20
```

### Firewall (if external scraping needed)

```bash
sudo ufw allow from 192.168.1.0/24 to any port 9100
```

**Note:** Only open port 9100 if you have a Prometheus server that needs to scrape this host.

---

## AIDE (File Integrity Monitoring)

Detects unauthorized file changes.

### Installation

```bash
sudo apt install aide
```

### Initialize Database

```bash
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

### Check for Changes

```bash
sudo aide --check
```

### Automate Daily Checks

```bash
# /etc/cron.daily/aide-check
#!/bin/bash
/usr/bin/aide --check | mail -s "[$(hostname)] AIDE Report" admin@example.com
```

---

## Centralized Logging

Forward logs to a remote syslog server.

### Configure rsyslog

```bash
# /etc/rsyslog.d/50-remote.conf
*.* @logserver.example.com:514       # UDP
# *.* @@logserver.example.com:514    # TCP
```

### Restart rsyslog

```bash
sudo systemctl restart rsyslog
```

---

## Log Locations Reference

| Log | Location | Purpose |
|-----|----------|---------|
| System | `/var/log/syslog` | General system messages |
| Authentication | `/var/log/auth.log` | SSH, sudo, PAM events |
| Cloud-init | `/var/log/cloud-init.log` | Cloud-init execution |
| Cloud-init output | `/var/log/cloud-init-output.log` | Command output |
| Firewall | `/var/log/ufw.log` | UFW blocked/allowed |
| fail2ban | `/var/log/fail2ban.log` | Ban/unban events |
| msmtp | `/var/log/msmtp.log` | Email sending |
| libvirt | `/var/log/libvirt/` | VM operations |

---

## Integration with Chapter 6

These optional tools complement the base monitoring in Chapter 6:

| Base (Chapter 6) | Optional (Chapter 11) |
|------------------|----------------------|
| fail2ban alerts | Prometheus metrics |
| msmtp notifications | Centralized logging |
| Log rotation | AIDE integrity checks |

See [6.9 Security Monitoring Fragment](../CLOUD_INIT_CONFIGURATION/SECURITY_MONITORING_FRAGMENT.md) for the base monitoring configuration.
