# 10.1 Post-Deployment Security

## Immediate Actions

Add to cloud-init user-data for automatic security hardening:

```yaml
runcmd:
  # Update system
  - apt update && apt upgrade -y

  # Configure automatic security updates
  - apt install unattended-upgrades -y
  - dpkg-reconfigure -plow unattended-upgrades

  # Harden SSH
  - sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  - systemctl restart sshd

  # Configure fail2ban
  - apt install fail2ban -y
  - systemctl enable fail2ban
  - systemctl start fail2ban
```

## SSH Hardening

Recommended `/etc/ssh/sshd_config` settings:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 60
```

## Automatic Updates

Configure unattended-upgrades for automatic security updates:

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Fail2ban

Fail2ban protects against brute-force attacks:

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

Default configuration protects SSH. Check status:

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```
