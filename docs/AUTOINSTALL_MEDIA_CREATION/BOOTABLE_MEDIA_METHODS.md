# 4.3 Methods to Create Bootable Media

## Method A: Modify ISO with Autoinstall (Recommended)

This method embeds autoinstall configuration directly into the ISO.

```bash
# Install required tools
sudo apt install xorriso isolinux

# Extract ISO
xorriso -osirrox on -indev ubuntu-24.04-live-server-amd64.iso -extract / iso_extract

# Copy autoinstall files
cp user-data iso_extract/nocloud/user-data
cp meta-data iso_extract/nocloud/meta-data

# Modify grub config to use autoinstall
cat > iso_extract/boot/grub/grub.cfg << 'EOF'
set timeout=5
menuentry "Autoinstall Ubuntu Server" {
    linux /casper/vmlinuz autoinstall ds=nocloud;s=/cdrom/nocloud/ ---
    initrd /casper/initrd
}
EOF

# Rebuild ISO
cd iso_extract
sudo xorriso -as mkisofs -r \
  -V "Ubuntu Autoinstall" \
  -o ../ubuntu-autoinstall.iso \
  -J -joliet-long \
  -cache-inodes \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  .

cd ..
```

## Method B: USB with Separate Autoinstall Files

This method adds autoinstall files to an existing bootable USB.

```bash
# Write ISO to USB
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress
sync

# Mount USB and add autoinstall files
sudo mount /dev/sdX1 /mnt
sudo mkdir -p /mnt/nocloud
sudo cp user-data /mnt/nocloud/
sudo cp meta-data /mnt/nocloud/
sudo umount /mnt
```

**Note:** Replace `/dev/sdX` with your actual USB device (check with `lsblk`).

## Method Comparison

| Method | Pros | Cons |
|--------|------|------|
| Modified ISO | Self-contained, works anywhere | Requires rebuilding for changes |
| USB + Files | Easy to update config | Requires USB modification |

## Verification

After creating media, verify it boots correctly:

1. Boot a test VM or spare hardware
2. Verify autoinstall starts automatically
3. Monitor for any configuration errors
4. Confirm installation completes and reboots
