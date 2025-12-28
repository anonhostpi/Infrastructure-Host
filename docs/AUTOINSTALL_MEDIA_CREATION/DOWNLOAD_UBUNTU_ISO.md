# 4.1 Download Ubuntu Server ISO

## Download Commands

```bash
# Download Ubuntu 24.04 LTS Server (example)
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Verify checksum
wget https://releases.ubuntu.com/24.04/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep OK
```

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
sha256sum -c SHA256SUMS 2>&1 | grep ubuntu-24.04-live-server-amd64.iso
```

Expected output: `ubuntu-24.04-live-server-amd64.iso: OK`
