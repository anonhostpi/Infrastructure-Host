# 7.1 Cloud-init Testing

Test cloud-init configuration with multipass before building the full autoinstall ISO.

## Pre-Build Checklist

Before starting, verify these files exist in `src/config/`:

- [ ] `network.config.yaml` - Valid IPs, gateway, DNS
- [ ] `identity.config.yaml` - Username, password, SSH keys
- [ ] `storage.config.yaml` - Disk selection settings
- [ ] `image.config.yaml` - Ubuntu release (noble, jammy)

## Phase 1: Cloud-init Testing

Test cloud-init configuration before embedding in autoinstall.

### Step 1: Build Cloud-init Configuration

```powershell
# From repository root
make cloud-init
```

This generates `output/cloud-init.yaml` by:
1. Rendering all fragment templates in `src/autoinstall/cloud-init/`
2. Merging them using `deep_merge` (see [3.3 Render CLI](../BUILD_SYSTEM/RENDER_CLI.md))

### Step 2: Validate YAML and Schema

```powershell
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('output/cloud-init.yaml'))"

# Validate against cloud-init schema (requires cloud-init installed)
cloud-init schema --config-file output/cloud-init.yaml
```

### Step 3: Launch Test VM

```powershell
# Launch multipass VM with cloud-init config
multipass launch --name cloud-init-test --cloud-init output/cloud-init.yaml

# Wait for cloud-init to complete
multipass exec cloud-init-test -- cloud-init status --wait
```

**Note:** The launch command may show timeout warnings - this is normal. The `cloud-init status --wait` command is the true success indicator.

### Step 4: Validate Configuration

```powershell
# Check cloud-init status (should show "done")
multipass exec cloud-init-test -- cloud-init status

# Check for errors in cloud-init log
multipass exec cloud-init-test -- grep -iE "error|warning|failed" /var/log/cloud-init.log

# Verify user created
multipass exec cloud-init-test -- id admin

# Verify packages installed
multipass exec cloud-init-test -- dpkg -l | grep -E "qemu-kvm|libvirt|cockpit|fail2ban"

# Verify services enabled
multipass exec cloud-init-test -- systemctl is-enabled cockpit.socket libvirtd fail2ban

# Verify firewall configured
multipass exec cloud-init-test -- sudo ufw status

# Verify MOTD (should show dynamic content)
multipass exec cloud-init-test -- cat /run/motd.dynamic
```

### Step 5: Validate Specific Fragments

Test components from each cloud-init fragment:

```powershell
# 6.2 Kernel Hardening - sysctl settings
multipass exec cloud-init-test -- sysctl net.ipv4.ip_forward

# 6.4 SSH Hardening - sshd config
multipass exec cloud-init-test -- sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"

# 6.5 UFW - firewall rules
multipass exec cloud-init-test -- sudo ufw status numbered

# 6.6 System Settings - timezone/locale
multipass exec cloud-init-test -- timedatectl
multipass exec cloud-init-test -- localectl

# 6.9 Security Monitoring - fail2ban jails
multipass exec cloud-init-test -- sudo fail2ban-client status

# 6.10 Virtualization - libvirt
multipass exec cloud-init-test -- virsh list --all
multipass exec cloud-init-test -- groups | grep -E "libvirt|kvm"

# 6.11 Cockpit - socket listening on localhost
multipass exec cloud-init-test -- ss -tlnp | grep 443

# 6.12 UI Touches - CLI tools installed
multipass exec cloud-init-test -- which batcat fdfind htop neofetch
```

### Step 6: Cleanup Test VM

```powershell
multipass delete cloud-init-test
multipass purge
```

If cloud-init test passes, proceed to [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md).

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Schema validation failed | Invalid cloud-init keys | Check [cloud-init docs](https://cloudinit.readthedocs.io/) |
| Package not found | Typo in package name | Verify package exists in Ubuntu repos |
| Service failed to start | Missing dependencies | Check `journalctl -u <service>` |
| Permission denied | Wrong file permissions | Check `write_files` permissions |

### Debug Commands

```powershell
# Full cloud-init output log
multipass exec cloud-init-test -- cat /var/log/cloud-init-output.log

# Cloud-init config used
multipass exec cloud-init-test -- sudo cat /var/lib/cloud/instance/cloud-config.txt

# Per-module status
multipass exec cloud-init-test -- cat /run/cloud-init/result.json
```

### Network Testing Limitations

Multipass VMs use NAT networking and cannot test:
- Static IP configuration (autoinstall early-commands)
- Gateway detection (arping)
- Network interface naming

These are tested in Phase 2 with VirtualBox or on actual hardware.

---

## Quick Test Script

For rapid iteration, use this PowerShell script:

```powershell
# Quick cloud-init test cycle
param([switch]$Rebuild)

if ($Rebuild) {
    make cloud-init
}

# Cleanup previous test
multipass delete cloud-init-test 2>$null
multipass purge 2>$null

# Launch and test
multipass launch --name cloud-init-test --cloud-init output/cloud-init.yaml
multipass exec cloud-init-test -- cloud-init status --wait

# Quick validation
Write-Host "`n=== Validation ===" -ForegroundColor Cyan
multipass exec cloud-init-test -- cloud-init status
multipass exec cloud-init-test -- id admin
multipass exec cloud-init-test -- systemctl is-enabled cockpit.socket libvirtd

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Run validation commands or: multipass shell cloud-init-test"
```

Save as `Test-CloudInit.ps1` and run:

```powershell
.\Test-CloudInit.ps1 -Rebuild
```
