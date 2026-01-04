# 7.2 Autoinstall Testing

Build and test the full autoinstall ISO with VirtualBox.

**Prerequisite:** Complete [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md) first.

## Phase 2: Autoinstall Testing

### Step 1: Build All Artifacts

```powershell
# From repository root - render all templates
make all
```

This generates:
- `output/user-data` - Autoinstall configuration with embedded cloud-init
- `output/cloud-init.yaml` - Standalone cloud-init (for testing)
- `output/scripts/build-iso.sh` - ISO build script
- `output/scripts/early-net.sh` - Network detection script

### Step 2: Validate user-data Structure

```powershell
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('output/user-data'))"

# Check structure
python -c "
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
print('user-data has users:', 'users' in ud)
print('user-data has write_files:', 'write_files' in ud)
"
```

### Step 3: Build ISO in Multipass VM

Follow the workflow from [5.3 Bootable Media Creation](../AUTOINSTALL_MEDIA_CREATION/TESTED_BOOTABLE_MEDIA_CREATION.md):

```powershell
# Load VM configuration
. .\vm.config.ps1

# Ensure builder VM exists
multipass launch --name $BuilderVMName --cpus $BuilderCpus --memory $BuilderMemory --disk $BuilderDisk 2>$null
# Or start existing
multipass start $BuilderVMName

# Transfer repository to builder VM
multipass transfer . ${BuilderVMName}:/home/ubuntu/build/

# Build ISO inside VM
multipass exec $BuilderVMName -- bash -c "cd ~/build && chmod +x output/scripts/build-iso.sh && ./output/scripts/build-iso.sh"
```

### Step 4: Validate ISO

```powershell
# Verify nocloud directory exists
multipass exec $BuilderVMName -- xorriso -indev ~/build/output/ubuntu-autoinstall.iso -ls /nocloud 2>/dev/null

# Verify GRUB has autoinstall entry
multipass exec $BuilderVMName -- bash -c "
  xorriso -indev ~/build/output/ubuntu-autoinstall.iso -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null
  grep -A5 'Autoinstall' /tmp/grub.cfg
"
```

### Step 5: Transfer ISO to Host

```powershell
# Transfer ISO from builder VM
multipass transfer "$BuilderVMName`:/home/ubuntu/build/output/ubuntu-autoinstall.iso" ./output/

# Verify
Get-Item ./output/ubuntu-autoinstall.iso | Select-Object Name, Length, LastWriteTime
```

### Step 6: Test with VirtualBox

```powershell
# Load VM configuration
if (-not (Test-Path ".\vm.config.ps1")) {
    Write-Error "Missing vm.config.ps1 - copy from vm.config.ps1.example"
    exit 1
}
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

# Create and attach disk (use larger size to test ZFS)
& $VBoxManage createmedium disk --filename $vdiPath --size $VBoxDiskSize --format VDI
& $VBoxManage storageattach $VBoxVMName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath

# Attach ISO
& $VBoxManage storageattach $VBoxVMName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $isoPath

# Start VM
& $VBoxManage startvm $VBoxVMName --type gui
```

### Step 7: Monitor Installation

Watch the VM window. The autoinstall process:

1. **GRUB menu** - "Autoinstall Ubuntu Server" selected (5 second timeout)
2. **Kernel boot** - Linux kernel loads
3. **Installer starts** - Ubuntu installer runs unattended
4. **Storage setup** - ZFS pool created on largest disk
5. **Package installation** - Base system + configured packages
6. **Cloud-init preparation** - user-data embedded for first boot
7. **Reboot** - System restarts automatically

Installation typically takes 10-15 minutes.

### Step 8: Validate Installation

After reboot, add SSH port forwarding and connect:

```powershell
# Add SSH port forwarding
& $VBoxManage controlvm $VBoxVMName natpf1 'ssh,tcp,,2222,,22'

# Wait for VM to be ready
Start-Sleep 30

# Connect via SSH (use password from src/config/identity.config.yaml)
ssh -p 2222 admin@localhost
```

**Validation commands** (run inside VM):

```bash
# Verify autoinstall completed
ls /var/log/installer/

# Verify cloud-init completed
cloud-init status

# Verify ZFS root
zfs list
zpool status

