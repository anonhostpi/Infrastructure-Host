# Autoinstall ISO Testing

## Overview
This directory contains scripts to build and test Ubuntu autoinstall ISOs.

## Files
- `build-iso.sh` - Runs in multipass to build the autoinstall ISO (xorriso in-place)
- `user-data` - Cloud-init autoinstall configuration
- `meta-data` - Cloud-init metadata (minimal)
- `Test-Autoinstall.ps1` - Main test script (supports VirtualBox and Hyper-V)
- `Send-VMKeys.ps1` - Hyper-V keyboard input helper (for debugging)

## Build Process

### Prerequisites
- Multipass installed on Windows
- VirtualBox (recommended) or Hyper-V for testing

### Quick Start
```powershell
# Run full test (builds ISO, creates VM, waits for install)
.\Test-Autoinstall.ps1

# Use Hyper-V instead of VirtualBox
.\Test-Autoinstall.ps1 -Hypervisor HyperV

# Skip rebuild if ISO already exists
.\Test-Autoinstall.ps1 -SkipBuild

# Cleanup test resources
.\Test-Autoinstall.ps1 -Cleanup
```

### Manual ISO Build (xorriso in-place method)

This method modifies the original ISO in-place, preserving boot structures:

```powershell
# Start/create multipass builder VM
multipass launch --name iso-builder --cpus 2 --memory 4G --disk 20G

# Transfer config files
multipass transfer user-data iso-builder:/home/ubuntu/user-data
multipass transfer meta-data iso-builder:/home/ubuntu/meta-data

# Download original Ubuntu ISO (in multipass)
multipass exec iso-builder -- wget -O ~/ubuntu-24.04.3-live-server-amd64.iso \
  "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"

# Copy to working file
multipass exec iso-builder -- cp ~/ubuntu-24.04.3-live-server-amd64.iso ~/ubuntu-autoinstall.iso

# Create staging directories
multipass exec iso-builder -- mkdir -p ~/nocloud_add ~/grub_mod
multipass exec iso-builder -- cp ~/user-data ~/nocloud_add/
multipass exec iso-builder -- cp ~/meta-data ~/nocloud_add/

# Create GRUB config (note escaped semicolon)
multipass exec iso-builder -- bash -c 'cat > ~/grub_mod/grub.cfg << '\''GRUBEOF'\''
set timeout=5
set default=0
menuentry "Autoinstall Ubuntu Server" {
    set gfxpayload=keep
    linux /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/nocloud/ ---
    initrd /casper/initrd
}
menuentry "Ubuntu Server (Manual Install)" {
    set gfxpayload=keep
    linux /casper/vmlinuz ---
    initrd /casper/initrd
}
GRUBEOF'

# Modify ISO in-place with xorriso (preserves boot structure!)
multipass exec iso-builder -- xorriso -indev ~/ubuntu-autoinstall.iso \
    -outdev ~/ubuntu-autoinstall.iso \
    -boot_image any replay \
    -map ~/nocloud_add /nocloud \
    -map ~/grub_mod/grub.cfg /boot/grub/grub.cfg \
    -commit

# Transfer ISO back to Windows
multipass transfer iso-builder:/home/ubuntu/ubuntu-autoinstall.iso ./output/
```

**Important**: Using xorriso in-place modification preserves the original ISO's boot structure (El Torito, MBR, GPT). Extracting and rebuilding with xorriso -as mkisofs can corrupt the boot image.

## Key Learnings

### GRUB Configuration
The kernel command line MUST include the datasource parameter:
```
linux /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/nocloud/ quiet ---
```

Without `ds=nocloud;s=/cdrom/nocloud/`, cloud-init won't find the user-data.

### user-data Location
Place files in `/nocloud/` directory on the ISO:
- `/nocloud/user-data` - autoinstall configuration
- `/nocloud/meta-data` - metadata (can be minimal)

Also copy to ISO root for redundancy.

### user-data Format
```yaml
#cloud-config
autoinstall:
  version: 1
  interactive-sections: []  # Required for unattended
  locale: en_US.UTF-8
  keyboard:
    layout: us
  network:
    version: 2
    ethernets:
      any:
        match:
          name: e*
        dhcp4: true
  storage:
    layout:
      name: lvm
      sizing-policy: all
  identity:
    hostname: myhost
    username: myuser
    password: "<sha512-hash>"  # Use: openssl passwd -6 yourpassword
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
  late-commands:
    - echo 'Installation complete' > /target/var/log/autoinstall.log
  shutdown: reboot
```

### Common Issues

1. **Malformed YAML in late-commands**
   - Don't use inline comments within list items
   - Keep commands simple and on single lines
   - Test YAML syntax before building ISO

2. **Missing datasource parameter**
   - Symptom: Drops to shell instead of running autoinstall
   - Fix: Add `ds=nocloud;s=/cdrom/nocloud/` to kernel cmdline

3. **Invalid password hash**
   - Must be a valid SHA-512 hash
   - Generate with: `openssl passwd -6 yourpassword`

4. **CD unmount failure at end**
   - This is cosmetic - installation usually completed
   - Force reboot/power cycle to continue

## Testing

### Hyper-V Notes
- Gen 1 VMs use BIOS boot - GRUB config at `/boot/grub/grub.cfg` works
- Gen 2 VMs use UEFI - may need additional EFI GRUB config
- Some I/O issues observed with virtual DVD drive

### VirtualBox Testing (Verified Working)

```powershell
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$vmName = 'ubuntu-autoinstall-test'
$isoPath = '.\output\ubuntu-autoinstall.iso'
$vdiPath = '.\output\ubuntu-test.vdi'

# Create VM
& $vbox createvm --name $vmName --ostype Ubuntu_64 --register
& $vbox modifyvm $vmName --memory 4096 --cpus 2 --nic1 nat

# Add SATA controller
& $vbox storagectl $vmName --name 'SATA' --add sata --controller IntelAhci

# Create and attach disk
& $vbox createmedium disk --filename $vdiPath --size 20480 --format VDI
& $vbox storageattach $vmName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath

# Attach ISO
& $vbox storageattach $vmName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $isoPath

# Start VM
& $vbox startvm $vmName --type gui
```

After installation completes, query IP via guest properties:
```powershell
& $vbox guestproperty enumerate $vmName | Select-String 'Net'
```

Add SSH port forwarding:
```powershell
& $vbox controlvm $vmName natpf1 'ssh,tcp,,2222,,22'
ssh -p 2222 test@localhost  # Password: test
```

**Note**: For fully automated SSH testing, use SSH keys instead of password auth.
Add to user-data:
```yaml
ssh:
  install-server: true
  authorized-keys:
    - ssh-rsa AAAA... your-public-key
```

## Status
- [x] ISO build process verified (xorriso in-place modification)
- [x] GRUB configuration verified (ds=nocloud\;s=/cdrom/nocloud/)
- [x] Autoinstall triggers correctly
- [x] Full end-to-end test verified with VirtualBox
- [x] Guest utils provide IP visibility
- [x] SSH access confirmed
