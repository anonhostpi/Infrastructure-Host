#!/bin/bash
# build-iso.sh - Build self-contained autoinstall ISO with embedded user-data
# Run inside multipass VM: ./output/scripts/build-iso.sh
# Generated from build-iso.sh.tpl - do not edit directly
#
# This script implements the Modified ISO method:
# - Extracts Ubuntu Server ISO
# - Embeds user-data and meta-data at ISO root
# - Modifies GRUB to add autoinstall + nocloud datasource parameters
# - Repackages into a single bootable ISO (no separate CIDATA needed)
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Image settings from image.config.yaml
RELEASE="{{ image.release }}"
TYPE="{{ image.type }}"
ARCH="{{ image.arch }}"

# Output paths
# NOTE: ISO is built in /tmp to avoid multipass mount 2GB file size limit
# Use 'multipass transfer' to copy it to Windows host
OUTPUT_ISO="/tmp/ubuntu-autoinstall.iso"
USER_DATA="$SCRIPT_DIR/user-data"

# Working directories (cleaned up on exit)
TMPDIR=""
BOOTDIR=""

# Ubuntu GPG key for verification
UBUNTU_GPG_KEY_ID="843938DF228D22F7B3742BC0D94AA3F0EFE21092"

# ============================================================================
# Utility Functions
# ============================================================================

log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

die() {
    local msg=$1
    local code=${2-1}
    log "ERROR: $msg"
    exit "$code"
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    if [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ]; then
        rm -rf "$TMPDIR"
        log "Cleaned up temporary directory"
    fi
    if [ -n "${BOOTDIR:-}" ] && [ -d "$BOOTDIR" ]; then
        rm -rf "$BOOTDIR"
    fi
}

trap cleanup SIGINT SIGTERM ERR EXIT

# ============================================================================
# Dependency Installation
# ============================================================================

install_deps() {
    log "=== Installing dependencies ==="
    sudo apt-get update -qq

    # Core dependencies
    local packages="xorriso p7zip-full curl wget"

    # Optional: GPG for verification
    packages="$packages gpg"

    # For focal (20.04) we also need isolinux
    if [ "$RELEASE" = "focal" ]; then
        packages="$packages isolinux"
    fi

    sudo apt-get install -y -qq $packages
    log "Dependencies installed"
}

# ============================================================================
# ISO Download
# ============================================================================

get_iso_url() {
    log "=== Determining ISO URL ==="

    if [ "$TYPE" = "live-server" ]; then
        # Live-server ISOs are on releases.ubuntu.com
        local base_url="https://releases.ubuntu.com/${RELEASE}"

        # Find the latest ISO filename
        local iso_name
        iso_name=$(curl -sL "$base_url/" | grep -oP "ubuntu-[0-9.]+-live-server-${ARCH}\.iso" | head -1)

        if [ -z "$iso_name" ]; then
            die "Could not find live-server ISO for ${RELEASE} ${ARCH}"
        fi

        echo "${base_url}/${iso_name}"
    else
        die "Unsupported image type: $TYPE (only live-server is supported)"
    fi
}

download_iso() {
    local iso_url="$1"
    local iso_name
    iso_name=$(basename "$iso_url")

    log "=== Downloading Ubuntu ISO ==="
    log "URL: $iso_url"

    # Always download fresh to /tmp (avoids multipass mount 2GB limit)
    local tmp_iso="/tmp/${iso_name}"
    rm -f "$tmp_iso"
    wget -q --show-progress "$iso_url" -O "$tmp_iso"

    if [ ! -f "$tmp_iso" ]; then
        die "Failed to download ISO"
    fi

    # Verify downloaded size (live-server ISOs are >2GB)
    local downloaded_size
    downloaded_size=$(stat -c%s "$tmp_iso" 2>/dev/null || stat -f%z "$tmp_iso" 2>/dev/null)
    if [ "$downloaded_size" -lt 2147483648 ]; then
        rm -f "$tmp_iso"
        die "Downloaded ISO is truncated (${downloaded_size} bytes). Check network connection."
    fi

    log "Downloaded: $(ls -lh "$tmp_iso" | awk '{print $5}')"
    echo "$tmp_iso"
}

# ============================================================================
# GPG Verification (Optional)
# ============================================================================

