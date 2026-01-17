# 7.2 Autoinstall Testing

Build and test the full autoinstall ISO with VirtualBox.

**Prerequisite:** Complete [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md) first.

## Overview

### 7.1 vs 7.2: What Each Tests

| Aspect | 7.1 (Cloud-init) | 7.2 (Autoinstall) |
|--------|------------------|-------------------|
| **Platform** | Multipass | VirtualBox |
| **What's tested** | Cloud-init fragments only | Full ISO installation cycle |
| **Storage** | Multipass default | ext4 root filesystem |
| **Network** | Multipass bridged | NAT + early-net.sh detection |
| **Build artifact** | `cloud-init.yaml` | `ubuntu-autoinstall.iso` |
| **Install time** | Instant | 10-15 minutes |
| **Can test storage layout** | No | Yes |
| **Can test early-commands** | No | Yes |
| **Can test GRUB/boot** | No | Yes |

### What 7.2 Validates (That 7.1 Cannot)

- **Root filesystem** - Partitioning, ext4 formatting, mount points
- **early-commands** - Network detection during installation
- **late-commands** - Post-install configuration
- **Boot configuration** - UEFI, GRUB menu, boot order
- **Storage layout** - Disk selection, partitioning
- **Full installation cycle** - From ISO boot to running system

---

## Phase 2: Autoinstall Testing

### Step 1: Launch Builder VM

The build system requires Linux tools (Python, Jinja2, xorriso). All build commands run inside a multipass VM.

```powershell
# Load VM configuration
. .\vm.config.ps1

# Launch builder VM (or start existing)
$existingBuilder = multipass list --format csv 2>$null | Select-String "^$BuilderVMName,"
if (-not $existingBuilder) {
    multipass launch --name $BuilderVMName --cpus $BuilderCpus --memory $BuilderMemory --disk $BuilderDisk
}
multipass start $BuilderVMName 2>$null

# Wait for cloud-init
multipass exec $BuilderVMName -- cloud-init status --wait
```

### Step 2: Transfer Repository to Builder VM

```powershell
# Mount repository (preferred - changes sync automatically)
multipass mount . ${BuilderVMName}:/home/ubuntu/infra-host

# Or transfer (one-time copy)
# multipass transfer . ${BuilderVMName}:/home/ubuntu/infra-host/
```

### Step 3: Install Dependencies and Build

```powershell
# Install build dependencies
multipass exec $BuilderVMName -- bash -c "
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3-pip python3-yaml python3-jinja2 make xorriso cloud-image-utils wget
    cd /home/ubuntu/infra-host && pip3 install --break-system-packages -q -e . 2>/dev/null
"

# Build all artifacts (user-data, cloud-init.yaml, scripts)
multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && make all"
```

This generates inside the builder VM:
- `output/user-data` - Autoinstall configuration with embedded cloud-init
- `output/cloud-init.yaml` - Standalone cloud-init (for 7.1 testing)
- `output/scripts/build-iso.sh` - ISO build script (rendered from template)
- `output/scripts/early-net.sh` - Network detection script

### Step 4: Validate user-data Structure

```powershell
# Validate YAML syntax and structure (inside builder VM)
multipass exec $BuilderVMName -- bash -c "
cd /home/ubuntu/infra-host
python3 -c \"
import yaml
with open('output/user-data') as f:
    data = yaml.safe_load(f)
ai = data.get('autoinstall', {})
print('autoinstall version:', ai.get('version'))
print('has early-commands:', 'early-commands' in ai)
print('has user-data:', 'user-data' in ai)
print('storage layout:', ai.get('storage', {}).get('layout', {}).get('name'))
ud = ai.get('user-data', {})
print('user-data has packages:', 'packages' in ud)
print('user-data has runcmd:', 'runcmd' in ud)
print('user-data has write_files:', 'write_files' in ud)
\"
"
```

### Step 5: Build ISO

```powershell
# Build autoinstall ISO (inside builder VM)
multipass exec $BuilderVMName -- bash -c "
    cd /home/ubuntu/infra-host
    chmod +x output/scripts/build-iso.sh
    ./output/scripts/build-iso.sh
"
```

This downloads the Ubuntu ISO (cached for subsequent builds) and creates `output/ubuntu-autoinstall.iso`.

### Step 6: Validate ISO

