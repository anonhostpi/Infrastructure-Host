# 4.2 Autoinstall Configuration

Autoinstall uses a `user-data` file for installation automation.

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
      name: lvm
      sizing-policy: all

  # Identity (temporary, will be managed by cloud-init)
  identity:
    hostname: ubuntu-server
    username: installer
    password: "$6$rounds=4096$saltsaltexample$hashedpasswordhere"
    # Generate with: mkpasswd -m sha-512

  # SSH server
  ssh:
    install-server: true
    allow-pw: true

  # Packages to install during installation
  packages:
    - cloud-init
    - qemu-guest-agent

  # Late commands (runs at end of installation)
  late-commands:
    - curtin in-target --target=/target -- systemctl enable cloud-init
    - curtin in-target --target=/target -- systemctl enable ssh

  # Reboot after installation
  shutdown: reboot
```

## Generate Password Hash

```bash
# Generate a password hash for the identity section
mkpasswd -m sha-512
```

## Storage Layout Options

| Layout | Description |
|--------|-------------|
| `lvm` | LVM with single volume group |
| `direct` | Direct partitioning without LVM |
| `zfs` | ZFS root filesystem |

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

### Additional Packages

```yaml
packages:
  - cloud-init
  - qemu-guest-agent
  - openssh-server
  - vim
  - htop
```