verify_iso() {
    local iso_path="$1"
    local base_url="https://releases.ubuntu.com/${RELEASE}"

    log "=== Verifying ISO integrity ==="

    # Download SHA256SUMS if not present
    if [ ! -f "$SCRIPT_DIR/SHA256SUMS" ]; then
        log "Downloading SHA256SUMS..."
        curl -sL "${base_url}/SHA256SUMS" -o "$SCRIPT_DIR/SHA256SUMS" || {
            log "WARNING: Could not download SHA256SUMS, skipping verification"
            return 0
        }
    fi

    # Verify checksum
    local iso_name
    iso_name=$(basename "$iso_path")
    local expected_hash
    expected_hash=$(grep "$iso_name" "$SCRIPT_DIR/SHA256SUMS" | cut -d' ' -f1)

    if [ -z "$expected_hash" ]; then
        log "WARNING: ISO not found in SHA256SUMS, skipping verification"
        return 0
    fi

    local actual_hash
    actual_hash=$(sha256sum "$iso_path" | cut -d' ' -f1)

    if [ "$expected_hash" = "$actual_hash" ]; then
        log "ISO verification successful"
    else
        die "ISO verification failed! Expected: $expected_hash, Got: $actual_hash"
    fi
}

# ============================================================================
# ISO Extraction
# ============================================================================

extract_iso() {
    local iso_path="$1"

    log "=== Extracting ISO ==="

    # Create temporary directory
    TMPDIR=$(mktemp -d)
    BOOTDIR=$(mktemp -d)

    if [ ! -d "$TMPDIR" ]; then
        die "Could not create temporary directory"
    fi

    log "Working directory: $TMPDIR"

    if [ "$RELEASE" = "focal" ]; then
        # Focal (20.04) uses xorriso extraction
        xorriso -osirrox on -indev "$iso_path" -extract / "$TMPDIR" 2>/dev/null
        rm -rf "$TMPDIR/[BOOT]"
    else
        # Jammy (22.04) and Noble (24.04) use 7z extraction
        # The [BOOT] directory must be preserved separately for xorriso
        7z -y x "$iso_path" -o"$TMPDIR" >/dev/null 2>&1

        if [ -d "$TMPDIR/[BOOT]" ]; then
            mv "$TMPDIR/[BOOT]" "$BOOTDIR/BOOT"
        else
            die "No [BOOT] directory found in ISO - extraction may have failed"
        fi
    fi

    # Make files writable
    chmod -R u+w "$TMPDIR"

    log "Extracted to $TMPDIR"
}

# ============================================================================
# GRUB Modification
# ============================================================================

modify_grub() {
    log "=== Modifying GRUB configuration ==="

    local grub_cfg="$TMPDIR/boot/grub/grub.cfg"

    if [ ! -f "$grub_cfg" ]; then
        die "GRUB config not found: $grub_cfg"
    fi

    # Backup original
    cp "$grub_cfg" "$grub_cfg.orig"

    # Set short timeout (5 seconds) and ensure first entry is default
    # This ensures autoinstall proceeds without waiting for user input
    sed -i 's|set timeout=.*|set timeout=5|g' "$grub_cfg"
    if ! grep -q 'set default=' "$grub_cfg"; then
        sed -i '1i set default=0' "$grub_cfg"
    fi
    log "Set GRUB timeout=5 and default=0"

    # Add 'autoinstall' parameter if not present
    # The kernel line typically ends with '---'
    if ! grep -q 'autoinstall' "$grub_cfg"; then
        sed -i 's|---$|autoinstall ---|g' "$grub_cfg"
        sed -i 's|--- $|autoinstall --- |g' "$grub_cfg"
        log "Added 'autoinstall' parameter"
    fi

    # Add nocloud datasource pointing to /cdrom/ (where ISO is mounted)
    # The semicolon must be escaped as \; in GRUB
    if ! grep -q 'ds=nocloud' "$grub_cfg"; then
        sed -i 's|autoinstall ---|autoinstall ds=nocloud\\;s=/cdrom/ ---|g' "$grub_cfg"
        log "Added 'ds=nocloud;s=/cdrom/' parameter"
    fi

    # For focal, also modify isolinux and loopback configs
    if [ "$RELEASE" = "focal" ]; then
        if [ -f "$TMPDIR/isolinux/txt.cfg" ]; then
            sed -i 's|---$|autoinstall ds=nocloud;s=/cdrom/ ---|g' "$TMPDIR/isolinux/txt.cfg"
        fi
        if [ -f "$TMPDIR/boot/grub/loopback.cfg" ]; then
            sed -i 's|---$|autoinstall ds=nocloud\\;s=/cdrom/ ---|g' "$TMPDIR/boot/grub/loopback.cfg"
        fi
    fi

    # Verify modification
    if grep -q 'autoinstall.*ds=nocloud' "$grub_cfg"; then
        log "GRUB modification verified"
    else
        log "WARNING: GRUB modification may not have applied correctly"
        log "Content of grub.cfg kernel lines:"
        grep -E 'linux.*vmlinuz' "$grub_cfg" | head -3
    fi
}

