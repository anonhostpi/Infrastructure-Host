# 6.8 Virtualization Fragment

**Template:** `src/autoinstall/cloud-init/60-virtualization.yaml.tpl`

Configures KVM/libvirt virtualization and multipass.

## Template

```yaml
packages:
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - virtinst

snap:
  commands:
    - snap install multipass

runcmd:
  # Enable and start libvirtd
  - systemctl enable libvirtd
  - systemctl start libvirtd
  # Add user to virtualization groups
  - usermod -aG libvirt {{ identity.username }}
  - usermod -aG kvm {{ identity.username }}
  # Configure default network
  - virsh net-autostart default
  - virsh net-start default || true
```

## Packages

| Package | Purpose |
|---------|---------|
| `qemu-kvm` | KVM hypervisor |
| `libvirt-daemon-system` | libvirt daemon and system integration |
| `libvirt-clients` | virsh and other management tools |
| `virtinst` | virt-install for VM creation |

## Snap Packages

| Snap | Purpose |
|------|---------|
| `multipass` | Ubuntu VM management (for testing) |

## User Groups

The admin user is added to virtualization groups:

| Group | Purpose |
|-------|---------|
| `libvirt` | Access to libvirt daemon |
| `kvm` | Direct access to /dev/kvm |

This allows the user to manage VMs without sudo.

## Default Network

libvirt creates a default NAT network (`virbr0`). The template:

1. Enables autostart on boot
2. Starts the network (ignoring errors if already running)

```bash
virsh net-autostart default
virsh net-start default || true
```

The `|| true` prevents cloud-init failure if the network is already started.

## Verification

After deployment, verify virtualization is working:

```bash
# Check libvirtd status
systemctl status libvirtd

# List networks
virsh net-list --all

# Check KVM support
kvm-ok

# List VMs (should be empty initially)
virsh list --all
```

## VM Storage

Default VM storage is at `/var/lib/libvirt/images/`. This uses the ZFS root filesystem configured during autoinstall.

For production, consider:
- Dedicated ZFS dataset for VM images
- Separate storage pool in libvirt
