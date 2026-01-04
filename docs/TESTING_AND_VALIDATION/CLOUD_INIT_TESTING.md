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
# Source VM configuration (see vm.config.ps1.example)
. .\vm.config.ps1

# Launch multipass VM with bridged networking for static IP testing
multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --network $VMNetwork --cloud-init output/cloud-init.yaml

# Wait for cloud-init to complete
multipass exec $VMName -- cloud-init status --wait
```

**Note:** The `--network` flag enables bridged networking. Use `multipass networks` to list available networks (e.g., `"Ethernet 1"`, `"Wi-Fi"`).

The launch command may show timeout warnings - this is normal. The `cloud-init status --wait` command is the true success indicator.

### Step 4: Validate Configuration

```powershell
# Check cloud-init status (should show "done")
multipass exec $VMName -- cloud-init status

# Check for errors in cloud-init log
multipass exec $VMName -- grep -iE "error|warning|failed" /var/log/cloud-init.log

# Verify user created
multipass exec $VMName -- id admin

# Verify packages installed
multipass exec $VMName -- dpkg -l | grep -E "qemu-kvm|libvirt|cockpit|fail2ban"

# Verify services enabled
multipass exec $VMName -- systemctl is-enabled cockpit.socket libvirtd fail2ban

# Verify firewall configured
multipass exec $VMName -- sudo ufw status

# Verify MOTD (should show dynamic content)
multipass exec $VMName -- cat /run/motd.dynamic
```

### Step 5: Validate Specific Fragments

Test components from each cloud-init fragment:

```powershell
# 6.2 Kernel Hardening - sysctl settings
multipass exec $VMName -- sysctl net.ipv4.ip_forward

# 6.4 SSH Hardening - sshd config
multipass exec $VMName -- sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"

# 6.5 UFW - firewall rules
multipass exec $VMName -- sudo ufw status numbered

# 6.6 System Settings - timezone/locale
multipass exec $VMName -- timedatectl
multipass exec $VMName -- localectl

# 6.9 Security Monitoring - fail2ban jails
multipass exec $VMName -- sudo fail2ban-client status

# 6.10 Virtualization - libvirt
multipass exec $VMName -- virsh list --all
multipass exec $VMName -- groups | grep -E "libvirt|kvm"

# 6.11 Cockpit - socket listening on localhost
multipass exec $VMName -- ss -tlnp | grep 443

# 6.12 OpenCode - AI coding agent (if enabled)
multipass exec $VMName -- which opencode 2>/dev/null && echo "OpenCode installed"