# ============================================================================
# Add Autoinstall Configuration
# ============================================================================

add_autoinstall_config() {
    log "=== Adding autoinstall configuration ==="

    # Verify user-data exists
    if [ ! -f "$USER_DATA" ]; then
        die "user-data not found: $USER_DATA"
    fi

    # Copy user-data to ISO root
    cp "$USER_DATA" "$TMPDIR/user-data"
    log "Added user-data to ISO root"

    # Create meta-data
    local instance_id="autoinstall-$(date +%Y%m%d%H%M%S)"
    echo "instance-id: $instance_id" > "$TMPDIR/meta-data"
    log "Created meta-data with instance-id: $instance_id"

    # Verify files are in place
    if [ -f "$TMPDIR/user-data" ] && [ -f "$TMPDIR/meta-data" ]; then
        log "Autoinstall configuration added successfully"
    else
        die "Failed to add autoinstall configuration"
    fi
}

# ============================================================================
# Update Checksums
# ============================================================================

update_checksums() {
    log "=== Updating MD5 checksums ==="

    local md5file="$TMPDIR/md5sum.txt"

    if [ ! -f "$md5file" ]; then
        log "WARNING: md5sum.txt not found, skipping checksum update"
        return
    fi

    cd "$TMPDIR"

    # Remove old entries for files we modified/added
    sed -i '/boot\/grub\/grub.cfg/d' md5sum.txt 2>/dev/null || true
    sed -i '/user-data/d' md5sum.txt 2>/dev/null || true
    sed -i '/meta-data/d' md5sum.txt 2>/dev/null || true

    # Add new checksums
    if [ -f "./boot/grub/grub.cfg" ]; then
        md5sum ./boot/grub/grub.cfg >> md5sum.txt
    fi
    if [ -f "./user-data" ]; then
        md5sum ./user-data >> md5sum.txt
    fi
    if [ -f "./meta-data" ]; then
        md5sum ./meta-data >> md5sum.txt
    fi

    # For focal, also update loopback.cfg
    if [ "$RELEASE" = "focal" ] && [ -f "./boot/grub/loopback.cfg" ]; then
        sed -i '/boot\/grub\/loopback.cfg/d' md5sum.txt 2>/dev/null || true
        md5sum ./boot/grub/loopback.cfg >> md5sum.txt
    fi

    cd "$OLDPWD"
    log "Checksums updated"
}

# ============================================================================
# Repackage ISO
# ============================================================================

repackage_iso() {
    log "=== Repackaging ISO ==="

    # Remove any existing output ISO
    rm -f "$OUTPUT_ISO"

    cd "$TMPDIR"

    if [ "$RELEASE" = "focal" ]; then
        # Focal (20.04) uses isolinux for BIOS boot
        xorriso -as mkisofs -r \
            -V "ubuntu-autoinstall-${RELEASE}" \
            -J -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
            -boot-info-table \
            -input-charset utf-8 \
            -eltorito-alt-boot \
            -e boot/grub/efi.img \
            -no-emul-boot \
            -isohybrid-gpt-basdat \
            -o "$OUTPUT_ISO" \
            .
    else
        # Jammy (22.04) and Noble (24.04) use GRUB2 for both BIOS and UEFI
        # Requires the preserved [BOOT] directory
        if [ ! -d "$BOOTDIR/BOOT" ]; then
            die "BOOT directory not found - cannot repackage ISO"
        fi

        xorriso -as mkisofs -r \
            -V "ubuntu-autoinstall-${RELEASE}" \
            -o "$OUTPUT_ISO" \
            --grub2-mbr "$BOOTDIR/BOOT/1-Boot-NoEmul.img" \
            -partition_offset 16 \
            --mbr-force-bootable \
            -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$BOOTDIR/BOOT/2-Boot-NoEmul.img" \
            -appended_part_as_gpt \
            -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
            -c '/boot.catalog' \
            -b '/boot/grub/i386-pc/eltorito.img' \
            -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
            -eltorito-alt-boot \
            -e '--interval:appended_partition_2:::' \
            -no-emul-boot \
            .
    fi

    cd "$OLDPWD"

    if [ -f "$OUTPUT_ISO" ]; then
        log "ISO created: $OUTPUT_ISO"
        log "Size: $(ls -lh "$OUTPUT_ISO" | awk '{print $5}')"
    else
        die "Failed to create ISO"
    fi
}

