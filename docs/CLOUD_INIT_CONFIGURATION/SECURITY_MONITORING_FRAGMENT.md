# 6.9 Security Monitoring Fragment

**Template:** `src/autoinstall/cloud-init/55-security-mon.yaml.tpl`

## Components

### fail2ban

Intrusion prevention system that bans IPs with too many failed authentication attempts.

#### File Organization

fail2ban configuration uses a modular `jail.d/` structure instead of a monolithic `jail.local`:

```
/etc/fail2ban/
├── jail.d/
│   ├── sshd.conf           # SSH brute force protection
│   ├── sshd-ddos.conf      # SSH connection flooding
│   ├── sudo.conf           # Privilege escalation attempts
│   └── recidive.conf       # Repeat offender escalation
├── filter.d/
│   └── sudo.conf           # Custom sudo filter (if needed)
└── action.d/
    └── msmtp-mail.conf     # Email notifications (optional)
```

**Benefits:**
- Each jail is independently configurable
- Easy to enable/disable specific jails
- Clear audit trail of what's protected
- Follows Headscale-VPS proven pattern

#### Base Template

```yaml
packages:
  - fail2ban

runcmd:
  - systemctl enable fail2ban
  - systemctl start fail2ban
```

### SSH Jail

Primary defense against SSH brute force attacks.

```yaml
write_files:
  - path: /etc/fail2ban/jail.d/sshd.conf
    permissions: '0644'
    content: |
      [sshd]
      enabled = true
      port = ssh
      filter = sshd
      logpath = /var/log/auth.log
      maxretry = 4
      findtime = 10m
      bantime = 24h
```

| Setting | Value | Description |
|---------|-------|-------------|
| `maxretry` | 4 | Ban after 4 failed attempts |
| `findtime` | 10m | Time window for attempts |
| `bantime` | 24h | Ban duration |

### SSH DDoS Jail

Catches connection flooding (different from auth failures).

```yaml
write_files:
  - path: /etc/fail2ban/jail.d/sshd-ddos.conf
    permissions: '0644'
    content: |
      [sshd-ddos]
      enabled = true
      port = ssh
      filter = sshd-ddos
      logpath = /var/log/auth.log
      maxretry = 6
      findtime = 30s
      bantime = 1h
```

| Setting | Value | Description |
|---------|-------|-------------|
| `maxretry` | 6 | Ban after 6 rapid connections |
| `findtime` | 30s | Very short window (flood detection) |
| `bantime` | 1h | Shorter ban (may be legitimate user) |

**Note:** Uses built-in `sshd-ddos` filter that matches connection attempts regardless of auth outcome.

### Sudo Jail

Detects privilege escalation attempts (post-compromise detection).

```yaml
write_files:
  - path: /etc/fail2ban/jail.d/sudo.conf
    permissions: '0644'
    content: |
      [sudo]
      enabled = true
      port = all
      filter = sudo
      logpath = /var/log/auth.log
      maxretry = 3
      findtime = 10m
      bantime = 1h
```

| Setting | Value | Description |
|---------|-------|-------------|
| `maxretry` | 3 | Ban after 3 failed sudo attempts |
| `findtime` | 10m | Time window |
| `bantime` | 1h | Ban duration |

**Note:** This jail bans the source IP. Since sudo failures typically come from authenticated SSH sessions, this provides defense-in-depth against compromised accounts attempting privilege escalation.

### Recidive Jail (Repeat Offenders)

Escalates bans for IPs that get banned repeatedly across any jail.

```yaml
write_files:
  - path: /etc/fail2ban/jail.d/recidive.conf
    permissions: '0644'
    content: |
      [recidive]
      enabled = true
      filter = recidive
      logpath = /var/log/fail2ban.log
      maxretry = 3
      findtime = 1d
      bantime = 1w
```

| Setting | Value | Description |
|---------|-------|-------------|
| `maxretry` | 3 | Escalate after 3 bans from any jail |
| `findtime` | 1d | Within 24 hours |
| `bantime` | 1w | Ban for 1 week |

### Email Notifications (Optional)

