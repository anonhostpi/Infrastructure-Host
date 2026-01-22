# Modified ISO Method for Ubuntu Autoinstall

This document describes the technique for creating a self-contained Ubuntu autoinstall ISO with embedded user-data. This approach modifies the stock Ubuntu ISO to include autoinstall configuration directly, eliminating the need for a separate CIDATA disk.

---

## Overview

The Modified ISO method works by:

1. Extracting the Ubuntu Server ISO
2. Adding `user-data` and `meta-data` files to the ISO root
3. Modifying GRUB to include the `autoinstall` kernel parameter with nocloud datasource
4. Repackaging into a bootable ISO

### Key Insight

The Ubuntu installer's nocloud datasource can read configuration from `/cdrom/` - the mount point of the boot ISO itself. By placing user-data at the ISO root and telling the kernel where to find it via `ds=nocloud;s=/cdrom/`, the installer finds the autoinstall configuration without needing a separate CIDATA volume.

### When to Use This Method

| Use Case | Recommended |
|----------|-------------|
| VM testing (VirtualBox, QEMU, etc.) | Yes |
| Air-gapped/offline deployment | Yes |
| Single self-contained media | Yes |
| Frequent config iteration | No (requires rebuild) |
| USB bare-metal (simple configs) | Yes |

---

## Prerequisites

### Required Tools

```bash
# Ubuntu/Debian
sudo apt-get install -y xorriso p7zip-full

# The tools serve these purposes:
# - xorriso: ISO extraction and repackaging (preserves boot structures)
# - p7zip-full: Alternative extraction method (7z command)
```

### Required Files

- Ubuntu Server ISO (e.g., `ubuntu-24.04.1-live-server-amd64.iso`)
- Your `user-data` file (autoinstall configuration)
- Optional: `meta-data` file (can be empty)

---

## Step-by-Step Process

### Step 1: Extract the ISO

Use xorriso to extract the ISO contents while preserving permissions:

```bash
SOURCE_ISO="ubuntu-24.04.1-live-server-amd64.iso"
WORKDIR="/tmp/iso-workdir"

mkdir -p "$WORKDIR"

# Extract using xorriso (preferred - preserves structure)
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$WORKDIR"

# Alternative: Extract using 7z
# 7z x -o"$WORKDIR" "$SOURCE_ISO"
```

After extraction, the directory structure looks like:

```
$WORKDIR/
├── boot/
│   └── grub/
│       ├── grub.cfg          # ← We modify this
│       ├── loopback.cfg
│       └── ...
├── casper/
│   ├── vmlinuz               # Kernel
│   ├── initrd                # Initial ramdisk
│   └── ...
├── dists/
├── pool/
├── md5sum.txt                # ← We update this
├── .disk/
└── [BOOT]/                   # EFI boot structures
```

### Step 2: Add Autoinstall Configuration

Place your user-data at the root of the extracted ISO:

```bash
# Copy user-data to ISO root
cp /path/to/your/user-data "$WORKDIR/user-data"

# Create meta-data (can be minimal or empty)
echo "instance-id: autoinstall-$(date +%Y%m%d)" > "$WORKDIR/meta-data"
```

The user-data file should be your complete autoinstall configuration:

```yaml
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  # ... rest of your autoinstall config
```

### Step 3: Modify GRUB Configuration

Edit `boot/grub/grub.cfg` to add the autoinstall kernel parameter:

```bash
GRUB_CFG="$WORKDIR/boot/grub/grub.cfg"

# Add autoinstall parameter to kernel command line
# The key addition is: autoinstall ds=nocloud;s=/cdrom/
sed -i 's|linux\t/casper/vmlinuz ---|linux\t/casper/vmlinuz autoinstall ds=nocloud\\;s=/cdrom/ ---|g' "$GRUB_CFG"

# If using HWE kernel, also modify that line
sed -i 's|linux\t/casper/hwe-vmlinuz ---|linux\t/casper/hwe-vmlinuz autoinstall ds=nocloud\\;s=/cdrom/ ---|g' "$GRUB_CFG"
```

**Important**: The semicolon in `ds=nocloud;s=/cdrom/` must be escaped as `\;` in GRUB config.

#### Understanding the Kernel Parameters

| Parameter | Purpose |
|-----------|---------|
| `autoinstall` | Tells subiquity to run in automated mode |
| `ds=nocloud` | Specifies the cloud-init datasource type |
| `s=/cdrom/` | Tells nocloud where to find user-data/meta-data |

#### Before and After