# ============================================================================
# Verification
# ============================================================================

verify_output_iso() {
    log "=== Verifying output ISO ==="

    # Check ISO exists and has reasonable size
    if [ ! -f "$OUTPUT_ISO" ]; then
        die "Output ISO not found"
    fi

    local iso_size
    iso_size=$(stat -f%z "$OUTPUT_ISO" 2>/dev/null || stat -c%s "$OUTPUT_ISO" 2>/dev/null)
    if [ "$iso_size" -lt 1000000000 ]; then
        log "WARNING: ISO seems small ($(ls -lh "$OUTPUT_ISO" | awk '{print $5}'))"
    fi

    # Verify user-data is at root
    local has_userdata
    has_userdata=$(xorriso -indev "$OUTPUT_ISO" -find / -name user-data 2>/dev/null | grep -c user-data || echo "0")
    if [ "$has_userdata" -gt 0 ]; then
        log "Verified: user-data present in ISO"
    else
        die "user-data not found in output ISO"
    fi

    # Verify GRUB has autoinstall parameter
    local grub_check
    grub_check=$(xorriso -osirrox on -indev "$OUTPUT_ISO" -extract /boot/grub/grub.cfg /tmp/grub-verify.cfg 2>/dev/null && \
                 grep -c 'autoinstall.*ds=nocloud' /tmp/grub-verify.cfg || echo "0")
    rm -f /tmp/grub-verify.cfg

    if [ "$grub_check" -gt 0 ]; then
        log "Verified: GRUB has autoinstall parameters"
    else
        log "WARNING: Could not verify GRUB autoinstall parameters"
    fi

    log "ISO verification complete"
}

# ============================================================================
# Main
# ============================================================================

main() {
    log "=============================================="
    log " Ubuntu Autoinstall ISO Builder"
    log " Modified ISO Method (embedded user-data)"
    log "=============================================="
    log ""
    log "Release:     $RELEASE"
    log "Type:        $TYPE"
    log "Arch:        $ARCH"
    log "User-data:   $USER_DATA"
    log "Output:      $OUTPUT_ISO"
    log ""

    # Check user-data exists before starting
    if [ ! -f "$USER_DATA" ]; then
        die "user-data not found: $USER_DATA\nRun 'make autoinstall' first to generate it."
    fi

    install_deps

    local iso_url
    iso_url=$(get_iso_url)

    local source_iso
    source_iso=$(download_iso "$iso_url")

    # Optional: verify ISO integrity
    # verify_iso "$source_iso"

    extract_iso "$source_iso"
    modify_grub
    add_autoinstall_config
    update_checksums
    repackage_iso
    verify_output_iso

    log ""
    log "=============================================="
    log " Build Complete"
    log "=============================================="
    log ""
    log "Output ISO: $OUTPUT_ISO"
    log ""
    log "This ISO contains embedded autoinstall configuration."
    log "No separate CIDATA disk is needed."
    log ""
    log "To transfer ISO to Windows host:"
    log "  multipass transfer {{ image.vm_name }}:$OUTPUT_ISO ./output/"
    log ""
    log "To test in VirtualBox:"
    log "  1. Create VM with EFI firmware"
    log "  2. Attach this ISO as the only optical drive"
    log "  3. Boot - installation will proceed automatically"
    log ""
}

main "$@"