# 6.13 UI Touches - CLI tools installed
multipass exec $VMName -- which batcat fdfind htop neofetch
```

### Step 6: Cleanup Test VM

```powershell
multipass delete $VMName
multipass purge
```

If cloud-init test passes, proceed to [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md).

---

## Automated Test Scenarios

Run these comprehensive tests to validate each fragment category. These can be scripted for CI or rapid validation.

### Scenario 1: Network Configuration Test

Validates fragment 6.1 (Network). Requires `--network` bridged mode.

```powershell
# Verify netplan config was written
multipass exec $VMName -- cat /etc/netplan/*.yaml
# Should contain static IP, gateway, DNS from network.config.yaml

# Verify static IP is applied
multipass exec $VMName -- ip addr show
# Should show IP from network.config.yaml on bridged interface

# Verify gateway is reachable
multipass exec $VMName -- ip route | grep default
multipass exec $VMName -- ping -c 1 $(grep gateway network.config.yaml | awk '{print $2}')

# Verify DNS configuration
multipass exec $VMName -- resolvectl status | head -20
```

### Scenario 2: Security Hardening Test

Validates fragments 6.2 (Kernel), 6.4 (SSH), 6.5 (UFW), 6.8 (Package Security).

```powershell
# Kernel hardening (6.2)
multipass exec $VMName -- sysctl net.ipv4.ip_forward
# Expected: 1 (for VMs)
multipass exec $VMName -- sysctl net.ipv4.conf.all.rp_filter
# Expected: 1

# SSH hardening (6.4)
multipass exec $VMName -- sudo sshd -T | grep -E "permitrootlogin|passwordauthentication|maxauthtries"
# Expected: permitrootlogin no, passwordauthentication no, maxauthtries 3

# UFW (6.5)
multipass exec $VMName -- sudo ufw status verbose
# Expected: Status: active, Default: deny (incoming)

# Unattended upgrades (6.8)
multipass exec $VMName -- systemctl is-enabled unattended-upgrades
# Expected: enabled
```

### Scenario 3: Virtualization Test

Validates fragments 6.10 (Virtualization), 6.11 (Cockpit).

```powershell
# libvirt (6.10)
multipass exec $VMName -- virsh list --all
multipass exec $VMName -- virsh net-list --all
multipass exec $VMName -- sudo systemctl status libvirtd --no-pager

# User permissions
multipass exec $VMName -- groups | grep -E "libvirt|kvm"

# Cockpit (6.11) - must be localhost only
multipass exec $VMName -- ss -tlnp | grep 443
# Expected: 127.0.0.1:443 ONLY
```

### Scenario 4: Monitoring Test

Validates fragments 6.7 (MSMTP), 6.9 (Security Monitoring).

```powershell
# fail2ban (6.9)
multipass exec $VMName -- sudo fail2ban-client status
multipass exec $VMName -- sudo fail2ban-client status sshd
# Expected: sshd jail active

# Recidive jail
multipass exec $VMName -- sudo fail2ban-client status recidive

# msmtp (6.7) - if configured
multipass exec $VMName -- which msmtp
multipass exec $VMName -- cat /etc/msmtprc 2>/dev/null | grep host || echo "msmtp not configured"

# Send test email (requires valid SMTP config in smtp.config.yaml)
multipass exec $VMName -- bash -c "printf 'Subject: Cloud-init Test\n\nTest email from cloud-init VM' | msmtp recipient@example.com" || echo "msmtp not configured or send failed"
```

### Scenario 5: User Experience Test

Validates fragments 6.3 (Users), 6.12 (OpenCode), 6.13 (UI Touches).

```powershell
# User and groups (6.3)
multipass exec $VMName -- id admin
multipass exec $VMName -- groups admin

# Dynamic MOTD (6.13)
multipass exec $VMName -- cat /run/motd.dynamic
# Should show: hostname, uptime, load, memory, disk, SSH config snippet

# Shell aliases
multipass exec $VMName -- bash -ic "type cat"
# Should alias to batcat

# CLI tools
multipass exec $VMName -- batcat --version
multipass exec $VMName -- fdfind --version
multipass exec $VMName -- htop --version
multipass exec $VMName -- jq --version

# OpenCode (6.12) - if enabled
multipass exec $VMName -- which opencode 2>/dev/null && opencode --version

# OpenCode config file exists
multipass exec $VMName -- cat ~/.config/opencode/opencode.json 2>/dev/null

# OpenCode configured providers/credentials
multipass exec $VMName -- opencode auth list 2>/dev/null

# OpenCode available models (requires valid credentials)
multipass exec $VMName -- bash -c "echo '/models' | opencode --no-tui 2>/dev/null | head -20" || echo "Models require valid API key"
```

---

## Full Validation Script

Automate all scenarios with a single script:

```powershell
# Validate-CloudInit.ps1
param([switch]$Verbose)

# Load VM configuration
if (-not (Test-Path ".\vm.config.ps1")) {
    Write-Error "Missing vm.config.ps1 - copy from vm.config.ps1.example"
    exit 1
}
. .\vm.config.ps1

function Test-Command {
    param([string]$Name, [string]$Command, [string]$Expected)
    $result = multipass exec $VMName -- bash -c $Command 2>&1
    $pass = if ($Expected) { $result -match $Expected } else { $LASTEXITCODE -eq 0 }
    $status = if ($pass) { "[PASS]" } else { "[FAIL]" }
    $color = if ($pass) { "Green" } else { "Red" }
    Write-Host "$status $Name" -ForegroundColor $color
    if ($Verbose -or -not $pass) { Write-Host "       $result" -ForegroundColor Gray }
    return $pass
}

Write-Host "`n=== Network Configuration ===" -ForegroundColor Cyan
Test-Command "Netplan: Config exists" "ls /etc/netplan/*.yaml" ".yaml"
Test-Command "Netplan: Has addresses" "grep -q addresses /etc/netplan/*.yaml" ""
Test-Command "Network: IP assigned" "ip addr show | grep 'inet '" "inet"
Test-Command "Network: Gateway reachable" "ping -c 1 -W 2 \$(ip route | grep default | awk '{print \$3}')" "1 received"

Write-Host "`n=== Security Hardening ===" -ForegroundColor Cyan
Test-Command "Kernel: IP forward" "sysctl -n net.ipv4.ip_forward" "1"
Test-Command "SSH: Root login disabled" "sudo sshd -T | grep permitrootlogin" "no"
Test-Command "SSH: Password auth disabled" "sudo sshd -T | grep passwordauthentication" "no"
Test-Command "UFW: Active" "sudo ufw status | head -1" "active"

Write-Host "`n=== Virtualization ===" -ForegroundColor Cyan
Test-Command "libvirt: Running" "systemctl is-active libvirtd" "active"
Test-Command "Cockpit: Localhost only" "ss -tlnp | grep 443 | grep 127.0.0.1" "127.0.0.1"
Test-Command "Groups: libvirt" "groups | grep libvirt" "libvirt"

Write-Host "`n=== Monitoring ===" -ForegroundColor Cyan
Test-Command "fail2ban: Running" "systemctl is-active fail2ban" "active"
Test-Command "fail2ban: SSH jail" "sudo fail2ban-client status sshd | grep 'Jail'" "sshd"

Write-Host "`n=== User Experience ===" -ForegroundColor Cyan
Test-Command "User: admin exists" "id admin" "admin"
Test-Command "MOTD: Dynamic" "test -f /run/motd.dynamic" ""
Test-Command "CLI: batcat" "which batcat" "batcat"
Test-Command "CLI: fdfind" "which fdfind" "fdfind"

Write-Host "`n=== OpenCode (if enabled) ===" -ForegroundColor Cyan
Test-Command "OpenCode: Installed" "which opencode" "opencode"
Test-Command "OpenCode: Config exists" "test -f ~/.config/opencode/opencode.json" ""
Test-Command "OpenCode: Auth configured" "opencode auth list 2>/dev/null | grep -q ." ""

Write-Host "`n=== Complete ===" -ForegroundColor Green
```

Run with:

```powershell
.\Validate-CloudInit.ps1 -Verbose
```

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
multipass exec $VMName -- cat /var/log/cloud-init-output.log

# Cloud-init config used
multipass exec $VMName -- sudo cat /var/lib/cloud/instance/cloud-config.txt

# Per-module status
multipass exec $VMName -- cat /run/cloud-init/result.json
```

### Network Testing with Bridged Mode

Using `--network` bridged mode, multipass can fully test network configuration:
- Static IP assignment
- Gateway reachability
- DNS resolution
- Netplan configuration

```powershell
# List available networks
multipass networks

# Configure in vm.config.ps1 (copy from vm.config.ps1.example)
$VMNetwork = "Ethernet 1"

# Launch with bridged networking
multipass launch --name $VMName --network $VMNetwork --cloud-init output/cloud-init.yaml
```

**Note:** The interface naming may differ between multipass (e.g., `enp0s2`) and bare metal (e.g., `enp3s0`). The early-commands network detection script handles this automatically.

---

## Quick Test Script

For rapid iteration, use this PowerShell script:

```powershell
# Quick cloud-init test cycle
param([switch]$Rebuild)

# Load VM configuration
if (-not (Test-Path ".\vm.config.ps1")) {
    Write-Error "Missing vm.config.ps1 - copy from vm.config.ps1.example"
    exit 1
}
. .\vm.config.ps1

if ($Rebuild) {
    make cloud-init
}

# Cleanup previous test
multipass delete $VMName 2>$null
multipass purge 2>$null

# Launch with bridged networking
multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --network $VMNetwork --cloud-init output/cloud-init.yaml
multipass exec $VMName -- cloud-init status --wait

# Quick validation
Write-Host "`n=== Validation ===" -ForegroundColor Cyan
multipass exec $VMName -- cloud-init status
multipass exec $VMName -- id admin
multipass exec $VMName -- ip addr show | Select-String "inet "
multipass exec $VMName -- systemctl is-enabled cockpit.socket libvirtd

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Run validation commands or: multipass shell $VMName"
```

Save as `Test-CloudInit.ps1` and run:

```powershell
# First time: copy and configure vm.config.ps1
cp vm.config.ps1.example vm.config.ps1
# Edit vm.config.ps1 with your network (use: multipass networks)

# Run test
.\Test-CloudInit.ps1 -Rebuild
```