**Before:**
```
linux   /casper/vmlinuz  ---
```

**After:**
```
linux   /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/  ---
```

### Step 4: Update Checksums

Update the md5sum.txt file to reflect the modified files:

```bash
cd "$WORKDIR"

# Remove old checksums for files we modified/added
sed -i '/grub\.cfg/d' md5sum.txt
sed -i '/user-data/d' md5sum.txt
sed -i '/meta-data/d' md5sum.txt

# Add new checksums
md5sum ./boot/grub/grub.cfg >> md5sum.txt
md5sum ./user-data >> md5sum.txt
md5sum ./meta-data >> md5sum.txt
```

### Step 5: Repackage the ISO

Use xorriso to create a new bootable ISO:

```bash
OUTPUT_ISO="ubuntu-autoinstall-modified.iso"

xorriso -as mkisofs \
    -r -V "Ubuntu-Server Autoinstall" \
    -o "$OUTPUT_ISO" \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$WORKDIR/[BOOT]/2-Boot-NoEmul.img" \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    "$WORKDIR"
```

#### Simplified xorriso Command

If the full command fails (missing files on some systems), try this simplified version:

```bash
xorriso -as mkisofs \
    -r -V "Ubuntu-Server Autoinstall" \
    -J -joliet-long \
    -o "$OUTPUT_ISO" \
    -b boot/grub/i386-pc/eltorito.img \
    -c boot.catalog \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/boot/bootx64.efi \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    "$WORKDIR"
```

---

## Complete Script

Here's a complete bash script implementing the method:

```bash
#!/bin/bash
set -euo pipefail

# Configuration
SOURCE_ISO="${1:?Usage: $0 <source-iso> <user-data> [output-iso]}"
USER_DATA="${2:?Usage: $0 <source-iso> <user-data> [output-iso]}"
OUTPUT_ISO="${3:-ubuntu-autoinstall-modified.iso}"

WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

echo "=== Modified ISO Builder ==="
echo "Source:  $SOURCE_ISO"
echo "Config:  $USER_DATA"
echo "Output:  $OUTPUT_ISO"
echo ""

# Step 1: Extract
echo "[1/5] Extracting ISO..."
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$WORKDIR" 2>/dev/null

# Step 2: Add autoinstall config
echo "[2/5] Adding autoinstall configuration..."
cp "$USER_DATA" "$WORKDIR/user-data"
echo "instance-id: autoinstall-$(date +%Y%m%d%H%M%S)" > "$WORKDIR/meta-data"

# Step 3: Modify GRUB
echo "[3/5] Modifying GRUB configuration..."
GRUB_CFG="$WORKDIR/boot/grub/grub.cfg"

# Backup original
cp "$GRUB_CFG" "$GRUB_CFG.bak"

# Add autoinstall parameters
sed -i 's|linux\t/casper/vmlinuz ---|linux\t/casper/vmlinuz autoinstall ds=nocloud\\;s=/cdrom/ ---|g' "$GRUB_CFG"
sed -i 's|linux\t/casper/hwe-vmlinuz ---|linux\t/casper/hwe-vmlinuz autoinstall ds=nocloud\\;s=/cdrom/ ---|g' "$GRUB_CFG"

# Verify modification
if ! grep -q "autoinstall" "$GRUB_CFG"; then
    echo "ERROR: Failed to modify GRUB config"
    exit 1
fi

# Step 4: Update checksums
echo "[4/5] Updating checksums..."
cd "$WORKDIR"
sed -i '/grub\.cfg/d' md5sum.txt 2>/dev/null || true
sed -i '/user-data/d' md5sum.txt 2>/dev/null || true
sed -i '/meta-data/d' md5sum.txt 2>/dev/null || true
md5sum ./boot/grub/grub.cfg >> md5sum.txt
md5sum ./user-data >> md5sum.txt
md5sum ./meta-data >> md5sum.txt

# Step 5: Repackage
echo "[5/5] Building ISO..."
xorriso -as mkisofs \
    -r -V "Ubuntu-Server Autoinstall" \
    -o "$OUTPUT_ISO" \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$WORKDIR/[BOOT]/2-Boot-NoEmul.img" \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    "$WORKDIR" 2>/dev/null

echo ""
echo "=== Complete ==="
echo "Output: $OUTPUT_ISO"
echo "Size:   $(du -h "$OUTPUT_ISO" | cut -f1)"
```

---

## Verification

### Verify ISO Structure

