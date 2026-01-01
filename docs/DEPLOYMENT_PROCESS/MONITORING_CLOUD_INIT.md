# 7.3 Monitoring Cloud-init Progress

Monitor cloud-init execution after the system reboots from autoinstall.

## Quick Status Check

```bash
# Wait for cloud-init to complete (blocks until done)
cloud-init status --wait

# Check current status
cloud-init status

# Check for errors
sudo grep -i error /var/log/cloud-init.log
```

## Cloud-init Stages

Cloud-init runs in four stages. In this deployment, cloud-init configuration is embedded in the autoinstall ISO and executed on first boot.

| Stage | Description | What Happens in This Deployment |
|-------|-------------|--------------------------------|
| `init-local` | Identifies datasource | Reads embedded user-data from autoinstall |
| `init` | Network configuration | Runs bootcmd (arping detection), applies netplan |
| `modules-config` | Configuration modules | Creates admin user, installs packages |
| `modules-final` | Final modules | Enables services, configures firewall |

### Bootcmd Stage (Network Detection)

The bootcmd stage runs arping to detect the correct network interface:

```bash
# Check if arping network detection succeeded
cat /etc/netplan/90-static.yaml

# If file exists with correct interface, network detection worked
# If missing, check cloud-init-output.log for arping errors
```

## Status Indicators

```bash
# Possible status values
cloud-init status
```

| Status | Meaning |
|--------|---------|
| `running` | Cloud-init is still executing |
| `done` | Cloud-init completed successfully |
| `error` | Cloud-init encountered an error |
| `disabled` | Cloud-init is disabled |

## Log Files

| Log File | Purpose |
|----------|---------|
| `/var/log/cloud-init.log` | Detailed cloud-init execution |
| `/var/log/cloud-init-output.log` | Output from scripts and commands |

## Real-time Monitoring

Watch cloud-init progress in real-time via console or SSH:

```bash
# Follow the output log (shows script output)
sudo tail -f /var/log/cloud-init-output.log

# Or watch the main log (shows detailed execution)
sudo tail -f /var/log/cloud-init.log
```

### What to Watch For

During cloud-init execution, monitor for:

| Event | What to Look For |
|-------|-----------------|
| Arping detection | "Interface detected: ethX" in output log |
| Package install | apt-get output for kvm, libvirt, cockpit |
| Service enable | systemctl enable/start for libvirtd, cockpit |
| Firewall config | ufw enable, port 9090 opened |

## Completion Verification

```bash
# Verify cloud-init completed
cloud-init status

# Check for any errors
sudo grep -i error /var/log/cloud-init.log

# View timing summary
cloud-init analyze show
```

## Common Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| Status shows "running" for >20 min | Package download slow | Wait, or check network connectivity |
| Status shows "error" | Script or package failure | Check `/var/log/cloud-init-output.log` for details |
| No 90-static.yaml | Arping detection failed | Check gateway/DNS respond to ARP, verify network config |
| Services not running | Package install failed | Check apt errors in cloud-init.log |

If cloud-init fails, see [Chapter 9: Troubleshooting](../TROUBLESHOOTING/OVERVIEW.md).