```powershell
# Verify nocloud directory exists
multipass exec $BuilderVMName -- xorriso -indev /home/ubuntu/infra-host/output/ubuntu-autoinstall.iso -ls /nocloud 2>/dev/null

# Verify GRUB has autoinstall entry
multipass exec $BuilderVMName -- bash -c "
    xorriso -indev /home/ubuntu/infra-host/output/ubuntu-autoinstall.iso -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null
    grep -A5 'Autoinstall' /tmp/grub.cfg
"
```

### Step 7: Transfer ISO to Host

```powershell
# Ensure output directory exists
New-Item -ItemType Directory -Path ./output -Force | Out-Null

# Transfer ISO from builder VM
multipass transfer "${BuilderVMName}:/home/ubuntu/infra-host/output/ubuntu-autoinstall.iso" ./output/

# Verify
Get-Item ./output/ubuntu-autoinstall.iso | Select-Object Name, Length, LastWriteTime
```

### Step 8: Test with VirtualBox

```powershell
# Load VM configuration
. .\vm.config.ps1

$isoPath = (Resolve-Path './output/ubuntu-autoinstall.iso').Path
$vdiPath = (Join-Path (Get-Location) 'output/ubuntu-test.vdi')

# Cleanup existing VM if present
$existingVM = & $VBoxManage list vms 2>$null | Select-String $VBoxVMName
if ($existingVM) {
    & $VBoxManage controlvm $VBoxVMName poweroff 2>$null
    Start-Sleep 2
    & $VBoxManage unregistervm $VBoxVMName --delete 2>$null
}
if (Test-Path $vdiPath) { Remove-Item $vdiPath -Force }

# Create VM with UEFI (matches bare metal)
& $VBoxManage createvm --name $VBoxVMName --ostype Ubuntu_64 --register
& $VBoxManage modifyvm $VBoxVMName --memory $VBoxMemory --cpus $VBoxCpus --nic1 nat --firmware efi

# Add storage controller
& $VBoxManage storagectl $VBoxVMName --name 'SATA' --add sata --controller IntelAhci

# Create and attach disk (30GB+ for ZFS)
& $VBoxManage createmedium disk --filename $vdiPath --size $VBoxDiskSize --format VDI
& $VBoxManage storageattach $VBoxVMName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath

# Attach ISO
& $VBoxManage storageattach $VBoxVMName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $isoPath

# Start VM
& $VBoxManage startvm $VBoxVMName --type gui
```

### Step 9: Monitor Installation

Watch the VM window. The autoinstall process:

1. **GRUB menu** - "Autoinstall Ubuntu Server" selected (5 second timeout)
2. **Kernel boot** - Linux kernel loads
3. **early-commands** - Network detection script runs
4. **Installer starts** - Ubuntu installer runs unattended
5. **Storage setup** - ZFS pool created on largest disk
6. **Package installation** - Base system + configured packages
7. **late-commands** - Post-install configuration
8. **Reboot** - System restarts automatically
9. **Cloud-init** - First-boot configuration runs

Installation typically takes 10-15 minutes.

### Step 10: Validate Installation

After reboot, add SSH port forwarding and connect:

```powershell
# Add SSH port forwarding
& $VBoxManage controlvm $VBoxVMName natpf1 'ssh,tcp,,2222,,22'

# Wait for VM to be ready (cloud-init completion)
Start-Sleep 60

# Connect via SSH (use password from src/config/identity.config.yaml)
ssh -p 2222 -o StrictHostKeyChecking=no admin@localhost
```

### Step 11: Cleanup

```powershell
# Stop and remove VirtualBox VM
& $VBoxManage controlvm $VBoxVMName poweroff 2>$null
Start-Sleep 2
& $VBoxManage unregistervm $VBoxVMName --delete

# Remove VDI
Remove-Item ./output/ubuntu-test.vdi -Force -ErrorAction SilentlyContinue

# Optionally keep ISO for bare-metal deployment
# Remove-Item ./output/ubuntu-autoinstall.iso -Force

# Stop builder VM (preserves cached Ubuntu ISO)
multipass stop $BuilderVMName
```

---

## Autoinstall-Specific Tests

These tests validate components that **cannot be tested with multipass** (7.1).

### Root Filesystem

