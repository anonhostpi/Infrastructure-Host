# 9.1 System Validation Checklist

## Basic System

- [ ] System boots successfully
- [ ] Hostname configured correctly: `hostnamectl`
- [ ] Network configured with static IP: `ip addr show`
- [ ] Default gateway reachable: `ping -c 3 <GATEWAY>`
- [ ] DNS resolution working: `nslookup google.com`
- [ ] Timezone correct: `timedatectl`

## Users and SSH

- [ ] Admin user created: `id admin`
- [ ] SSH key authentication working: `ssh admin@<host-ip>`
- [ ] Password authentication disabled: `sudo grep PasswordAuthentication /etc/ssh/sshd_config`
- [ ] Sudo access working: `sudo whoami`

## Virtualization

- [ ] KVM modules loaded: `lsmod | grep kvm`
- [ ] Virtualization enabled in CPU: `egrep -c '(vmx|svm)' /proc/cpuinfo` (should be > 0)
- [ ] Libvirt running: `systemctl status libvirtd`
- [ ] Default network active: `virsh net-list --all`
- [ ] Admin user in libvirt group: `groups admin | grep libvirt`

## Cockpit

- [ ] Cockpit service running: `systemctl status cockpit.socket`
- [ ] Cockpit listening on localhost: `ss -tlnp | grep 443` (should show 127.0.0.1:443)
- [ ] Cockpit accessible via SSH tunnel:
  ```bash
  ssh -L 9090:127.0.0.1:443 admin@<host-ip>
  # Then open https://localhost:9090
  ```
- [ ] Login with admin user credentials
- [ ] Verify modules loaded (Machines, Network)

## Firewall

- [ ] UFW enabled: `sudo ufw status`
- [ ] Required ports open: `sudo ufw status numbered`