# Verify network configured
ip addr show
cat /etc/netplan/*.yaml

# Verify services running
systemctl status cockpit.socket libvirtd fail2ban ssh

# Verify packages installed
dpkg -l | grep -E "qemu-kvm|libvirt|cockpit|fail2ban|bat|fd-find"

# Verify user and groups
id admin
groups admin

# Verify firewall
sudo ufw status

# Verify dynamic MOTD
cat /run/motd.dynamic

# Verify Cockpit on localhost only
ss -tlnp | grep 443
```

### Step 9: Cleanup

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

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Malformed autoinstall config" | YAML syntax error | Check for inline comments in list items |
| "No autoinstall config found" | Missing datasource | Verify GRUB has `ds=nocloud\;s=/cdrom/nocloud/` |
| Installation drops to shell | early-commands failed | Check network config, arping availability |
| Boot loop after install | Wrong boot order | Eject ISO or change boot order in VM |
| ZFS pool not created | Disk too small | Use 25GB+ disk |
| cloud-init errors on first boot | Fragment merge issues | Test cloud-init separately first |

## Debug Commands

```bash
# Inside installed VM

# Autoinstall log
cat /var/log/installer/autoinstall-user-data

# Cloud-init logs
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log

# Early network script output (if failed)
cat /var/log/installer/curtin-install.log | grep -A20 "early-commands"
```

---

## Validation Checklist

After successful autoinstall, verify:

| Component | Check | Command |
|-----------|-------|---------|
| ZFS | Root on ZFS | `zfs list` |
| Network | Static IP applied | `ip addr show` |
| User | Admin user created | `id admin` |
| Groups | libvirt, kvm membership | `groups admin` |
| SSH | Service running | `systemctl status ssh` |
| Cockpit | Localhost only | `ss -tlnp \| grep 443` |
| libvirt | Daemon running | `virsh list --all` |
| fail2ban | Jails active | `sudo fail2ban-client status` |
| UFW | Firewall enabled | `sudo ufw status` |
| MOTD | Dynamic content | `cat /run/motd.dynamic` |
| CLI tools | bat, fd, htop | `which batcat fdfind htop` |
| OpenCode | AI agent (if enabled) | `which opencode` |

---

## Autoinstall-Specific Tests

These tests validate components that **cannot be tested with multipass** - they require the full autoinstall process.

### ZFS Root Filesystem

```bash
# Verify ZFS pool exists
zpool status
# Expected: pool "rpool" with state: ONLINE

# Verify ZFS datasets
zfs list
# Expected: rpool/ROOT/ubuntu mounted at /

# Check ZFS properties
zfs get compression,atime rpool
```

### Network Verification

Network is fully tested in [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md#scenario-1-network-configuration-test) with bridged multipass. Quick verification after autoinstall:

```bash
# Confirm IP matches config
ip addr show | grep "inet "

# Confirm gateway
ip route | grep default
```

### Installation Artifacts

```bash
# Verify autoinstall completed
ls -la /var/log/installer/
cat /var/log/installer/autoinstall-user-data | head -20

# Verify cloud-init ran after install
cloud-init status
cat /var/log/cloud-init-output.log | tail -50
```

### Boot Configuration

```bash
# Verify GRUB installed correctly
efibootmgr -v
# Expected: ubuntu entry pointing to correct disk

# Verify no installer remnants
mount | grep cdrom
# Expected: no output (ISO ejected)
```

---

## Cloud-init Tests (Reference)

For fragment-specific testing (security, virtualization, monitoring, user experience), see the automated test scenarios in [7.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md#automated-test-scenarios).

These tests work identically in multipass (7.1) and VirtualBox (7.2) since they validate cloud-init configuration, not autoinstall-specific behavior.

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

This allows testing multiple scenarios without full reinstall.

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

## Next Steps

After VirtualBox testing passes:

1. **Write ISO to USB** - Use Rufus, Ventoy, or `dd`
2. **Boot bare metal** - Select USB in BIOS boot menu
3. **Monitor installation** - Watch console or connect monitor
4. **Post-deployment** - Run `sudo msmtp-config` to configure email notifications

See [Chapter 8: Deployment Process](../DEPLOYMENT_PROCESS/OVERVIEW.md) for bare-metal deployment steps.
