# 4.2 Autoinstall Configuration

Autoinstall uses a `user-data` file for installation automation. This configuration is intentionally minimal - it only installs the base OS with cloud-init. User setup, packages, and services are configured via cloud-init (see Chapter 5).

**Configuration Files:** Replace placeholders with values from:
- [network.config.yaml](../../network.config.yaml) - Hostname, IPs, gateway, DNS

## Directory Structure

```bash
mkdir -p autoinstall/nocloud
cd autoinstall/nocloud
```

## Create meta-data

Create an empty `meta-data` file (required but can be empty):

```bash
touch meta-data
```

## Create user-data

Create `user-data` with your autoinstall configuration:

```yaml
#cloud-config
autoinstall:
  version: 1

  # Locale and keyboard
  locale: en_US.UTF-8
  keyboard:
    layout: us

  # Network: disabled here - configured via early-commands using arping
  # This avoids DHCP broadcast and uses the same secure approach as cloud-init
  # See Chapter 3: NETWORK_PLANNING/CLOUD_INIT_NETWORK_CONFIG.md
  network:
    version: 2
    renderer: networkd

  # Secure network detection via ARP probing (runs before installation)
  # arping is available via busybox in the live installer
  early-commands:
    - |
      GATEWAY="<GATEWAY>"
      DNS_PRIMARY="<DNS_PRIMARY>"
      STATIC_IP="<HOST_IP>"
      CIDR="<CIDR>"

      for iface in /sys/class/net/e*; do
        NIC=$(basename "$iface")
        [ "$NIC" = "lo" ] && continue

        ip link set "$NIC" up
        sleep 2

        if ! arping -c 2 -w 3 -I "$NIC" "$GATEWAY" >/dev/null 2>&1; then
          ip link set "$NIC" down
          continue
        fi

        if ! arping -c 2 -w 3 -I "$NIC" "$DNS_PRIMARY" >/dev/null 2>&1; then
          ip link set "$NIC" down
          continue
        fi

        ip addr add "$STATIC_IP/$CIDR" dev "$NIC"
        ip route add default via "$GATEWAY" dev "$NIC"
        echo "nameserver $DNS_PRIMARY" > /etc/resolv.conf
        break
      done

  # Storage configuration
  storage:
    layout:
      name: zfs
      sizing-policy: all

  # Temporary installer identity (cloud-init creates the real user)
  # Password "install" hashed with: openssl passwd -6 -salt xyz install
  identity:
    hostname: <HOSTNAME>
    username: installer
    password: "$6$xyz$AxH4K0XL6J7rLB6x4GjxT1bfF9cXWlVN5dFvLMJ4x3GpZ0vKjG0z6NjUqQpT9s5L4aH8zV7xS2wR4yE6uI8oO0"

  # SSH server
  ssh:
    install-server: true
    allow-pw: true

  # Packages to install during installation
  packages:
    - cloud-init

  # Late commands (runs at end of installation)
  # WARNING: Do NOT use inline comments in late-commands list items
  late-commands:
    - curtin in-target --target=/target -- systemctl enable cloud-init
    - curtin in-target --target=/target -- systemctl enable ssh

  # Reboot after installation
  shutdown: reboot
```

## YAML Formatting Notes

**Critical:** Avoid inline comments within list items in `late-commands`. This causes YAML parsing errors:

```yaml
# WRONG - will cause "Malformed autoinstall" error
late-commands:
  - echo 'done' > /target/var/log/install.log  # This comment breaks it

# CORRECT
late-commands:
  - echo 'done' > /target/var/log/install.log
```

## Installer Account

The `installer` user is temporary - only used to bootstrap the system. Cloud-init creates the real admin user on first boot (see [5.1 Configuration Structure](../CLOUD_INIT_CONFIGURATION/CONFIGURATION_STRUCTURE.md)).

To generate a different installer password:
```bash
openssl passwd -6 -salt xyz yourpassword
```

## Storage Layout Options

| Layout | Description |
|--------|-------------|
| `zfs` | ZFS root filesystem (recommended for virtualization hosts) |
| `lvm` | LVM with single volume group |
| `direct` | Direct partitioning without LVM |

ZFS provides advantages for virtualization hosts:
- Native snapshots for VM backups
- Data checksumming prevents silent corruption
- Built-in compression saves storage
- zvols for efficient VM disk storage

## Common Customizations

### Custom Partitioning

```yaml
storage:
  config:
    - type: disk
      id: disk0
      ptable: gpt
      wipe: superblock
      grub_device: true
    - type: partition
      id: efi-partition
      device: disk0
      size: 512M
      flag: boot
      grub_device: true
    - type: partition
      id: root-partition
      device: disk0
      size: -1
```

### Packages

Keep autoinstall packages minimal - only `cloud-init` is required:

```yaml
packages:
  - cloud-init
```

All other packages (openssh-server, vim, htop, etc.) should be installed via cloud-init configuration. See Chapter 5 for the full package list.

## Placeholder Reference

| Placeholder | Source | Description |
|-------------|--------|-------------|
| `<HOSTNAME>` | network.config.yaml | System hostname |
| `<HOST_IP>` | network.config.yaml | Static IP address |
| `<CIDR>` | network.config.yaml | Network prefix length |
| `<GATEWAY>` | network.config.yaml | Default gateway IP |
| `<DNS_PRIMARY>` | network.config.yaml | Primary DNS server |