```bash
# Check that user-data exists at root
xorriso -indev ubuntu-autoinstall-modified.iso -ls / 2>/dev/null | grep -E "user-data|meta-data"

# Extract and verify GRUB config
xorriso -osirrox on -indev ubuntu-autoinstall-modified.iso \
    -extract /boot/grub/grub.cfg /tmp/grub-check.cfg 2>/dev/null
grep "autoinstall" /tmp/grub-check.cfg
```

Expected output:
```
'user-data'
'meta-data'
linux   /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/  ---
```

### Test in VirtualBox

```bash
# Create VM and attach single ISO
VBoxManage createvm --name "autoinstall-test" --ostype Ubuntu_64 --register
VBoxManage modifyvm "autoinstall-test" --memory 4096 --cpus 2 --firmware efi
VBoxManage storagectl "autoinstall-test" --name "SATA" --add sata
VBoxManage createmedium disk --filename test-disk.vdi --size 40960
VBoxManage storageattach "autoinstall-test" --storagectl "SATA" --port 0 --type hdd --medium test-disk.vdi
VBoxManage storageattach "autoinstall-test" --storagectl "SATA" --port 1 --type dvddrive --medium ubuntu-autoinstall-modified.iso
VBoxManage startvm "autoinstall-test"
```

**Key difference from CIDATA method**: Only ONE ISO attached. No separate cloud-init disk needed.

---

## How It Works

### Boot Sequence

```
1. BIOS/UEFI loads ISO
         ↓
2. GRUB starts, reads grub.cfg
         ↓
3. Kernel boots with: autoinstall ds=nocloud;s=/cdrom/
         ↓
4. cloud-init initializes, checks nocloud datasource
         ↓
5. Nocloud looks at /cdrom/ (ISO mount point)
         ↓
6. Finds /cdrom/user-data and /cdrom/meta-data
         ↓
7. subiquity reads autoinstall config from user-data
         ↓
8. Fully automated installation proceeds
```

### Datasource Resolution

The `ds=nocloud;s=/cdrom/` parameter tells cloud-init:

1. **ds=nocloud**: Use the NoCloud datasource
2. **s=/cdrom/**: The "seed" directory is `/cdrom/`

Cloud-init then looks for:
- `/cdrom/user-data` - Autoinstall/cloud-init configuration
- `/cdrom/meta-data` - Instance metadata

Since the ISO is mounted at `/cdrom/` during installation, our files are found automatically.

---

## Troubleshooting

### ISO Won't Boot

```bash
# Verify ISO is bootable
file ubuntu-autoinstall-modified.iso
# Expected: DOS/MBR boot sector... bootable

# Check EFI boot structure exists
xorriso -indev ubuntu-autoinstall-modified.iso -ls /EFI/boot/ 2>/dev/null
```

### Autoinstall Not Triggered

```bash
# Check kernel command line inside booted system
cat /proc/cmdline
# Should contain: autoinstall ds=nocloud;s=/cdrom/

# Check cloud-init datasource
cloud-init query ds
# Expected: DataSourceNoCloud

# Check if user-data was found
cat /var/log/installer/autoinstall-user-data
```

### GRUB Modification Failed

```bash
# Verify GRUB file exists and was modified
grep -n "linux.*vmlinuz" "$WORKDIR/boot/grub/grub.cfg"

# Common issues:
# - Tab vs space: GRUB uses tabs, ensure sed pattern matches
# - Multiple kernel entries: Both vmlinuz and hwe-vmlinuz need modification
```

### xorriso Repackaging Fails

```bash
# Check for missing boot files
ls -la "$WORKDIR/[BOOT]/"
ls -la "$WORKDIR/boot/grub/i386-pc/"

# If [BOOT] directory doesn't exist, use simplified xorriso command
# Or ensure xorriso extracted with -osirrox on flag
```

---

## Comparison with Other Methods

| Aspect | Modified ISO | CIDATA Method | Ventoy |
|--------|-------------|---------------|--------|
| ISOs needed | 1 | 2 | 1 (unmodified) |
| VM testing | Excellent | Good | Does not work |
| Config location | ISO root | Separate disk | USB partition |
| Rebuild for changes | Full ISO | CIDATA only | Edit files |
| Offline packages | Possible | Not possible | Not possible |
| Complexity | Medium | Low | Low |

---

## References

- [Ubuntu Autoinstall Documentation](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
- [Cloud-init NoCloud Datasource](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html)
- [xorriso Manual](https://www.gnu.org/software/xorriso/man_1_xorriso.html)
- [GRUB Manual](https://www.gnu.org/software/grub/manual/grub/)
