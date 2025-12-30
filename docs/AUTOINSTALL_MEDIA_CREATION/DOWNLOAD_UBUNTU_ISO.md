# 4.1 Download Ubuntu Server ISO

## Download Commands

```bash
# Download Ubuntu 24.04 LTS Server (use latest point release)
# Check https://releases.ubuntu.com/24.04/ for current version (e.g., 24.04.3)
wget https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso

# Verify checksum
wget https://releases.ubuntu.com/24.04/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep OK
```

**Note:** Ubuntu releases point updates (24.04.1, 24.04.2, 24.04.3, etc.) with security patches and updated packages. Always download the latest point release available.

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
