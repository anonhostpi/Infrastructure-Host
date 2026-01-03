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
# Ensure builder VM exists
multipass launch --name iso-builder --cpus 2 --memory 4G --disk 20G 2>$null
# Or start existing
multipass start iso-builder

# Transfer repository to builder VM
multipass transfer . iso-builder:/home/ubuntu/build/

# Build ISO inside VM
multipass exec iso-builder -- bash -c "cd ~/build && chmod +x output/scripts/build-iso.sh && ./output/scripts/build-iso.sh"
```

### Step 4: Validate ISO

```powershell
# Verify nocloud directory exists
multipass exec iso-builder -- xorriso -indev ~/build/output/ubuntu-autoinstall.iso -ls /nocloud 2>/dev/null

# Verify GRUB has autoinstall entry
multipass exec iso-builder -- bash -c "
  xorriso -indev ~/build/output/ubuntu-autoinstall.iso -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null
  grep -A5 'Autoinstall' /tmp/grub.cfg
"
```

### Step 5: Transfer ISO to Host

```powershell
# Transfer ISO from builder VM
multipass transfer iso-builder:/home/ubuntu/build/output/ubuntu-autoinstall.iso ./output/

# Verify
Get-Item ./output/ubuntu-autoinstall.iso | Select-Object Name, Length, LastWriteTime
```

### Step 6: Test with VirtualBox

```powershell
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$vmName = 'ubuntu-autoinstall-test'
$isoPath = (Resolve-Path './output/ubuntu-autoinstall.iso').Path
$vdiPath = (Join-Path (Get-Location) 'output/ubuntu-test.vdi')

# Cleanup existing VM if present
$existingVM = & $vbox list vms 2>$null | Select-String $vmName
if ($existingVM) {
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep 2
    & $vbox unregistervm $vmName --delete 2>$null
}
if (Test-Path $vdiPath) { Remove-Item $vdiPath -Force }

# Create VM with UEFI (matches bare metal)
& $vbox createvm --name $vmName --ostype Ubuntu_64 --register
& $vbox modifyvm $vmName --memory 4096 --cpus 2 --nic1 nat --firmware efi

# Add storage controller
& $vbox storagectl $vmName --name 'SATA' --add sata --controller IntelAhci

# Create and attach disk (use larger size to test ZFS)
& $vbox createmedium disk --filename $vdiPath --size 40960 --format VDI
& $vbox storageattach $vmName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath

# Attach ISO
& $vbox storageattach $vmName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $isoPath

# Start VM
& $vbox startvm $vmName --type gui
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
& $vbox controlvm $vmName natpf1 'ssh,tcp,,2222,,22'

# Wait for VM to be ready
Start-Sleep 30

# Connect via SSH (use password from identity.config.yaml)
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
& $vbox controlvm $vmName poweroff 2>$null
Start-Sleep 2
& $vbox unregistervm $vmName --delete

# Remove VDI
Remove-Item ./output/ubuntu-test.vdi -Force -ErrorAction SilentlyContinue

# Optionally keep ISO for bare-metal deployment
# Remove-Item ./output/ubuntu-autoinstall.iso -Force

# Stop builder VM (preserves cached Ubuntu ISO)
multipass stop iso-builder
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

---

## Next Steps

After VirtualBox testing passes:

1. **Write ISO to USB** - Use Rufus, Ventoy, or `dd`
2. **Boot bare metal** - Select USB in BIOS boot menu
3. **Monitor installation** - Watch console or connect monitor
4. **Post-deployment** - Run `sudo msmtp-config` to configure email notifications

See [Chapter 8: Deployment Process](../DEPLOYMENT_PROCESS/OVERVIEW.md) for bare-metal deployment steps.
