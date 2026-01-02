# 5.3 Bootable Media Creation

This section covers building the autoinstall ISO using xorriso in-place modification.

**Important:** Do NOT extract and rebuild the ISO with `xorriso -as mkisofs` - this corrupts the boot structure. Use in-place modification instead.

## build-iso.sh

Automated script for building the autoinstall ISO. Run inside a multipass VM.

```bash
#!/bin/bash
# build-iso.sh - Build autoinstall ISO using xorriso in-place modification
# Run inside multipass VM
set -e

UBUNTU_VERSION="24.04.2"
ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"
ORIGINAL_ISO="ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"
OUTPUT_ISO="$HOME/ubuntu-autoinstall.iso"

echo "=== Installing dependencies ==="
sudo apt-get update -qq
sudo apt-get install -y -qq xorriso wget

echo "=== Downloading Ubuntu ISO (if not cached) ==="
if [ ! -f "$HOME/$ORIGINAL_ISO" ]; then
    wget -q --show-progress "$ISO_URL" -O "$HOME/$ORIGINAL_ISO"
else
    echo "Using cached ISO"
fi

echo "=== Copying ISO for modification ==="
cp "$HOME/$ORIGINAL_ISO" "$OUTPUT_ISO"

echo "=== Creating config directories ==="
mkdir -p "$HOME/nocloud_add" "$HOME/grub_mod"

# user-data is the autoinstall config (includes embedded cloud-init)
cp "$HOME/user-data" "$HOME/nocloud_add/"

# meta-data is minimal
cat > "$HOME/nocloud_add/meta-data" << 'EOF'
instance-id: autoinstall-001
EOF

echo "=== Creating GRUB config ==="
cat > "$HOME/grub_mod/grub.cfg" << 'GRUBEOF'
set timeout=5
set default=0
loadfont unicode
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Autoinstall Ubuntu Server" {
    set gfxpayload=keep
    linux /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/nocloud/ consoleblank=0 ---
    initrd /casper/initrd
}

menuentry "Ubuntu Server (Manual Install)" {
    set gfxpayload=keep
    linux /casper/vmlinuz ---
    initrd /casper/initrd
}
GRUBEOF

echo "=== Modifying ISO in-place with xorriso ==="
xorriso -indev "$OUTPUT_ISO" \
    -outdev "$OUTPUT_ISO" \
    -boot_image any replay \
    -map "$HOME/nocloud_add" /nocloud \
    -map "$HOME/grub_mod/grub.cfg" /boot/grub/grub.cfg \
    -commit

echo "=== Verifying ISO ==="
xorriso -indev "$OUTPUT_ISO" -ls /nocloud 2>/dev/null || true

echo "=== ISO built successfully ==="
ls -lh "$OUTPUT_ISO"
```

## Usage

### Transfer to Builder VM

```powershell
# Transfer script to builder VM
multipass transfer build-iso.sh iso-builder:/home/ubuntu/
multipass exec iso-builder -- chmod +x build-iso.sh

# Ensure user-data is already built and transferred
multipass transfer user-data iso-builder:/home/ubuntu/
```

### Execute Build

```powershell
multipass exec iso-builder -- ./build-iso.sh
```

### Retrieve ISO

```powershell
multipass transfer iso-builder:/home/ubuntu/ubuntu-autoinstall.iso .\output\
```

## Script Details

| Step | Description |
|------|-------------|
| Install dependencies | Installs `xorriso` and `wget` |
| Download ISO | Downloads Ubuntu Server ISO (cached for subsequent builds) |
| Copy ISO | Creates working copy to preserve original |
| Create nocloud directory | Copies `user-data`, creates minimal `meta-data` |
| Create GRUB config | Sets up autoinstall boot menu entry |
| Modify ISO | Uses xorriso in-place modification (preserves boot structure) |
| Verify | Lists `/nocloud` directory contents |

## Critical GRUB Configuration Notes

The kernel command line **MUST** include the datasource parameter with escaped semicolon:
```
ds=nocloud\;s=/cdrom/nocloud/
```

Without this parameter, cloud-init won't find the user-data and autoinstall won't trigger.

The `consoleblank=0` parameter prevents screen blanking during installation.

## Verification

After creating media, verify it boots correctly:

1. Boot a test VM or spare hardware
2. Verify GRUB menu shows "Autoinstall Ubuntu Server"
3. Verify autoinstall starts automatically (no user prompts)
4. Monitor for any configuration errors
5. Confirm installation completes and reboots

See [6.1 Test Procedures](../TESTING_AND_VALIDATION/TEST_PROCEDURES.md) for complete testing workflow.

## Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Missing datasource parameter | Drops to shell, no autoinstall | Add `ds=nocloud\;s=/cdrom/nocloud/` to kernel cmdline |
| Corrupted ISO | I/O errors during boot | Use in-place modification, not extract/rebuild |
| Screen blanking | Installer appears stuck | Add `consoleblank=0` to kernel cmdline |
