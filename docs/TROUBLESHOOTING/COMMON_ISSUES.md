# 9.1 Common Issues

## Autoinstall Not Starting

**Symptoms:** Manual installer appears instead of autoinstall

**Solutions:**
- Verify boot parameters include `autoinstall ds=nocloud`
- Check that `user-data` and `meta-data` files exist in correct location
- Use Shift/Esc during boot to access GRUB menu manually
- Verify ISO was rebuilt correctly with autoinstall files

## Network Not Configured After Installation

**Symptoms:** No network connectivity, arping detection failed

**Solutions:**
- Check `/var/log/cloud-init.log` for arping/network errors
- Verify gateway and DNS IPs are correct and reachable
- Verify arping is available: `which arping`
- Check interface names: `ip link show`
- Manually test arping: `arping -c 2 -I <interface> <gateway>`
- Check netplan config: `cat /etc/netplan/90-static.yaml`
- Manually apply with `sudo netplan apply`

## Cloud-init Not Running

**Symptoms:** Configuration not applied, users not created

**Solutions:**
- Check datasource detection: `cloud-init query -a`
- Verify cloud-init enabled: `systemctl status cloud-init`
- Re-run cloud-init: `sudo cloud-init clean && sudo cloud-init init`
- Check for seed files: `ls -la /var/lib/cloud/seed/`

## Cockpit Not Accessible

**Symptoms:** Cannot connect to port 9090

**Solutions:**
- Check service status: `systemctl status cockpit.socket`
- Verify firewall: `sudo ufw status | grep 9090`
- Check listening ports: `sudo ss -tlnp | grep 9090`
- Restart service: `sudo systemctl restart cockpit.socket`

## Virtualization Not Working

**Symptoms:** Cannot start VMs, KVM errors

**Solutions:**
- Verify BIOS settings (VT-x/AMD-V enabled)
- Check kernel modules: `lsmod | grep kvm`
- Verify CPU support: `egrep -c '(vmx|svm)' /proc/cpuinfo`
- Run validation: `virt-host-validate`

## SSH Access Denied

**Symptoms:** Cannot SSH to server

**Solutions:**
- Verify SSH service running: `systemctl status ssh`
- Check firewall allows SSH: `ufw status | grep 22`
- Verify user exists: `id admin`
- Check SSH key in authorized_keys: `cat ~/.ssh/authorized_keys`
- Check `/etc/ssh/sshd_config` for configuration issues
