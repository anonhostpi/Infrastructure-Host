# 7.3 Monitoring Cloud-init Progress

## Check Cloud-init Status

```bash
# Wait for cloud-init to complete
cloud-init status --wait

# Check cloud-init status
cloud-init status

# View cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Check for errors
sudo grep -i error /var/log/cloud-init.log
```

## Cloud-init Stages

Cloud-init runs in four stages:

| Stage | Description | What Happens |
|-------|-------------|--------------|
| `init-local` | Identifies datasource | Finds NoCloud ISO or seed files |
| `init` | Network configuration | Applies network settings |
| `modules-config` | Configuration modules | Users, packages, SSH keys |
| `modules-final` | Final modules | Scripts, final message |

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

Watch cloud-init progress in real-time:

```bash
# Follow the output log
sudo tail -f /var/log/cloud-init-output.log

# Or watch the main log
sudo tail -f /var/log/cloud-init.log
```

## Completion Verification

```bash
# Verify cloud-init completed
cloud-init status

# Check for any errors
sudo grep -i error /var/log/cloud-init.log

# View summary
cloud-init analyze show
```
