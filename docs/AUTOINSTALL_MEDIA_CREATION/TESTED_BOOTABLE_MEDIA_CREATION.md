# 4.3 Tested Bootable Media Creation

## Modify ISO In-Place with xorriso

This method modifies the original ISO in-place, preserving boot structures. This approach has been verified working in VM testing (see `tests/autoinstall/`).

**Important:** Do NOT extract and rebuild the ISO with `xorriso -as mkisofs` - this corrupts the boot structure. Use in-place modification instead.

```bash
# Install required tools
sudo apt install xorriso wget cloud-image-utils

# Query for latest Ubuntu 24.04 live server ISO
ISO_URL=$(ubuntu-cloudimg-query noble live-server amd64 --format "%{url}\n")

# Download ISO
wget -q --show-progress "$ISO_URL" -O ubuntu-live-server.iso

# Copy ISO for modification (preserve original)
cp ubuntu-live-server.iso ubuntu-autoinstall.iso

# Create staging directories
mkdir -p nocloud_add grub_mod

# Copy autoinstall files to staging
cp user-data nocloud_add/
cp meta-data nocloud_add/

# Create GRUB config (note: semicolon MUST be escaped with backslash)
cat > grub_mod/grub.cfg << 'EOF'
set timeout=5
set default=0

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
EOF

# Modify ISO in-place (preserves El Torito, MBR, GPT boot structures)
xorriso -indev ubuntu-autoinstall.iso \
    -outdev ubuntu-autoinstall.iso \
    -boot_image any replay \
    -map nocloud_add /nocloud \
    -map grub_mod/grub.cfg /boot/grub/grub.cfg \
    -commit

# Verify the modification
xorriso -indev ubuntu-autoinstall.iso -ls /nocloud
```

### Critical GRUB Configuration Notes

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

## Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Missing datasource parameter | Drops to shell, no autoinstall | Add `ds=nocloud\;s=/cdrom/nocloud/` to kernel cmdline |
| Corrupted ISO | I/O errors during boot | Use in-place modification, not extract/rebuild |
| Screen blanking | Installer appears stuck | Add `consoleblank=0` to kernel cmdline |
