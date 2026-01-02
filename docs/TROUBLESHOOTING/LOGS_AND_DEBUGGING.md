# 10.2 Logs and Debugging

## Key Log Files

```bash
# Cloud-init logs
/var/log/cloud-init.log          # Detailed cloud-init execution
/var/log/cloud-init-output.log   # Output from scripts and commands

# Installation logs
/var/log/installer/              # Autoinstall logs

# System logs
journalctl -u cloud-init         # Cloud-init service logs
journalctl -u cockpit            # Cockpit logs
journalctl -u libvirtd           # Libvirt logs
```

## Debug Cloud-init

```bash
# Run cloud-init in debug mode
sudo cloud-init init --debug

# Analyze cloud-init run
sudo cloud-init analyze show

# Dump cloud-init data
sudo cloud-init query -a

# Show cloud-init status
cloud-init status --long
```

## View Specific Logs

```bash
# Cloud-init errors only
sudo grep -i error /var/log/cloud-init.log

# Cloud-init warnings
sudo grep -i warn /var/log/cloud-init.log

# Recent cloud-init activity
sudo tail -100 /var/log/cloud-init.log

# Follow logs in real-time
sudo tail -f /var/log/cloud-init-output.log
```

## System Logs

```bash
# General system log
journalctl -xe

# Boot messages
journalctl -b

# Specific service logs
journalctl -u ssh
journalctl -u libvirtd
journalctl -u docker
```

## Network Debugging

```bash
# Check interface configuration
ip addr show
ip route show

# Test connectivity
ping -c 3 gateway_ip
ping -c 3 8.8.8.8

# DNS resolution
nslookup google.com
resolvectl status

# Netplan configuration
cat /etc/netplan/*.yaml
sudo netplan try
```

## Re-running Cloud-init

If you need to re-apply cloud-init configuration:

```bash
# Clean cloud-init state
sudo cloud-init clean

# Re-run all stages
sudo cloud-init init
sudo cloud-init modules --mode config
sudo cloud-init modules --mode final

# Or reboot
sudo reboot
```
