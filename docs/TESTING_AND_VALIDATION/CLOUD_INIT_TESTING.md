# 7.1 Cloud-init Testing

Test cloud-init configuration with multipass before building the full autoinstall ISO.

**Testing Platform:** All tests run on a multipass VM. VirtualBox is only used for autoinstall ISO testing (see [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md)).

---

## Individual Test Files

Detailed test specifications for each Chapter 6 fragment are in [CLOUD_INIT_TESTS/](./CLOUD_INIT_TESTS/):

| Test | Fragment | Description |
|------|----------|-------------|
| [TEST_6.1](./CLOUD_INIT_TESTS/TEST_6.1_NETWORK.md) | Network | Hostname, netplan, connectivity |
| [TEST_6.2](./CLOUD_INIT_TESTS/TEST_6.2_KERNEL_HARDENING.md) | Kernel Hardening | sysctl security parameters |
| [TEST_6.3](./CLOUD_INIT_TESTS/TEST_6.3_USERS.md) | Users | User creation, groups, sudo |
| [TEST_6.4](./CLOUD_INIT_TESTS/TEST_6.4_SSH_HARDENING.md) | SSH Hardening | sshd configuration |
| [TEST_6.5](./CLOUD_INIT_TESTS/TEST_6.5_UFW.md) | UFW | Firewall rules, rate limiting |
| [TEST_6.6](./CLOUD_INIT_TESTS/TEST_6.6_SYSTEM_SETTINGS.md) | System Settings | Locale, timezone |
| [TEST_6.7](./CLOUD_INIT_TESTS/TEST_6.7_MSMTP.md) | MSMTP | Mail configuration |
| [TEST_6.8](./CLOUD_INIT_TESTS/TEST_6.8_PACKAGE_SECURITY.md) | Package Security | Unattended upgrades |
| [TEST_6.9](./CLOUD_INIT_TESTS/TEST_6.9_SECURITY_MONITORING.md) | Security Monitoring | fail2ban jails |
| [TEST_6.10](./CLOUD_INIT_TESTS/TEST_6.10_VIRTUALIZATION.md) | Virtualization | KVM, libvirt, multipass |
| [TEST_6.11](./CLOUD_INIT_TESTS/TEST_6.11_COCKPIT.md) | Cockpit | Web console, localhost binding |
| [TEST_6.12](./CLOUD_INIT_TESTS/TEST_6.12_OPENCODE.md) | OpenCode | AI coding agent |
| [TEST_6.13](./CLOUD_INIT_TESTS/TEST_6.13_UI_TOUCHES.md) | UI Touches | CLI tools, MOTD, aliases |

---

## Pre-Build Checklist

Before starting, copy example files and configure in `src/config/`:

```powershell
# Copy examples and edit with your values
cp src/config/network.config.yaml.example src/config/network.config.yaml
cp src/config/identity.config.yaml.example src/config/identity.config.yaml
cp src/config/storage.config.yaml.example src/config/storage.config.yaml
cp src/config/image.config.yaml.example src/config/image.config.yaml
```

- [ ] `network.config.yaml` - Valid IPs, gateway, DNS
- [ ] `identity.config.yaml` - Username, password, SSH keys
- [ ] `storage.config.yaml` - Disk selection settings
- [ ] `image.config.yaml` - Ubuntu release (noble, jammy)

---

## Test Environment Setup

### Step 1: Build Cloud-init Configuration

```powershell
# From repository root
make cloud-init
```

This generates `output/cloud-init.yaml` by rendering and merging all fragment templates.

### Step 2: Launch Test VM

```powershell
# Source VM configuration (see vm.config.ps1.example)
. .\vm.config.ps1

# Launch multipass VM with bridged networking
multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --disk $VMDisk --network $VMNetwork --cloud-init output/cloud-init.yaml

# Wait for cloud-init to complete
multipass exec $VMName -- cloud-init status --wait
```

### Step 3: Verify Cloud-init Success

```powershell
# Check cloud-init status (should show "done")
multipass exec $VMName -- cloud-init status

# Check for errors
multipass exec $VMName -- grep -iE "error|failed" /var/log/cloud-init.log | grep -v "No error" || echo "No errors found"
```

---

## Quick Validation Checklist

Run these commands for a rapid pass/fail assessment:

```powershell
# From PowerShell, with VM running
$VMName = "cloud-init-test"

# Cloud-init status
multipass exec $VMName -- cloud-init status

# Core services
multipass exec $VMName -- systemctl is-active libvirtd fail2ban ssh

# Security
multipass exec $VMName -- sudo ufw status | Select-String "Status"
multipass exec $VMName -- sudo sshd -T | Select-String "permitrootlogin"

# Cockpit localhost-only (CRITICAL)
multipass exec $VMName -- ss -tlnp | Select-String "443"

# User setup
multipass exec $VMName -- id admin
multipass exec $VMName -- groups admin
```

### Cleanup

```powershell
multipass delete $VMName
multipass purge
```

---

## Troubleshooting

### Debug Commands

```powershell
# Full cloud-init log
multipass exec $VMName -- cat /var/log/cloud-init-output.log

# Cloud-init errors
multipass exec $VMName -- grep -iE "error|failed" /var/log/cloud-init.log

# Rendered cloud-init config
multipass exec $VMName -- sudo cat /var/lib/cloud/instance/cloud-config.txt

# Per-module results
multipass exec $VMName -- cat /run/cloud-init/result.json
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Package not found | Typo or unavailable | Verify package name in Ubuntu repos |
| Service failed | Missing dependency | Check `journalctl -u <service>` |
| Permission denied | Wrong file mode | Verify `write_files` permissions |
| Cockpit on 0.0.0.0 | Socket override missing | Check drop-in config exists |
| fail2ban jail inactive | Config syntax error | Check `/var/log/fail2ban.log` |
