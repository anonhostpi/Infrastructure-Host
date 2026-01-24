# Test 6.9: Security Monitoring Fragment

**Template:** `src/autoinstall/cloud-init/55-security-mon.yaml.tpl`
**Fragment Docs:** [6.9 Security Monitoring Fragment](../../CLOUD_INIT_CONFIGURATION/SECURITY_MONITORING_FRAGMENT.md)

Tests fail2ban installation, jail configuration, and log rotation.

---

## Test 6.9.1: Package Installation

```bash
# On VM: Verify fail2ban installed
dpkg -l | grep fail2ban
# Expected: Shows installed

which fail2ban-client
# Expected: /usr/bin/fail2ban-client
```

---

## Test 6.9.2: Service Status

```bash
# On VM: Verify fail2ban running
systemctl is-active fail2ban
# Expected: active

systemctl is-enabled fail2ban
# Expected: enabled
```

| Check | Command | Expected |
|-------|---------|----------|
| Service active | `systemctl is-active fail2ban` | active |
| Service enabled | `systemctl is-enabled fail2ban` | enabled |

---

## Test 6.9.3: Jail Configuration - SSHD

```bash
# On VM: Verify sshd jail active
sudo fail2ban-client status sshd
# Expected: Shows jail status with filter, actions

# On VM: Verify jail config
cat /etc/fail2ban/jail.d/sshd.conf
# Expected: enabled = true, maxretry = 4, bantime = 24h
```

| Check | Command | Expected |
|-------|---------|----------|
| sshd jail active | `sudo fail2ban-client status sshd` | Shows status |
| maxretry | `grep maxretry /etc/fail2ban/jail.d/sshd.conf` | 4 |
| bantime | `grep bantime /etc/fail2ban/jail.d/sshd.conf` | 24h |

---

## Test 6.9.4: Jail Configuration - SSHD-DDoS

```bash
# On VM: Verify sshd-ddos jail
cat /etc/fail2ban/jail.d/sshd-ddos.conf
# Expected: enabled = true, maxretry = 6, findtime = 30s, bantime = 1h
```

| Check | Command | Expected |
|-------|---------|----------|
| sshd-ddos config | `test -f /etc/fail2ban/jail.d/sshd-ddos.conf` | Exists |
| maxretry | `grep maxretry /etc/fail2ban/jail.d/sshd-ddos.conf` | 6 |
| findtime | `grep findtime /etc/fail2ban/jail.d/sshd-ddos.conf` | 30s |

---

## Test 6.9.5: Jail Configuration - Sudo

```bash
# On VM: Verify sudo jail
cat /etc/fail2ban/jail.d/sudo.conf
# Expected: enabled = true, maxretry = 3, bantime = 1h
```

---

## Test 6.9.6: Jail Configuration - Recidive

```bash
# On VM: Verify recidive jail (repeat offenders)
sudo fail2ban-client status recidive
# Expected: Shows jail status

cat /etc/fail2ban/jail.d/recidive.conf
# Expected: enabled = true, maxretry = 3, findtime = 1d, bantime = 1w
```

| Check | Command | Expected |
|-------|---------|----------|
| recidive active | `sudo fail2ban-client status recidive` | Shows status |
| bantime | `grep bantime /etc/fail2ban/jail.d/recidive.conf` | 1w |

---

## Test 6.9.7: Email Action (Optional)

```bash
# On VM: Verify msmtp-mail action exists
cat /etc/fail2ban/action.d/msmtp-mail.conf
# Expected: Shows actionban with msmtp
```

---

## Test 6.9.8: Libvirt Log Rotation

```bash
# On VM: Verify libvirt logrotate config
cat /etc/logrotate.d/libvirt
# Expected: Shows /var/log/libvirt/*.log rotation
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- dpkg -l | Select-String "fail2ban"
multipass exec $VMName -- systemctl is-active fail2ban
multipass exec $VMName -- sudo fail2ban-client status
multipass exec $VMName -- sudo fail2ban-client status sshd
multipass exec $VMName -- sudo fail2ban-client status recidive
multipass exec $VMName -- cat /etc/fail2ban/jail.d/sshd.conf
multipass exec $VMName -- cat /etc/fail2ban/jail.d/sshd-ddos.conf
multipass exec $VMName -- cat /etc/fail2ban/jail.d/sudo.conf
multipass exec $VMName -- cat /etc/fail2ban/jail.d/recidive.conf
multipass exec $VMName -- cat /etc/logrotate.d/libvirt
```
