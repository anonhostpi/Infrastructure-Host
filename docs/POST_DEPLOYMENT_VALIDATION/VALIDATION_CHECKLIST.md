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
- [ ] Cockpit accessible: Open browser to `https://<host-ip>`
- [ ] Login with admin user credentials
- [ ] Verify modules loaded (Machines, Podman, Network)

## Docker

- [ ] Docker service running: `systemctl status docker`
- [ ] Docker functional: `sudo docker run hello-world`
- [ ] Admin user in docker group (may require logout/login): `groups admin | grep docker`

## Firewall

- [ ] UFW enabled: `sudo ufw status`
- [ ] Required ports open: `sudo ufw status numbered`