Send email alerts on ban events. Requires msmtp from [6.7 MSMTP Fragment](./MSMTP_FRAGMENT.md).

```yaml
write_files:
  - path: /etc/fail2ban/action.d/msmtp-mail.conf
    permissions: '0644'
    content: |
      [Definition]
      actionstart =
      actionstop =
      actioncheck =
      actionban = printf "Subject: [fail2ban] %(name)s: Banned <ip>\n\nfail2ban has banned IP <ip> for jail %(name)s after <failures> failures.\n\nMatches:\n<matches>" | msmtp <dest>
      actionunban =

      [Init]
      dest = root
```

To enable email notifications, add the action to each jail:

```ini
[sshd]
enabled = true
# ... other settings ...
action = %(action_)s
         msmtp-mail[name=SSH]
```

### Jail Summary

| Jail | Trigger | Ban Time | Purpose |
|------|---------|----------|---------|
| `sshd` | 4 auth failures / 10m | 24h | Brute force protection |
| `sshd-ddos` | 6 connections / 30s | 1h | Connection flooding |
| `sudo` | 3 sudo failures / 10m | 1h | Privilege escalation |
| `recidive` | 3 bans / 24h | 1w | Repeat offender escalation |

### Verification

After deployment, verify fail2ban status:

```bash
# Check jail status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client get sshd banip

# Manually unban an IP
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

---

## auditd

Linux audit daemon for security event logging.

```yaml
packages:
  - auditd
  - audispd-plugins

write_files:
  - path: /etc/audit/rules.d/99-custom.rules
    permissions: '0640'
    content: |
      # Log all commands executed as root
      -a always,exit -F arch=b64 -F euid=0 -S execve -k root-commands
      # Log file deletions
      -a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete
      # Log permission changes
      -a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm_mod
      # Monitor SSH configuration
      -w /etc/ssh/ -p wa -k ssh_config
      # Monitor user/group changes
      -w /etc/passwd -p wa -k user_changes
      -w /etc/shadow -p wa -k user_changes
      -w /etc/group -p wa -k user_changes
      # Monitor sudo configuration
      -w /etc/sudoers -p wa -k sudo_config
      -w /etc/sudoers.d/ -p wa -k sudo_config
      # Monitor libvirt configuration
      -w /etc/libvirt/ -p wa -k libvirt_config
      # Monitor netplan configuration
      -w /etc/netplan/ -p wa -k network_config

runcmd:
  - systemctl enable auditd
  - systemctl start auditd
```

---

## Integration with Other Fragments

### SSH Hardening (6.4)

fail2ban works in conjunction with [6.4 SSH Hardening](./SSH_HARDENING_FRAGMENT.md):

1. SSH hardening limits `MaxAuthTries` per connection
2. fail2ban bans IPs that repeatedly fail across connections
3. UFW rate limiting (`ufw limit ssh`) provides additional layer

Together, they provide defense in depth against brute force attacks.

### MSMTP (6.7)

Email notifications require msmtp configured in [6.7 MSMTP Fragment](./MSMTP_FRAGMENT.md). If msmtp is not configured, omit the `msmtp-mail` action from jail definitions.

---

## Log Rotation

Configure log rotation for security-related logs:

```yaml
write_files:
  - path: /etc/logrotate.d/libvirt
    permissions: '0644'
    content: |
      /var/log/libvirt/*.log {
          daily
          missingok
          rotate 7
          compress
          delaycompress
          notifempty
          create 640 root adm
          sharedscripts
          postrotate
              systemctl reload libvirtd > /dev/null 2>&1 || true
          endscript
      }
```

### Log Retention

| Log | Rotation | Retention |
|-----|----------|-----------|
| libvirt | daily | 7 days |
| fail2ban | default | system default |
| auditd | default | system default |

**Note:** Ubuntu's default logrotate handles most logs. Custom rotation is only needed for application-specific logs.

---

## Future Considerations

- **Log aggregation** - Shipping logs to central SIEM
- **Alerting** - Notifications on security events (see email action above)
- **AIDE** - File integrity monitoring
- **rkhunter** - Rootkit detection
