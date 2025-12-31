# 12.2 Useful Commands

## Password Generation

```bash
# Generate password hash for autoinstall
mkpasswd -m sha-512
```

## Cloud-init Commands

```bash
# Test cloud-init config syntax
cloud-init schema --config-file user-data

# List available cloud-init modules
cloud-init list

# Query cloud-init data
cloud-init query -a

# Check cloud-init status
cloud-init status

# Re-run cloud-init
cloud-init clean
cloud-init init
```

## Network Commands

```bash
# Check network configuration
netplan get
netplan try  # Test configuration with auto-rollback

# Apply network changes
sudo netplan apply

# Show interfaces
ip addr show
ip link show
```

## Virtualization Commands

```bash
# Verify virtualization
virt-host-validate

# Check KVM modules
lsmod | grep kvm

# List VMs
virsh list --all

# List networks
virsh net-list --all
```

## System Information

```bash
# System details
hostnamectl

# CPU info
lscpu

# Memory info
free -h

# Disk info
lsblk
df -h
```

## Service Management

```bash
# Check service status
systemctl status <service>

# Start/stop/restart service
systemctl start <service>
systemctl stop <service>
systemctl restart <service>

# Enable/disable service at boot
systemctl enable <service>
systemctl disable <service>
```