```bash
# Verify root filesystem type (ext4 with direct layout)
df -T /
# Expected: ext4 filesystem

# Verify root is mounted
mount | grep ' / '
# Expected: /dev/... on / type ext4 ...

# Verify boot partition
df /boot
# Expected: separate boot partition or part of root
```

### Installation Artifacts

```bash
# Verify autoinstall completed
ls -la /var/log/installer/

# View captured autoinstall config
cat /var/log/installer/autoinstall-user-data | head -30

# Verify cloud-init ran after install
cloud-init status
# Expected: status: done

# Check cloud-init output
cat /var/log/cloud-init-output.log | tail -50
```

### Boot Configuration

```bash
# Verify UEFI boot entry
efibootmgr -v
# Expected: ubuntu entry pointing to correct disk

# Verify no installer remnants
mount | grep cdrom
# Expected: no output (ISO ejected)

# Verify GRUB
cat /boot/grub/grub.cfg | grep -A3 "menuentry"
```

### early-commands Verification

```bash
# Check early network detection ran
cat /var/log/installer/curtin-install.log | grep -A20 "early-commands"

# Verify static IP was configured
cat /etc/netplan/90-static.yaml
```

---

## Cloud-init Tests (Reused from 7.1)

Most tests from [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md) work in 7.2 via SSH instead of multipass. These validate cloud-init fragments, not autoinstall-specific behavior.

**Validation commands** (run inside VM via SSH):

```bash
# Network (6.1)
hostname -f
ip addr show

# Kernel Hardening (6.2)
sysctl net.ipv4.conf.all.rp_filter

# Users (6.3)
id admin
groups admin

# SSH Hardening (6.4)
sudo grep PermitRootLogin /etc/ssh/sshd_config.d/*.conf

# UFW (6.5)
sudo ufw status verbose

# System Settings (6.6)
timedatectl

# MSMTP (6.7)
which msmtp
test -f /etc/msmtprc && echo "msmtp configured"

# Package Security (6.8)
systemctl status unattended-upgrades

# Security Monitoring (6.9)
sudo fail2ban-client status

# Virtualization (6.10)
systemctl status libvirtd
virsh list --all

# Cockpit (6.11)
ss -tlnp | grep 443

# AI CLIs (6.12-6.13)
which claude copilot 2>/dev/null

# UI Touches (6.15)
cat /run/motd.dynamic
which batcat fdfind htop
```

---

## Validation Checklist

After successful autoinstall, verify:

| Component | Check | Command |
|-----------|-------|---------|
| **Autoinstall-Specific** | | |
| Root FS | ext4 filesystem | `df -T /` |
| Mount | Root mounted | `mount \| grep ' / '` |
| Boot | UEFI entry exists | `efibootmgr -v` |
| Installer | Artifacts present | `ls /var/log/installer/` |
| **Cloud-init (from 7.1)** | | |
| Network | Connectivity | `ping -c1 8.8.8.8` |
| User | Admin user created | `id admin` |
| Groups | libvirt, kvm membership | `groups admin` |
| SSH | Service running | `systemctl status ssh` |
| Cockpit | Localhost only | `ss -tlnp \| grep 443` |
| libvirt | Daemon running | `virsh list --all` |
| fail2ban | Jails active | `sudo fail2ban-client status` |
| UFW | Firewall enabled | `sudo ufw status` |
| MOTD | Dynamic content | `cat /run/motd.dynamic` |
| CLI tools | bat, fd, htop | `which batcat fdfind htop` |

---

## Snapshot Testing

For iterative testing, use VirtualBox snapshots to quickly restore state:

```powershell
# After successful base install, create snapshot
& $VBoxManage snapshot $VBoxVMName take "base-install" --description "Clean autoinstall complete"

# Test configuration changes...

# Restore to clean state
& $VBoxManage snapshot $VBoxVMName restore "base-install"

# List snapshots
& $VBoxManage snapshot $VBoxVMName list
```

This allows testing multiple scenarios without full reinstall (~15 min saved per iteration).

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Malformed autoinstall config" | YAML syntax error | Check for inline comments in list items |
| "No autoinstall config found" | Missing datasource | Verify GRUB has `ds=nocloud\;s=/cdrom/nocloud/` |
| Installation drops to shell | early-commands failed | Check network config, arping availability |
| Boot loop after install | Wrong boot order | Eject ISO or change boot order in VM |
| Disk too small | Insufficient space for partitions | Use 25GB+ disk |
| cloud-init errors on first boot | Fragment merge issues | Test with 7.1 first |

