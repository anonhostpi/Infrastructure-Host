# 5.1 Download Ubuntu Server ISO

## image.config.yaml

Configure the Ubuntu release and architecture in `src/config/image.config.yaml`:

```yaml
image:
  release: noble        # Ubuntu codename (noble=24.04, jammy=22.04)
  type: live-server     # Image type
  arch: amd64           # Architecture
```

This config is used by the build system to render `build-iso.sh` from its template. See [5.3 Bootable Media Creation](./TESTED_BOOTABLE_MEDIA_CREATION.md) for the build workflow.

| Field | Description | Options |
|-------|-------------|---------|
| `release` | Ubuntu release codename | `noble` (24.04), `jammy` (22.04) |
| `type` | Image type | `live-server` |
| `arch` | CPU architecture | `amd64`, `arm64` |

## Using ubuntu-cloudimg-query (Recommended)

The `ubuntu-cloudimg-query` tool automatically finds the latest image URL:

```bash
# Install cloud-image-utils
sudo apt install cloud-image-utils

# Query for latest Ubuntu 24.04 live server ISO URL
ISO_URL=$(ubuntu-cloudimg-query noble live-server amd64 --format "%{url}\n")
echo "ISO URL: $ISO_URL"

# Download the ISO
wget -q --show-progress "$ISO_URL" -O ubuntu-live-server.iso
```

### Query Options

| Release | Codename | Command |
|---------|----------|---------|
| 24.04 LTS | noble | `ubuntu-cloudimg-query noble live-server amd64` |
| 22.04 LTS | jammy | `ubuntu-cloudimg-query jammy live-server amd64` |

### Available Formats

```bash
# Get just the URL
ubuntu-cloudimg-query noble live-server amd64 --format "%{url}\n"

# Get filename
ubuntu-cloudimg-query noble live-server amd64 --format "%{filename}\n"

# Get SHA256 checksum
ubuntu-cloudimg-query noble live-server amd64 --format "%{sha256}\n"
```

## Manual Download (Alternative)

```bash
# Download directly from releases.ubuntu.com
wget https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso

# Verify checksum
wget https://releases.ubuntu.com/24.04/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep OK
```

**Note:** Ubuntu releases point updates (24.04.1, 24.04.2, 24.04.3, etc.). The `ubuntu-cloudimg-query` tool automatically finds the latest.

## Download Links

| Version | Release | Download |
|---------|---------|----------|
| 24.04 LTS | Noble Numbat | [Download](https://releases.ubuntu.com/24.04/) |
| 22.04 LTS | Jammy Jellyfish | [Download](https://releases.ubuntu.com/22.04/) |

## Verification

Always verify the ISO checksum before use:

```bash
# Download checksums and signature
wget https://releases.ubuntu.com/24.04/SHA256SUMS
wget https://releases.ubuntu.com/24.04/SHA256SUMS.gpg

# Verify GPG signature (optional but recommended)
gpg --keyid-format long --verify SHA256SUMS.gpg SHA256SUMS

# Verify ISO checksum
sha256sum -c SHA256SUMS 2>&1 | grep ubuntu-24.04.3-live-server-amd64.iso
```

Expected output: `ubuntu-24.04.3-live-server-amd64.iso: OK`
