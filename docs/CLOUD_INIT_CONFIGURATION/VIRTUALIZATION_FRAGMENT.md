# 6.10 Virtualization Fragment

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

# Verify multipass installation
multipass version

# List multipass instances (should be empty initially)
multipass list

# Test multipass can launch a VM
multipass launch --name test-vm
multipass exec test-vm -- uname -a
multipass delete test-vm && multipass purge
```

## VM Storage

Default VM storage is at `/var/lib/libvirt/images/`. This uses the ZFS root filesystem configured during autoinstall.

For production, consider:
- Dedicated ZFS dataset for VM images
- Separate storage pool in libvirt

## VM Lifecycle Notifications

Send email alerts when VMs start, stop, or crash. Requires msmtp from [6.7 MSMTP Fragment](./MSMTP_FRAGMENT.md).

### libvirt Hook Script

libvirt supports hook scripts that run on VM lifecycle events:

```yaml
write_files:
  - path: /etc/libvirt/hooks/qemu
    permissions: '0755'
    content: |
      #!/bin/bash
      # libvirt QEMU hook for VM lifecycle notifications
      # Arguments: $1=VM name, $2=operation, $3=sub-operation

      VM_NAME="$1"
      OPERATION="$2"
      SUB_OPERATION="$3"
      HOSTNAME=$(hostname)
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      RECIPIENT=$(grep "^root:" /etc/aliases 2>/dev/null | cut -d: -f2 | tr -d ' ')

      # Only notify on these events
      case "$OPERATION/$SUB_OPERATION" in
        start/begin)
          SUBJECT="[${HOSTNAME}] VM Started: ${VM_NAME}"
          BODY="Virtual machine '${VM_NAME}' has started.\n\nTimestamp: ${TIMESTAMP}\nHost: ${HOSTNAME}"
          ;;
        stopped/end)
          SUBJECT="[${HOSTNAME}] VM Stopped: ${VM_NAME}"
          BODY="Virtual machine '${VM_NAME}' has stopped.\n\nTimestamp: ${TIMESTAMP}\nHost: ${HOSTNAME}"
          ;;
        reconnect/begin)
          SUBJECT="[${HOSTNAME}] VM Reconnected: ${VM_NAME}"
          BODY="Virtual machine '${VM_NAME}' reconnected after libvirtd restart.\n\nTimestamp: ${TIMESTAMP}\nHost: ${HOSTNAME}"
          ;;
        *)
          # Don't notify for other events (prepare, release, migrate, etc.)
          exit 0
          ;;
      esac

      # Send notification if msmtp is configured
      if [ -n "$RECIPIENT" ] && [ -f /etc/msmtp-password ]; then
        echo -e "Subject: ${SUBJECT}\n\n${BODY}" | msmtp "$RECIPIENT" 2>/dev/null || true
      fi

      exit 0
```

### Hook Events

| Event | Trigger | Notification |
|-------|---------|--------------|
| `start/begin` | VM is starting | Yes |
| `stopped/end` | VM has stopped (any reason) | Yes |
| `reconnect/begin` | libvirtd reconnects to running VM | Yes |
| `prepare/begin` | Before VM starts | No |
| `release/end` | After VM resources released | No |
| `migrate/*` | Migration events | No |

### Crash Detection

The `stopped/end` event fires regardless of how the VM stopped:
- Clean shutdown
- Forced stop (`virsh destroy`)
- Guest crash
- Host crash recovery

For more granular crash detection, check the domain state:

```bash
# In hook script, after stopped/end
STATE=$(virsh domstate "$VM_NAME" 2>/dev/null)
if [ "$STATE" = "crashed" ]; then
  SUBJECT="[${HOSTNAME}] VM CRASHED: ${VM_NAME}"
fi
```

### Testing Hooks

```bash
# Test the hook script manually
sudo /etc/libvirt/hooks/qemu test-vm start begin

# Start a VM and check for email
virsh start my-vm

# Check msmtp log
cat /var/log/msmtp.log
```

### Disabling Notifications

To disable notifications for a specific VM, add a condition:

```bash
# Skip notification for certain VMs
case "$VM_NAME" in
  test-*|temp-*)
    exit 0
    ;;
esac
```

---

## Systemd Hardening (Optional)

For additional security, add systemd hardening via drop-in file:

```yaml
write_files:
  - path: /etc/systemd/system/libvirtd.service.d/hardening.conf
    permissions: '0644'
    content: |
      [Service]
      NoNewPrivileges=true
      PrivateTmp=true
      ProtectHome=true
      ProtectClock=true
      ProtectHostname=true
      ProtectKernelTunables=true
      ProtectKernelModules=true
      ProtectControlGroups=true
      RestrictSUIDSGID=true
      RestrictRealtime=true
      LockPersonality=true

      # libvirtd needs these paths writable
      ReadWritePaths=/var/lib/libvirt /var/log/libvirt /run/libvirt

runcmd:
  - systemctl daemon-reload
```

**Note:** libvirtd requires more capabilities than typical services for VM management. Test thoroughly before enabling in production. Some settings may need adjustment based on VM requirements.

### Hardening Options

| Setting | Purpose |
|---------|---------|
| `NoNewPrivileges` | Prevent privilege escalation |
| `PrivateTmp` | Isolated /tmp directory |
| `ProtectHome` | No access to /home |
| `ProtectClock` | No system clock changes |
| `ProtectKernelTunables` | No sysctl changes |
| `ProtectKernelModules` | No module loading |
| `ReadWritePaths` | Explicit write access for libvirt |
