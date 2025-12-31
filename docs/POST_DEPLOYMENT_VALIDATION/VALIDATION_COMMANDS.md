# 8.2 Validation Commands

## Validation Script

```bash
#!/bin/bash
# System validation script

echo "=== System Information ==="
hostnamectl
echo ""

echo "=== Network Configuration ==="
ip addr show
ip route show
echo ""

echo "=== DNS Resolution ==="
resolvectl status
nslookup google.com
echo ""

echo "=== Virtualization Support ==="
echo "CPU virtualization: $(egrep -c '(vmx|svm)' /proc/cpuinfo) cores with VT"
lsmod | grep kvm
virsh version
echo ""

echo "=== Services Status ==="
systemctl status libvirtd --no-pager
systemctl status cockpit.socket --no-pager
systemctl status docker --no-pager
echo ""

echo "=== Cockpit Access ==="
echo "Cockpit URL: https://$(hostname -I | awk '{print $1}'):9090"
echo ""

echo "=== Cloud-init Status ==="
cloud-init status
echo ""

echo "Validation complete!"
```

## Individual Validation Commands

### System Information
```bash
hostnamectl
uname -a
cat /etc/os-release
```

### Network Validation
```bash
ip addr show
ip route show
cat /etc/netplan/*.yaml
resolvectl status
```

### Service Status
```bash
systemctl status libvirtd
systemctl status cockpit.socket
systemctl status docker
systemctl status ssh
```

### Virtualization Validation
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
lsmod | grep kvm
virsh list --all
virsh net-list --all
virt-host-validate
```

### User Validation
```bash
id admin
groups admin
sudo -l -U admin
```

### Firewall Status
```bash
sudo ufw status verbose
sudo ufw status numbered
```
