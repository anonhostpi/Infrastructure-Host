# 6.8 Security Monitoring Fragment

**Template:** `src/autoinstall/cloud-init/55-security-mon.yaml.tpl`

**Status:** Future implementation. This section documents planned security monitoring.

## Planned Components

### fail2ban

Intrusion prevention system that bans IPs with too many failed authentication attempts.

```yaml
packages:
  - fail2ban

write_files:
  - path: /etc/fail2ban/jail.local
    permissions: '0644'
    content: |
      [sshd]
      enabled = true
      port = 22
      filter = sshd
      logpath = /var/log/auth.log
      maxretry = 3
      bantime = 3600
      findtime = 600

runcmd:
  - systemctl enable fail2ban
  - systemctl start fail2ban
```

| Setting | Value | Description |
|---------|-------|-------------|
| `maxretry` | 3 | Ban after 3 failed attempts |
| `bantime` | 3600 | Ban duration (1 hour) |
| `findtime` | 600 | Time window for attempts (10 min) |

### Recidive Jail (Repeat Offenders)

For IPs that get banned repeatedly:

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
      findtime = 86400
      bantime = 604800
```

| Setting | Value | Description |
|---------|-------|-------------|
| `maxretry` | 3 | Ban after 3 previous bans |
| `findtime` | 86400 | Within 24 hours |
| `bantime` | 604800 | Ban for 1 week |

### auditd

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

## Integration with SSH Hardening

fail2ban works in conjunction with [6.4 SSH Hardening](./SSH_HARDENING_FRAGMENT.md):

1. SSH hardening limits `MaxAuthTries` per connection
2. fail2ban bans IPs that repeatedly fail across connections

Together, they provide defense in depth against brute force attacks.

## Implementation Notes

This fragment is not yet implemented because:

1. **Baseline first** - Establish working system before adding monitoring
2. **Log volume** - auditd generates significant log data
3. **Tuning required** - fail2ban rules need tuning for the environment

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

## Future Considerations

- **Log aggregation** - Shipping logs to central SIEM
- **Alerting** - Notifications on security events
- **AIDE** - File integrity monitoring
- **rkhunter** - Rootkit detection