## Debug Commands

```bash
# Inside installed VM

# Autoinstall log
cat /var/log/installer/autoinstall-user-data

# Curtin install log (early-commands, storage)
cat /var/log/installer/curtin-install.log

# Cloud-init logs
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log

# Service failures
systemctl --failed
journalctl -xe
```

---

## Troubleshooting Failures

When tests fail, collect diagnostics before cleanup:

```powershell
# Collect logs from VM before destroying
ssh -p 2222 admin@localhost "sudo tar czf /tmp/logs.tar.gz /var/log/cloud-init* /var/log/installer/ /var/log/syslog"
scp -P 2222 admin@localhost:/tmp/logs.tar.gz ./test-failure-logs.tar.gz

# Extract and review
tar xzf test-failure-logs.tar.gz
```

### Failure Categories

| Symptom | Likely Cause | Diagnostic |
|---------|--------------|------------|
| VM won't boot | ISO build issue | Check xorriso output, verify GRUB config |
| Drops to shell at GRUB | Missing autoinstall datasource | Verify `ds=nocloud;s=/cdrom/nocloud/` |
| Install starts but fails | YAML syntax error | Check `/var/log/installer/autoinstall-user-data` |
| Install completes, services fail | Fragment issue | Check `cloud-init status`, specific service logs |
| Network unreachable | early-commands failed | Check `/var/log/installer/curtin-install.log` |

---

## Automated Testing

The manual workflow above is automated via `Invoke-AutoinstallTest.ps1`:

```
tests/
├── Invoke-IncrementalTest.ps1        # 7.1 - multipass cloud-init testing
├── Invoke-AutoinstallTest.ps1        # 7.2 - VirtualBox autoinstall testing
├── lib/
│   ├── Config.ps1                    # Shared config loading
│   ├── Verifications.ps1             # Shared test functions (7.1)
│   └── VBoxHelpers.ps1               # VirtualBox CLI management
```

### Running Automated Tests

```powershell
# Full test: build ISO, install, run all tests
.\tests\Invoke-AutoinstallTest.ps1

# Use existing ISO (skip build)
.\tests\Invoke-AutoinstallTest.ps1 -SkipBuild

# Keep VMs running after tests (for debugging)
.\tests\Invoke-AutoinstallTest.ps1 -SkipCleanup

# Headless mode (no VirtualBox GUI window)
.\tests\Invoke-AutoinstallTest.ps1 -Headless
```

### What the Automated Tests Cover

**Autoinstall-Specific Tests (7.2.x):**
- 7.2.1: Root filesystem is ext4
- 7.2.2: Root mounted correctly
- 7.2.3: Boot partition exists
- 7.2.4: Installer logs present
- 7.2.5: Autoinstall user-data captured
- 7.2.6: UEFI boot entry exists
- 7.2.7: No cdrom mounted (ISO ejected)
- 7.2.8: Cloud-init status done

**Cloud-init Fragment Tests (6.x):**
- All tests from 7.1 re-run via SSH transport
- Network, users, SSH hardening, UFW, etc.

### Key Differences from 7.1 Automation

| Aspect | 7.1 (Invoke-IncrementalTest.ps1) | 7.2 (Invoke-AutoinstallTest.ps1) |
|--------|----------------------------------|----------------------------------|
| Platform | Multipass | VirtualBox |
| Transport | `multipass exec` | SSH (port 2222) |
| VM management | Multipass CLI | VBoxManage via VBoxHelpers.ps1 |
| Test functions | Verifications.ps1 | Inline (SSH-based) |
| Timeouts | ~5 minutes | ~20 minutes |
| Prerequisites | Multipass | VirtualBox + SSH client |

---

## Next Steps

After VirtualBox testing passes:

1. **Write ISO to USB** - Use Rufus, Ventoy, or `dd`
2. **Boot bare metal** - Select USB in BIOS boot menu
3. **Monitor installation** - Watch console or connect monitor
4. **Post-deployment** - Run `sudo msmtp-config` to configure email notifications

See [Chapter 8: Deployment Process](../DEPLOYMENT_PROCESS/OVERVIEW.md) for bare-metal deployment steps.
