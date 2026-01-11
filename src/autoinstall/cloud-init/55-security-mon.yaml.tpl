packages:
  - fail2ban

write_files:
  # SSH brute force protection
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

  # SSH connection flooding
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

  # Privilege escalation attempts
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

  # Repeat offender escalation
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

  # Email notifications via msmtp (optional - requires 6.7 MSMTP)
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

  # Libvirt log rotation
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

runcmd:
  - systemctl enable fail2ban
  - systemctl start fail2ban
