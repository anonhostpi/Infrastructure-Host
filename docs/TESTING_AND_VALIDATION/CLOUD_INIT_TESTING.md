# 7.1 Cloud-init Testing

Test cloud-init configuration with multipass before building the full autoinstall ISO.

> **CRITICAL: NOTHING RUNS ON THE WINDOWS HOST**
>
> | Task | Where it runs |
> |------|---------------|
> | Build (`make cloud-init`) | **Builder VM** (multipass) |
> | Run tests | **Test VM** (multipass) |
>
> The Windows host only orchestrates VMs via PowerShell scripts that source `vm.config.ps1`.
> Never run Python, make, or test scripts directly on Windows.
>
> VirtualBox is only used for [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md) (ZFS root, ISO boot).

---

## VM Orchestration

**All VM orchestration uses `vm.config.ps1`** in the repository root.

```powershell
# Always source the config first
. .\vm.config.ps1

# Then use the variables
multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --disk $VMDisk --network $VMNetwork --cloud-init output/cloud-init.yaml
```

This ensures consistent VM settings across all test runs.

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

## Configuration Files

Configuration files in `src/config/` are created once from examples and **persist across test runs**. They contain values gathered during earlier chapters (network planning, identity setup, etc.).

| File | Created From | Contains |
|------|--------------|----------|
| `network.config.yaml` | Chapter 4 values | IP, gateway, DNS from network planning |
| `identity.config.yaml` | Chapter 5 values | Username, password, SSH keys |
| `storage.config.yaml` | Chapter 5 values | Disk selection settings |
| `image.config.yaml` | Chapter 5 values | Ubuntu release |
| `vm.config.ps1` | Repository root | VM orchestration settings |

**Do not delete or recreate these files** - they are your deployment configuration.

---

## Test Environment Setup

### Step 1: Launch Builder VM

```powershell
. .\vm.config.ps1

# Launch builder VM and mount repo
multipass launch --name $BuilderVMName --cpus $BuilderCpus --memory $BuilderMemory --disk $BuilderDisk
multipass mount . ${BuilderVMName}:/home/ubuntu/infra-host
```

### Step 2: Build Cloud-init Configuration (on Builder VM)

```powershell
# Install dependencies and build
multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && pip3 install -r requirements.txt && make cloud-init"
```

This generates `output/cloud-init.yaml` by rendering and merging all fragment templates.

### Step 3: Launch Test VM

```powershell
. .\vm.config.ps1

# Launch test VM with generated cloud-init
multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --disk $VMDisk --network $VMNetwork --cloud-init output/cloud-init.yaml

# Wait for cloud-init to complete
multipass exec $VMName -- cloud-init status --wait
```

### Step 4: Verify Cloud-init Success

```powershell
. .\vm.config.ps1

# Check cloud-init status (should show "done")
multipass exec $VMName -- cloud-init status

# Check for errors
multipass exec $VMName -- bash -c "grep -iE 'error|failed' /var/log/cloud-init.log | grep -v 'No error' || echo 'No errors found'"
```

---

## Quick Validation Checklist

```powershell
. .\vm.config.ps1

# Cloud-init status
multipass exec $VMName -- cloud-init status

# Core services
multipass exec $VMName -- systemctl is-active libvirtd fail2ban ssh

# Security
multipass exec $VMName -- sudo ufw status
multipass exec $VMName -- sudo sshd -T | Select-String "permitrootlogin"

# Cockpit localhost-only (CRITICAL)
multipass exec $VMName -- ss -tlnp | Select-String "443"

# User setup
multipass exec $VMName -- id admin
multipass exec $VMName -- groups admin
```

---

## Cleanup

```powershell
. .\vm.config.ps1

# Delete test VM
multipass delete $VMName
multipass purge

# Optionally delete builder VM
multipass delete $BuilderVMName
multipass purge
```

---

## Troubleshooting

### Debug Commands

```powershell
. .\vm.config.ps1

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
