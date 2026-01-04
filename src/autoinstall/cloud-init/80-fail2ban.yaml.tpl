write_files:
  - path: /etc/fail2ban/jail.d/sshd.conf
    permissions: '0644'
    content: |
      [sshd]
      enabled = true
      port = ssh
      filter = sshd
      logpath = /var/log/auth.log
      maxretry = 3
      bantime = 3600
      findtime = 600

  - path: /etc/fail2ban/jail.d/recidive.conf
    permissions: '0644'
    content: |
      [recidive]
      enabled = true
      filter = recidive
      logpath = /var/log/fail2ban.log
      bantime = 604800
      findtime = 86400
      maxretry = 3

runcmd:
  - systemctl enable fail2ban
  - systemctl start fail2ban
