#!/bin/bash
# build-iso.sh - Build autoinstall ISO using xorriso in-place modification
# Run inside multipass VM
set -e

UBUNTU_VERSION="24.04.3"
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
cp "$HOME/user-data" "$HOME/nocloud_add/"
cp "$HOME/meta-data" "$HOME/nocloud_add/"

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
