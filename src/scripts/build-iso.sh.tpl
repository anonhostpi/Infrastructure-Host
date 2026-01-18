#!/bin/bash
# build-iso.sh - Build autoinstall ISO and/or CIDATA ISO
# Run inside multipass VM: ./output/scripts/build-iso.sh [cidata|autoinstall|all]
# Generated from build-iso.sh.tpl - do not edit directly
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-all}"

# Image settings from image.config.yaml
RELEASE="{{ image.release }}"
TYPE="{{ image.type }}"
ARCH="{{ image.arch }}"

# Output paths (directly in output directory)
CIDATA_ISO="$SCRIPT_DIR/cidata.iso"
AUTOINSTALL_ISO="$SCRIPT_DIR/ubuntu-autoinstall.iso"

install_deps() {
    echo "=== Installing dependencies ==="
    sudo apt-get update -qq
    sudo apt-get install -y -qq xorriso cloud-image-utils wget distro-info
}

build_cidata() {
    echo "=== Building CIDATA ISO ==="
    # Ubuntu 24.04 requires a separate disk labeled CIDATA for cloud-init nocloud datasource

    # Create meta-data for cloud-localds
    META_DATA=$(mktemp)
    echo "instance-id: autoinstall-001" > "$META_DATA"

    # cloud-localds creates proper nocloud seed with correct format
    cloud-localds "$CIDATA_ISO" "$SCRIPT_DIR/user-data" "$META_DATA"
    rm -f "$META_DATA"

    echo "CIDATA ISO: $CIDATA_ISO"
    ls -lh "$CIDATA_ISO"
}

build_autoinstall() {
    echo "=== Building autoinstall ISO ==="

    # Create GRUB config
    mkdir -p "$HOME/grub_mod"
    cat > "$HOME/grub_mod/grub.cfg" << 'GRUBEOF'
set timeout=5
set default=0
loadfont unicode
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Autoinstall Ubuntu Server" {
    set gfxpayload=keep
    linux /casper/vmlinuz quiet autoinstall ---
    initrd /casper/initrd
}

menuentry "Ubuntu Server (Manual Install)" {
    set gfxpayload=keep
    linux /casper/vmlinuz ---
    initrd /casper/initrd
}
GRUBEOF

    # Query latest Ubuntu ISO
    echo "Querying latest Ubuntu ISO..."
    if [ "$TYPE" = "live-server" ]; then
        # Live-server ISOs are on releases.ubuntu.com, not cloud-images
        # ubuntu-cloudimg-query doesn't support live-server, so we query dynamically

        # Get base version from codename (e.g., noble -> 24.04)
        BASE_VERSION=$(ubuntu-distro-info --series="$RELEASE" -r 2>/dev/null | cut -d' ' -f1)
        if [ -z "$BASE_VERSION" ]; then
            BASE_VERSION="$RELEASE"
        fi

        # Find latest point release from releases.ubuntu.com
        VERSION=$(curl -sL "https://releases.ubuntu.com/" | grep -oE "href=\"${BASE_VERSION}(\.[0-9]+)?/\"" | sed 's/href="//;s/\/"$//' | sort -V | tail -1)
        if [ -z "$VERSION" ]; then
            VERSION="$BASE_VERSION"
        fi

        # Scrape actual ISO filename from directory listing
        ISO_NAME=$(curl -sL "https://releases.ubuntu.com/${VERSION}/" | grep -oE "href=\"[^\"]+live-server[^\"]+\.iso\"" | sed 's/href="//;s/"$//' | grep "$ARCH" | head -1)
        if [ -z "$ISO_NAME" ]; then
            echo "ERROR: Could not find live-server ISO for ${VERSION} ${ARCH}"
            exit 1
        fi
        ISO_URL="https://releases.ubuntu.com/${VERSION}/${ISO_NAME}"
    else
        # Use ubuntu-cloudimg-query for cloud images
        ISO_URL=$(ubuntu-cloudimg-query "$RELEASE" "$TYPE" "$ARCH" --format "%{url}\n")
    fi
    echo "ISO URL: $ISO_URL"

    # Download Ubuntu ISO directly to output
    echo "Downloading Ubuntu ISO..."
    wget -q --show-progress "$ISO_URL" -O "$AUTOINSTALL_ISO"
    echo "Downloaded: $(ls -lh "$AUTOINSTALL_ISO" | awk '{print $5}')"

    # Modify ISO in-place with xorriso
    echo "Modifying ISO with custom GRUB config..."
    xorriso -dev "$AUTOINSTALL_ISO" \
        -boot_image any keep \
        -update "$HOME/grub_mod/grub.cfg" /boot/grub/grub.cfg \
        -update "$HOME/grub_mod/grub.cfg" /EFI/boot/grub.cfg \
        -commit

    echo "Autoinstall ISO: $AUTOINSTALL_ISO"
    ls -lh "$AUTOINSTALL_ISO"
}

# Main
install_deps

case "$TARGET" in
    cidata)
        build_cidata
        ;;
    autoinstall)
        build_autoinstall
        ;;
    all)
        build_cidata
        build_autoinstall
        ;;
    *)
        echo "Usage: $0 [cidata|autoinstall|all]"
        exit 1
        ;;
esac

echo "=== Build complete ==="
